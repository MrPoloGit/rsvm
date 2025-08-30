// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1          IDLE,   latch inputs
// 2          NEG,    negate divisor (if necessary), negate dividend (if necessary)
// 3-8        CALC,   shift add operation
// 19         POSTOP, negate quotient (if necessary)
// 20         DONE,   wait for out_ready_i
// -------------------------------------------

module signed_mul #(
    parameter DataWidth = 16,
    parameter int Log2DataWidth = $clog2(DataWidth)
) (
    input  logic                        clk_i,
    input  logic                        rst_i,

    output logic                        in_ready_o,
    input  logic                        in_valid_i,
    input  logic signed [DataWidth-1:0] a_i,
    input  logic signed [DataWidth-1:0] b_i,

    output logic                        out_valid_o,
    input  logic                        out_ready_i,
    output logic signed [DataWidth-1:0] y_o
);

typedef enum logic[3:0] {
    IDLE,
    NEG,
    CALC,
    POSTOP,
    DONE
} state_t;

// State storing
state_t state_d, state_q;

// Inputs and outputs stored
logic signed [2*DataWidth-1:0] a_d, a_q;
logic signed [2*DataWidth-1:0] b_d, b_q;
logic signed [2*DataWidth-1:0] y_d, y_q;

// Sign tracking for restoring correct signs later
logic a_sign_d, a_sign_q;
logic b_sign_d, b_sign_q;

// Shift and add variables
logic [4:0] iter_d, iter_q;

always_comb begin
    state_d     = state_q;
    a_d         = a_q;
    b_d         = b_q;
    y_d         = y_q;
    a_sign_d    = a_sign_q;
    b_sign_d    = b_sign_q;
    iter_d      = iter_q;
    
    in_ready_o  = 0;
    out_valid_o = 0;

    case (state_q)
        IDLE: begin
            in_ready_o = 1;
            if (in_valid_i) begin
                if (a_i == 0 || b_i == 0)begin
                    y_d = '0;
                    state_d = DONE;
                end
                a_d = a_i;
                b_d = b_i;
                iter_d = 0;
                state_d = NEG;
            end
        end
        NEG: begin
            a_sign_d = 0;
            b_sign_d = 0;
            // Does this work?
            a_sign_d = a_q[DataWidth-1];
            if (a_q[DataWidth-1]) a_d = -a_q;

            b_sign_d = b_q[DataWidth-1];
            if (b_q[DataWidth-1]) b_d = -b_q;
            y_d = 0;  // Clear accumulator
            state_d = CALC;
        end
        CALC: begin
            if (iter_q < DataWidth) begin
                if (b_q[0]) begin
                    y_d = y_q + a_q;
                end
                a_d = a_q << 1;
                b_d = b_q >> 1;
                iter_d = iter_q + 1;
            end else begin
                state_d = POSTOP;
            end
        end
        POSTOP: begin
            if (a_sign_q ^ b_sign_q) y_d = -y_q;
            state_d = DONE;
        end
        DONE: begin
            out_valid_o = 1;
            if (out_ready_i) begin
                a_d      = 'x;
                b_d      = 'x;
                y_d      = 'x;
                a_sign_d = 'x;
                b_sign_d = 'x;
                state_d  = IDLE;
            end
        end
        default: state_d = IDLE;
    endcase
end

assign y_o = y_q;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state_q         <= IDLE;
        a_q             <= 'x;
        b_q             <= 'x;
        y_q             <= 'x;
        a_sign_q        <= 0;
        b_sign_q        <= 0;
        iter_q          <= '0;
    end else begin
        state_q         <= state_d;
        a_q             <= a_d;
        b_q             <= b_d;
        y_q             <= y_d;
        a_sign_q        <= a_sign_d;
        b_sign_q        <= b_sign_d;
        iter_q          <= iter_d;
    end
end

endmodule
