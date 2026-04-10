// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1            IDLE,   latch inputs
// 2..NumIter+1 CALC,   add BitsPerCycle bits + carry per cycle
// NumIter+2    DONE,   wait for out_ready_i
// -------------------------------------------
//
// Supports non-evenly-divisible DataWidth/BitsPerCycle.
// The last iteration handles the residual bits.

module multi_cycle_add #(
    parameter int  DataWidth    = 16,
    parameter int  BitsPerCycle = 4
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

// Number of full-width iterations + one more if there is a remainder
localparam int Remainder = DataWidth % BitsPerCycle;
localparam int NumIter   = (Remainder == 0) ? (DataWidth / BitsPerCycle)
                                            : (DataWidth / BitsPerCycle) + 1;
localparam int IterWidth = $clog2(NumIter + 1);

typedef enum logic [1:0] {
    IDLE,
    CALC,
    DONE
} state_t;

// State
state_t state_d, state_q;

// Shift registers — hold the remaining (unprocessed) bits of each operand.
logic [DataWidth-1:0] a_d, a_q;
logic [DataWidth-1:0] b_d, b_q;

// Accumulated result — DataWidth bits, grows from LSB upward.
logic [DataWidth-1:0] y_d, y_q;

// Running carry between slices
logic carry_d, carry_q;

// Iteration counter
logic [IterWidth-1:0] iter_d, iter_q;

// Per-cycle slice arithmetic
logic [BitsPerCycle:0] slice_sum;

// Is this the last iteration (which may be a partial slice)?
logic last_iter;

// How many bits does the current slice actually cover?
// Full BitsPerCycle for all iterations except the last one when there's a remainder.
logic [$clog2(BitsPerCycle+1)-1:0] cur_slice_width;

always_comb begin
    // Defaults — hold state
    state_d = state_q;
    a_d     = a_q;
    b_d     = b_q;
    y_d     = y_q;
    carry_d = carry_q;
    iter_d  = iter_q;

    in_ready_o  = 1'b0;
    out_valid_o = 1'b0;
    slice_sum   = '0;

    last_iter      = (iter_q == IterWidth'(NumIter - 1));
    cur_slice_width = (last_iter && Remainder != 0)
                      ? $clog2(BitsPerCycle+1)'(Remainder)
                      : $clog2(BitsPerCycle+1)'(BitsPerCycle);

    case (state_q)
        IDLE: begin
            in_ready_o = 1'b1;
            if (in_valid_i) begin
                a_d     = a_i;
                b_d     = b_i;
                y_d     = '0;
                carry_d = 1'b0;
                iter_d  = '0;
                state_d = CALC;
            end
        end

        CALC: begin
            // Add the lowest BitsPerCycle bits of each operand plus carry-in.
            // For the last partial slice, upper bits of a_q/b_q are already 0
            // from prior right-shifts so using [BitsPerCycle-1:0] is safe.
            slice_sum = {1'b0, a_q[BitsPerCycle-1:0]}
                      + {1'b0, b_q[BitsPerCycle-1:0]}
                      + {{BitsPerCycle{1'b0}}, carry_q};

            // OR the computed slice bits into the result at the correct position.
            y_d = y_q | ({{(DataWidth - BitsPerCycle){1'b0}},
                          slice_sum[BitsPerCycle-1:0]} << (iter_q * BitsPerCycle));

            // Propagate carry
            carry_d = slice_sum[BitsPerCycle];

            // Shift operands right so next iteration sees the next slice
            a_d = a_q >> BitsPerCycle;
            b_d = b_q >> BitsPerCycle;

            iter_d = iter_q + 1'b1;

            if (last_iter) begin
                state_d = DONE;
            end
        end

        DONE: begin
            out_valid_o = 1'b1;
            if (out_ready_i) begin
                a_d     = 'x;
                b_d     = 'x;
                y_d     = 'x;
                carry_d = 'x;
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
        a_q     <= 'x;
        b_q     <= 'x;
        y_q     <= '0;
        carry_q <= 1'b0;
        iter_q  <= '0;
    end else begin
        state_q <= state_d;
        a_q     <= a_d;
        b_q     <= b_d;
        y_q     <= y_d;
        carry_q <= carry_d;
        iter_q  <= iter_d;
    end
end

endmodule
