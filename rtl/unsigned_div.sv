
// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1          IDLE,   latch inputs
// 2          PREOP,  negate divisor (if necessary), negate dividend (if necessary), setup numbers
// 3-18       CALC,   shift, add/subtract, set bit operation
// 19         POSTOP, negate quotient (if necessary), and add remainder (if necessary)
// 20         DONE,   wait for out_ready_i
// -------------------------------------------
module signed_div import config_pkg::*; #(
    parameter DataWidth = 16
) (
    input                   clk_i,
    input                   rst_i,

    output logic            in_readq_o,
    input  logic            in_valid_i,
    input  [DataWidth-1: 0] a_i,
    input  [DataWidth-1: 0] b_i,

    input  logic            out_ready_i,
    output logic            out_valid_o,
    output [DataWidth-1: 0] q_o,
    output [DataWidth-1: 0] r_o
);

typedef enum logic[3:0] {
    IDLE,
    CALC,
    DONE
} state_t;

state_t state_d, state_q;

// Inputs and outputs stored
logic signed [DataWidth-1:0] a_d, a_q;
logic signed [DataWidth-1:0] b_d, b_q;
logic signed [DataWidth:0]   comp_b_d, comp_b_q;
logic signed [DataWidth-1:0] q_d, q_q;

// Non-restoring division registers
logic [DataWidth-1:0] q_d, q_q;   // quotient
logic [DataWidth:0]   r_d, r_q; // Partial remainder
logic [5:0]           iter_d, iter_q;

always_comb begin
    state_d = state_q;
    a_d = a_q;
    b_d = b_q;
    comp_b_d = comp_b_q;
    q_d = q_q;

    q_d = q_q;
    r_d = r_q;
    iter_d = iter_q;

    in_readq_o = 0;
    out_valid_o = 0;

    case (state_q)
        IDLE: begin
            in_readq_o = 1;
            if (in_valid_i) begin
                // Handling divide by zero immediately to save time
                if (a_i == '0) begin
                    q_d = 0;
                    state_d = DONE;
                end
                if (b_i == '0)begin
                    q_d = 0;
                    state_d = DONE;
                end
                a_d = a_i;
                b_d = b_i;

                iter_d = 0;
                // Initialize division parts
                comp_b_d = -b_i;                     // Negate the absolute b_d
                q_d = a_i;                    // Initialize quotient
                r_d = '0;                    // Initialize remainder to 0
                iter_d = '0;                         // Start Iteration at 0
                q_d = 0;                             // Clear accumulator

                state_d = CALC;
            end
        end
        CALC: begin
            if (iter_q != 16) begin
                // Shift Operation
                {r_d, q_d} = {r_q, q_q} << 1;

                // Addition/Subtraction
                if (r_d[DataWidth]) r_d = r_d + {1'b0, b_q};
                else                r_d = r_d + comp_b_q;

                // Set Bit
                if (r_d[DataWidth]) q_d[0] = 0;
                else                q_d[0] = 1;
                
                // Increment
                iter_d = iter_q + 1;
            end else begin
                state_d = DONE;
            end
        end
        DONE: begin
            out_valid_o = 1;
            if (out_ready_i) begin
                // Clear stored values
                a_d = 'x;
                b_d = 'x;
                q_d = 'x;
                q_d = 'x;
                r_d = 'x;
                iter_d = 0;
                state_d = IDLE;
            end
        end

        default: state_d = IDLE;
    endcase
end

assign r_o = r_q;
assign q_o = q_q;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state_q <= IDLE;
        a_q <= 'x;
        b_q <= 'x;
        comp_b_q <= 'x;

        q_q <= 'x;
        r_q <= 'x;
        iter_q <= 0;
    end else begin
        state_q <= state_d;
        a_q <= a_d;
        b_q <= b_d;
        comp_b_q <= comp_b_d;

        q_q <= q_d;
        r_q <= r_d;
        iter_q <= iter_d;
    end
end

endmodule
