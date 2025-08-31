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
    output logic signed [DataWidth-1:0] y_o
);

parameter int PipeDepth = DataWidth + 4;

// Inputs and outputs stored
logic signed [DataWidth:0]   a_d      [PipeDepth], a_q      [PipeDepth];
logic signed [DataWidth:0]   b_d      [PipeDepth], b_q      [PipeDepth];
logic signed [DataWidth:0]   comp_b_d [PipeDepth], comp_b_q [PipeDepth];
logic signed [DataWidth-1:0] y_d      [PipeDepth], y_q      [PipeDepth];

// Sign tracking for restoring correct signs later
logic a_sign_d [PipeDepth], a_sign_q [PipeDepth];
logic b_sign_d [PipeDepth], b_sign_q [PipeDepth];

// Non-restoring division registers
logic [DataWidth-1:0]     quotient_d [PipeDepth], quotient_q [PipeDepth];
logic [DataWidth:0]       remainder_d [PipeDepth], remainder_q [PipeDepth];
logic                     valid_d [PipeDepth], valid_q [PipeDepth];

generate
    genvar i;
    for (i = 0; i < PipeDepth; i++) begin
        always_comb begin
            a_d[i]         = a_q[i];
            b_d[i]         = b_q[i];
            comp_b_d[i]    = comp_b_q[i];
            y_d[i]         = y_q[i];

            a_sign_d[i]    = a_sign_q[i];
            b_sign_d[i]    = b_sign_q[i];

            quotient_d[i]  = quotient_q[i];
            remainder_d[i] = remainder_q[i];
            valid_d[i]     = valid_q[i];

            if (out_ready_i) begin
                if (i == 0) begin
                    if (a_i == 0)begin
                        y_d = '0;
                    end else if (b_i == 0) begin
                        if (a_i > 0) y_d = MaxValue;
                        if (a_i < 0) y_d = MinValue;
                    end else begin
                        a_d = {a_i[DataWidth-1], a_i};
                        b_d = {b_i[DataWidth-1], b_i};
                    end
                end else if (i == 1) begin
                    // Convert to unsigned
                    // don't need if statement exactly, could do a ternary statement and a_sign_d = a_q[DataWidth-1]
                    if (a_q[i-1][DataWidth-1]) begin
                        a_d[i] = -a_q[i-1];
                        a_sign_d[i] = 1;
                    end
                    
                    if (b_q[i-1][DataWidth-1]) begin
                        b_d[i] = -b_q[i-1];
                        b_sign_d[i] = 1;
                    end

                    // Initialize division portions
                    comp_b_d    = -b_d;
                    /* verilator lint_off WIDTHTRUNC */
                    quotient_d  = a_d;
                    /* verilator lint_on WIDTHTRUNC */
                    remainder_d = '0;
                    y_d         = 0;
                end else if (i == (PipeDepth-1)) begin
                    // Final correction for non-restoring division
                    if (remainder_q[DataWidth]) remainder_d = remainder_q + b_q;

                    // Restore correct sign to which is saved initially
                    y_d = quotient_q;
                    if (a_sign_q ^ b_sign_q) y_d = -y_d;
                end else begin
                    // Shift Operation
                    {remainder_d, quotient_d} = {remainder_q, quotient_q} << 1;

                    // Addition/Subtraction
                    /* verilator lint_off WIDTHTRUNC */
                    if (remainder_d[DataWidth]) remainder_d = remainder_d + {1'b0, b_q};
                    else                        remainder_d = remainder_d + comp_b_q;
                    /* verilator lint_on WIDTHTRUNC */

                    // Set Bit
                    quotient_d[0] = ~remainder_d[DataWidth];
                end
            end

        always_ff @(posedge clk_i) begin
            if (rst_i) begin
                a_q[i]         <= 'x;
                b_q[i]         <= 'x;
                comp_b_q[i]    <= 'x;
                y_q[i]         <= 'x;

                a_sign_q[i]    <= 0;
                b_sign_q[i]    <= 0;

                quotient_q[i]  <= 'x;
                remainder_q[i] <= 'x;
            end else begin
                a_q[i]         <= a_d[i];
                b_q[i]         <= b_d[i];
                comp_b_q[i]    <= comp_b_d[i];
                y_q[i]         <= y_d[i];

                a_sign_q[i]    <= a_sign_d[i];
                b_sign_q[i]    <= b_sign_d[i];

                quotient_q[i]  <= quotient_d[i];
                remainder_q[i] <= remainder_d[i];
            end
        end

    end
endgenerate

assign in_ready_o  = out_ready_i;
assign out_valid_o = valid_q[PipeDepth-1];
assign y_o         = y_q[PipeDepth-1];

endmodule
