// -------------------------------------------
// Non-restoring signed division using multi_cycle_add
// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1                        IDLE,    latch inputs
// 2                        NEG,     negate to magnitude, setup
// 3..(DataWidth+2)         CALC,    one quotient bit per outer iteration
//                                   (each uses one multi-cycle add)
// (DataWidth+3)            POSTOP,  remainder correction (optional add)
// (DataWidth+4+add_lat*N)  DONE,    wait for out_ready_i
// -------------------------------------------

module signed_div_multi_cycle_add #(
    parameter int DataWidth       = 32,
    parameter int AddBitsPerCycle = 4,

    parameter logic signed [DataWidth-1:0] MaxValue = ((1 << (DataWidth-1)) - 1),
    parameter logic signed [DataWidth-1:0] MinValue = (-(1 << (DataWidth-1)))
) (
    input  logic                        clk_i,
    input  logic                        rst_i,

    output logic                        in_ready_o,
    input  logic                        in_valid_i,
    input  logic signed [DataWidth-1:0] a_i,
    input  logic signed [DataWidth-1:0] b_i,

    output logic                        out_valid_o,
    input  logic                        out_ready_i,
    output logic signed [DataWidth-1:0] y_o,
    output logic signed [DataWidth-1:0] r_o
);

localparam int Log2DataWidth = $clog2(DataWidth);

// Counter width: needs to hold values 0..DataWidth, so Log2DataWidth+1 bits
localparam int IterWidth = Log2DataWidth + 1;

// -----------------------------------------------------------------------
// multi_cycle_add instantiation
// -----------------------------------------------------------------------
localparam int AddWidth = DataWidth + 1;

logic                        add_in_valid,  add_in_ready;
logic                        add_out_valid, add_out_ready;
logic signed [AddWidth-1:0]  add_a, add_b;
logic signed [AddWidth-1:0]  add_y;

multi_cycle_add #(
    .DataWidth    (AddWidth),
    .BitsPerCycle (AddBitsPerCycle)
) u_adder (
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .in_ready_o  (add_in_ready),
    .in_valid_i  (add_in_valid),
    .a_i         (add_a),
    .b_i         (add_b),
    .out_valid_o (add_out_valid),
    .out_ready_i (add_out_ready),
    .y_o         (add_y)
);

// -----------------------------------------------------------------------
// FSM types
// -----------------------------------------------------------------------
typedef enum logic [2:0] {
    IDLE,
    NEG,
    CALC,
    POSTOP,
    DONE
} state_t;

typedef enum logic [1:0] {
    ADD_IDLE,
    ADD_SEND,
    ADD_WAIT
} add_state_t;

state_t     state_d,     state_q;
add_state_t add_state_d, add_state_q;

// Dividend / divisor (sign-extended to DataWidth+1)
logic signed [DataWidth:0] a_d, a_q;
logic signed [DataWidth:0] b_d, b_q;
logic signed [DataWidth:0] comp_b_d, comp_b_q;   // -|b|, precomputed

// Quotient / remainder
logic [DataWidth-1:0]  quotient_d,  quotient_q;
logic [DataWidth:0]    remainder_d, remainder_q;

// Sign bits
logic a_sign_d, a_sign_q;
logic b_sign_d, b_sign_q;

// Iteration counter
logic [IterWidth-1:0] iter_d, iter_q;

// Saved quotient for output
logic signed [DataWidth-1:0] y_d, y_q;

// Adder operand staging registers
logic signed [AddWidth-1:0] add_a_d, add_a_q;
logic signed [AddWidth-1:0] add_b_d, add_b_q;

// Combinational shift result
logic [DataWidth:0]    shifted_rem;
logic [DataWidth-1:0]  shifted_quot;

