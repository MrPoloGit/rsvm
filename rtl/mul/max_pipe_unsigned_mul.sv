module max_pipe_unsigned_mul #(
    parameter DataWidth = 16
) (
    input  logic                 clk_i,
    input  logic                 rst_i,

    output logic                 in_ready_o,
    input  logic                 in_valid_i,
    input  logic [DataWidth-1:0] a_i,
    input  logic [DataWidth-1:0] b_i,

    output logic                 out_valid_o,
    input  logic                 out_ready_i,
    output logic [DataWidth-1:0] y_o
);

logic [DataWidth-1:0]   a_d [DataWidth]; 
logic [DataWidth-1:0]   a_q [DataWidth];
logic [DataWidth-1:0]   b_d [DataWidth];
logic [DataWidth-1:0]   b_q [DataWidth];
logic [2*DataWidth-1:0] y_d [DataWidth];
logic [2*DataWidth-1:0] y_q [DataWidth];

logic                   valid_d [DataWidth];
logic                   valid_q [DataWidth];

generate
    genvar i;
    for (i = 0; i < DataWidth; i++) begin
        always_comb begin
            if (out_ready_i) begin
                if (i == 0) begin
                    a_d[i]     = a_i;
                    b_d[i]     = b_i;
                    y_d[i]     = '0;
                    valid_d[i] = in_valid_i;
                end else begin
                    if (b_q[i][0]) y_d[i] = y_q[i-1] + a_q[i-1];
                    else           y_d[i] = y_q[i-1];
                    a_d[i]     = a_q[i-1] << 1;
                    b_d[i]     = b_q[i-1] >> 1;
                    valid_d[i] = valid_q[i-1];
                end 
            end else begin
                a_d[i]     = a_q[i];
                b_d[i]     = b_q[i];
                y_d[i]     = y_q[i];
                valid_d[i] = valid_q[i];
            end
        end

        always_ff @(posedge clk_i) begin
            if (rst_i) begin
                a_q[i]     <= '0;
                b_q[i]     <= '0;
                y_q[i]     <= '0;
                valid_q[i] <= 1'b0;
            end else begin
                a_q[i]     <= a_d[i];
                b_q[i]     <= b_d[i];
                y_q[i]     <= y_d[i];
                valid_q[i] <= valid_d[i];
            end
        end
    end
endgenerate

assign in_ready_o = out_ready_i;
assign out_valid_o = valid_q[DataWidth-1];
assign y_o = y_q[DataWidth-1][DataWidth-1:0];

endmodule
