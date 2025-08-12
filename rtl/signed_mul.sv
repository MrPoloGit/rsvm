
// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1          IDLE,   latch inputs
// 2          PREOP,  negate divisor (if necessary), negate dividend (if necessary), setup numbers
// 3-18       CALC,   shift, add/subtract, set bit operation
// 19         POSTOP, negate quotient (if necessary), and add remainder (if necessary)
// 20         DONE,   wait for out_ready_i
// -------------------------------------------
module signed_mul import config_pkg::*; #(
    parameter DataWidth = 16
) (
    input                   clk_i,
    input                   rst_i,

    output logic            in_ready_o,
    input  logic            in_valid_i,
    input  [DataWidth-1: 0] a_i,
    input  [DataWidth-1: 0] b_i,

    input  logic            out_ready_i,
    output logic            out_valid_o,
    output [DataWidth-1: 0] y_o
);

typedef enum logic[3:0] {
    IDLE,
    NEG,
    CALC,
    POSTOP,
    DONE
} state_t;

state_t state_d, state_q;

// Inputs and outputs stored
logic signed [DataWidth-1:0] a_d, a_q;
logic signed [DataWidth-1:0] b_d, b_q;
logic signed [DataWidth:0]   comp_b_d, comp_b_q;
logic signed [DataWidth-1:0] y_d, y_q;

// Sign tracking for restoring correct signs later
logic a_is_negative_d, a_is_negative_q;
logic b_is_negative_d, b_is_negative_q;

// Non-restoring division registers
logic [DataWidth-1:0] quotient_d, quotient_q;   // quotient
logic [DataWidth:0]   remainder_d, remainder_q; // Partial remainder
logic [5:0]           iter_d, iter_q;

always_comb begin
    state_d = state_q;
    a_d = a_q;
    b_d = b_q;
    comp_b_d = comp_b_q;
    y_d = y_q;

    a_is_negative_d = a_is_negative_q;
    b_is_negative_d = b_is_negative_q;

    quotient_d = quotient_q;
    remainder_d = remainder_q;
    iter_d = iter_q;

    in_ready_o = 0;
    out_valid_o = 0;

    case (state_q)
        IDLE: begin
            in_ready_o = 1;
            if (in_valid_i) begin
                // Handling divide by zero immediately to save time
                if (a_i == '0 || b_i == '0)begin
                    state_d = DONE;
                end
                a_d = a_i;
                b_d = b_i;
                iter_d = 0;
                state_d = NEG;
            end
        end
        NEG: begin
            // Convert to unsigned
            if (a_q[DataWidth-1]) begin
                a_d = -a_q;
                a_is_negative_d = 1;
            end
            if (b_q[DataWidth-1]) begin
                b_d = -b_q;
                b_is_negative_d = 1;
            end

            // Initialize division parts
            comp_b_d = -b_d;                     // Negate the absolute b_d
            quotient_d = a_d;                    // Initialize quotient
            remainder_d = '0;                    // Initialize remainder to 0
            iter_d = '0;                         // Start Iteration at 0
            y_d = 0;                             // Clear accumulator

            state_d = CALC;
        end

        CALC: begin
            if (iter_q != 16) begin
                // Shift Operation
                {remainder_d, quotient_d} = {remainder_q, quotient_q} << 1;

                // Addition/Subtraction
                if (remainder_d[DataWidth]) remainder_d = remainder_d + {1'b0, b_q};
                else                        remainder_d = remainder_d + comp_b_q;

                // Set Bit
                if (remainder_d[DataWidth]) quotient_d[0] = 0;
                else                        quotient_d[0] = 1;
                
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
            if (a_is_negative_q ^ b_is_negative_q) y_d = -y_d;

            state_d = DONE;
        end
        DONE: begin
            out_valid_o = 1;
            if (out_ready_i) begin
                // Clear stored values
                a_d = 'x;
                b_d = 'x;
                y_d = 'x;
                quotient_d = 'x;
                remainder_d = 'x;
                iter_d = 0;
                a_is_negative_d = 0;
                b_is_negative_d = 0;
                state_d = IDLE;
            end
        end

        default: state_d = IDLE;
    endcase
end

assign y_o = y_q;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        state_q <= IDLE;
        a_q <= 'x;
        b_q <= 'x;
        comp_b_q <= 'x;
        y_q <= 'x;

        a_is_negative_q <= 0;
        b_is_negative_q <= 0;

        quotient_q <= 'x;
        remainder_q <= 'x;
        iter_q <= 0;
    end else begin
        state_q <= state_d;
        a_q <= a_d;
        b_q <= b_d;
        comp_b_q <= comp_b_d;
        y_q <= y_d;

        a_is_negative_q <= a_is_negative_d;
        b_is_negative_q <= b_is_negative_d;

        quotient_q <= quotient_d;
        remainder_q <= remainder_d;
        iter_q <= iter_d;
    end
end

endmodule