always_comb begin
    state_d     = state_q;
    add_state_d = add_state_q;

    a_d         = a_q;
    b_d         = b_q;
    comp_b_d    = comp_b_q;
    y_d         = y_q;

    a_sign_d    = a_sign_q;
    b_sign_d    = b_sign_q;

    quotient_d  = quotient_q;
    remainder_d = remainder_q;
    iter_d      = iter_q;

    add_a_d     = add_a_q;
    add_b_d     = add_b_q;

    // Adder control defaults
    add_in_valid  = 1'b0;
    add_out_ready = 1'b0;
    add_a         = add_a_q;
    add_b         = add_b_q;

    in_ready_o  = 1'b0;
    out_valid_o = 1'b0;

    shifted_rem  = '0;
    shifted_quot = '0;

    case (state_q)
        IDLE: begin
            in_ready_o = 1'b1;
            if (in_valid_i) begin
                if (a_i == '0) begin
                    y_d         = '0;
                    remainder_d = '0;
                    state_d     = DONE;
                end else if (b_i == '0) begin
                    y_d         = (a_i > 0) ? MaxValue : MinValue;
                    remainder_d = '0;
                    state_d     = DONE;
                end else begin
                    a_d     = {a_i[DataWidth-1], a_i};
                    b_d     = {b_i[DataWidth-1], b_i};
                    iter_d  = '0;
                    state_d = NEG;
                end
            end
        end

        NEG: begin
            // Convert to unsigned magnitudes
            if (a_q[DataWidth]) a_d = -a_q;
            a_sign_d = a_q[DataWidth];

            if (b_q[DataWidth]) b_d = -b_q;
            b_sign_d = b_q[DataWidth];

            // Pre-compute -|b| for subtraction steps in CALC.
            // If b was negative: b_q is negative, so -|b| = b_q itself.
            // If b was positive: b_q is positive, so -|b| = -b_q.
            comp_b_d = b_q[DataWidth] ? b_q : -b_q;

            // Initialize quotient with magnitude of a
            if (a_q[DataWidth])
                quotient_d = (-a_q);
            else
                quotient_d = a_q[DataWidth-1:0];

            remainder_d = '0;
            iter_d      = '0;
            y_d         = '0;
            add_state_d = ADD_IDLE;
            state_d     = CALC;
        end

        // ----------------------------------------------------------------
        // CALC: non-restoring division, one bit per outer iteration.
        //
        // Each iteration:
        //   1. Shift {remainder, quotient} left by 1
        //   2. remainder += (remainder >= 0) ? (-|b|) : (+|b|)
        //   3. quotient[0] = ~new_remainder_sign
        //   4. iter++
        // ----------------------------------------------------------------
        CALC: begin
            if (iter_q < IterWidth'(DataWidth)) begin

                case (add_state_q)
                    ADD_IDLE: begin
                        // Step 1: shift left
                        {shifted_rem, shifted_quot} = {remainder_q, quotient_q} << 1;
                        remainder_d = shifted_rem;
                        quotient_d  = shifted_quot;

                        // Step 2: prepare adder operands
                        // remainder >= 0 -> subtract b (add comp_b = -|b|)
                        // remainder < 0  -> add b      (add |b|)
                        add_a_d = {shifted_rem[DataWidth], shifted_rem}; // sign-extend
                        add_b_d = shifted_rem[DataWidth]
                                    ? {{1{b_q[DataWidth]}},   b_q}       // + |b|  (b_q holds |b| after NEG)
                                    : {{1{comp_b_q[DataWidth]}}, comp_b_q}; // + (-|b|)

                        add_state_d = ADD_SEND;
                    end

                    ADD_SEND: begin
                        add_in_valid = 1'b1;
                        add_a        = add_a_q;
                        add_b        = add_b_q;
                        if (add_in_ready) begin
                            add_state_d = ADD_WAIT;
                        end
                    end

                    ADD_WAIT: begin
                        add_out_ready = 1'b1;
                        if (add_out_valid) begin
                            remainder_d   = add_y[DataWidth:0];
                            quotient_d[0] = ~add_y[DataWidth]; // Q bit = 1 if rem >= 0
                            iter_d        = iter_q + 1'b1;
                            add_state_d   = ADD_IDLE;
                        end
                    end

                    default: add_state_d = ADD_IDLE;
                endcase

            end else begin
                state_d     = POSTOP;
                add_state_d = ADD_IDLE;
            end
        end

        // ----------------------------------------------------------------
        // POSTOP: non-restoring correction.
        // If remainder is negative:
        //   remainder += |b|
        //   quotient  -= 1
        // Then apply sign to quotient and remainder.
        // ----------------------------------------------------------------
        POSTOP: begin
            case (add_state_q)
                ADD_IDLE: begin
                    if (remainder_q[DataWidth]) begin
                        // Remainder is negative -> needs correction
                        // remainder += |b|  (b_q holds |b| after NEG stage)
                        add_a_d     = {{1{remainder_q[DataWidth]}}, remainder_q};
                        add_b_d     = {{1{b_q[DataWidth]}}, b_q};
                        add_state_d = ADD_SEND;
                    end else begin
                        // No correction needed — apply signs directly
                        y_d = quotient_q;
                        if (a_sign_q ^ b_sign_q) y_d = -$signed(quotient_q);
                        if (a_sign_q) remainder_d = -remainder_q;
                        add_state_d = ADD_IDLE;
                        state_d     = DONE;
                    end
                end

                ADD_SEND: begin
                    add_in_valid = 1'b1;
                    add_a        = add_a_q;
                    add_b        = add_b_q;
                    if (add_in_ready) begin
                        add_state_d = ADD_WAIT;
                    end
                end

                ADD_WAIT: begin
                    add_out_ready = 1'b1;
                    if (add_out_valid) begin
                        remainder_d = add_y[DataWidth:0];

                        // quotient must be decremented when remainder
                        // was negative (non-restoring correction: Q = Q - 1)
                        y_d = quotient_q - 1'b1;

                        // Apply signs
                        if (a_sign_q ^ b_sign_q) y_d = -$signed(quotient_q - 1'b1);
                        if (a_sign_q) remainder_d = -add_y[DataWidth:0];

                        add_state_d = ADD_IDLE;
                        state_d     = DONE;
                    end
                end

                default: add_state_d = ADD_IDLE;
            endcase
        end

        DONE: begin
            out_valid_o = 1'b1;
            if (out_ready_i) begin
                state_d     = IDLE;
                a_d         = 'x;
                b_d         = 'x;
                y_d         = 'x;
                a_sign_d    = 1'b0;
                b_sign_d    = 1'b0;
                quotient_d  = 'x;
                remainder_d = 'x;
                iter_d      = '0;
            end
        end

        default: state_d = IDLE;
    endcase
end

assign y_o = y_q;
assign r_o = remainder_q[DataWidth-1:0];

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state_q     <= IDLE;
        add_state_q <= ADD_IDLE;
        a_q         <= 'x;
        b_q         <= 'x;
        comp_b_q    <= 'x;
        y_q         <= 'x;
        a_sign_q    <= 1'b0;
        b_sign_q    <= 1'b0;
        quotient_q  <= 'x;
        remainder_q <= 'x;
        iter_q      <= '0;
        add_a_q     <= 'x;
        add_b_q     <= 'x;
    end else begin
        state_q     <= state_d;
        add_state_q <= add_state_d;
        a_q         <= a_d;
        b_q         <= b_d;
        comp_b_q    <= comp_b_d;
        y_q         <= y_d;
        a_sign_q    <= a_sign_d;
        b_sign_q    <= b_sign_d;
        quotient_q  <= quotient_d;
        remainder_q <= remainder_d;
        iter_q      <= iter_d;
        add_a_q     <= add_a_d;
        add_b_q     <= add_b_d;
    end
end

endmodule
