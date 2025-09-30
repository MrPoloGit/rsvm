// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1               IDLE,   latch inputs
// 2               PREOP,  negate divisor (if necessary), negate dividend (if necessary), setup numbers
// 3-(DataWidth+2) CALC,   shift, add/subtract, set bit operation, negate quotient (if necessary), and add remainder (if necessary)
// (DataWidth+4)   DONE,   wait for out_ready_i
// -------------------------------------------

// Add remainder output
module signed_div #(
    parameter int DataWidth = 4, 
    parameter int Log2DataWidth = $clog2(DataWidth),
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

typedef enum logic[2:0] {
    IDLE,
    NEG,
    CALC,
    POSTOP,
    DONE
} state_t;

state_t                      state_d, state_q;

// Inputs and outputs stored
logic signed [DataWidth:0]   a_d, a_q;
logic signed [DataWidth:0]   b_d, b_q;
logic signed [DataWidth:0]   comp_b_d, comp_b_q;
logic signed [DataWidth-1:0] y_d, y_q;

// Sign tracking for restoring correct signs later
logic                        a_sign_d, a_sign_q;
logic                        b_sign_d, b_sign_q;

// Non-restoring division registers
logic [DataWidth-1:0]       quotient_d, quotient_q;
logic [DataWidth:0]         remainder_d, remainder_q;
logic [Log2DataWidth:0]     iter_d, iter_q;

always_comb begin
    state_d     = state_q;
    a_d         = a_q;
    b_d         = b_q;
    comp_b_d    = comp_b_q;
    y_d         = y_q;

    a_sign_d    = a_sign_q;
    b_sign_d    = b_sign_q;

    quotient_d  = quotient_q;
    remainder_d = remainder_q;
    iter_d      = iter_q;

    in_ready_o  = 0;
    out_valid_o = 0;

    case (state_q)
        IDLE: begin
            in_ready_o = 1;
            if (in_valid_i) begin
                // Handling zero cases immediately to save time
                if (a_i == 0)begin
                    y_d = 0;
                    remainder_d = 0;
                    state_d = DONE;
                end else if (b_i == 0) begin
                    if (a_i > 0) y_d = MaxValue;
                    if (a_i < 0) y_d = MinValue;
                    remainder_d = 0;
                    state_d = DONE;
                end else begin
                    a_d = {a_i[DataWidth-1], a_i};
                    b_d = {b_i[DataWidth-1], b_i};
                    iter_d = 0;
                    state_d = NEG;
                end
            end
        end
        NEG: begin
            // Convert to unsigned
            // don't need if statement exactly, could do a ternary statement and a_sign_d = a_q[DataWidth-1]
            if (a_q[DataWidth-1]) a_d = -a_q;
            a_sign_d = a_q[DataWidth-1];
            
            if (b_q[DataWidth-1]) b_d = -b_q;
            b_sign_d = b_q[DataWidth-1];

            // Initialize division portions
            comp_b_d    = -b_d;
            /* verilator lint_off WIDTHTRUNC */
            quotient_d  = a_d;
            /* verilator lint_on WIDTHTRUNC */
            remainder_d = '0;
            iter_d      = '0;
            y_d         = 0;

            state_d = CALC;
        end
        CALC: begin
            /* verilator lint_off WIDTHEXPAND */
            if (iter_q < DataWidth) begin
            /* verilator lint_on WIDTHEXPAND */
                // Shift Operation
                {remainder_d, quotient_d} = {remainder_q, quotient_q} << 1;

                // Addition/Subtraction
                /* verilator lint_off WIDTHTRUNC */
                if (remainder_d[DataWidth]) remainder_d = remainder_d + {1'b0, b_q};
                else                        remainder_d = remainder_d + comp_b_q;
                /* verilator lint_on WIDTHTRUNC */

                // Set Bit
                quotient_d[0] = ~remainder_d[DataWidth];
                
                // Increment
                iter_d = iter_q + 1;
            end else begin
                state_d = POSTOP;
            end
        end
        POSTOP: begin
            // Final correction for non-restoring division
            if (remainder_q[DataWidth]) remainder_d = remainder_q + b_q;

            // Restore correct sign to which is saved initially
            y_d = quotient_q;
            if (a_sign_q ^ b_sign_q) y_d = -y_d;
            if (a_sign_q) remainder_d = -remainder_d;
            state_d = DONE;
        end
        DONE: begin
            out_valid_o = 1;
            if (out_ready_i) begin
                // Clear stored values
                state_d     = IDLE;
                a_d         = 'x;
                b_d         = 'x;
                y_d         = 'x;

                a_sign_d    = 0;
                b_sign_d    = 0;

                quotient_d  = 'x;
                remainder_d = 'x;
                iter_d      = 0;
            end
        end
        default: state_d = IDLE;
    endcase
end

assign y_o = y_q;
assign r_o = remainder_q;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state_q     <= IDLE;
        a_q         <= 'x;
        b_q         <= 'x;
        comp_b_q    <= 'x;
        y_q         <= 'x;

        a_sign_q    <= 0;
        b_sign_q    <= 0;

        quotient_q  <= 'x;
        remainder_q <= 'x;
        iter_q      <= 0;
    end else begin
        state_q     <= state_d;
        a_q         <= a_d;
        b_q         <= b_d;
        comp_b_q    <= comp_b_d;
        y_q         <= y_d;

        a_sign_q    <= a_sign_d;
        b_sign_q    <= b_sign_d;

        quotient_q  <= quotient_d;
        remainder_q <= remainder_d;
        iter_q      <= iter_d;
    end
end

endmodule
