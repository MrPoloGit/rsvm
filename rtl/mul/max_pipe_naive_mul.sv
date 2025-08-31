module max_pipe_naive_mul #(
    parameter DataWidth = 16
) (
    input  logic                   clk_i,
    input  logic                   rst_i,

    output logic                   in_ready_o,
    input  logic                   in_valid_i,
    input  logic [DataWidth-1:0]   a_i,
    input  logic [DataWidth-1:0]   b_i,

    output logic                   out_valid_o,
    input  logic                   out_ready_i,
    output logic [2*DataWidth-1:0] y_o
);

logic [DataWidth-1:0] m_d [DataWidth]; 
logic [DataWidth-1:0] m_q [DataWidth];
logic [2*DataWidth:0] p_d [DataWidth];
logic [2*DataWidth:0] p_q [DataWidth];

logic                 valid_d [DataWidth];
logic                 valid_q [DataWidth];

generate
    genvar i;
    for (i = 0; i < DataWidth; i++) begin
        always_comb begin
            m_d[i]     = m_q[i];
            p_d[i]     = p_q[i];
            valid_d[i] = valid_q[i];

            // Only continue the operations if downstream signal that its ready
            if (out_ready_i) begin
                if (i == 0) begin
                    m_d[i]     = a_i;
                    p_d[i]   = {{(DataWidth+1){1'b0}}, b_i};
                    if (b_i[0]) begin
                        p_d[i][2*DataWidth:DataWidth] = p_d[i][2*DataWidth:DataWidth] + {1'b0, a_i};
                    end
                    p_d[i]     = {1'b0, p_d[i][2*DataWidth:1]};
                    valid_d[i] = in_valid_i;
                end else begin
                    m_d[i]     = m_q[i-1];
                    valid_d[i] = valid_q[i-1];
                    p_d[i] = p_q[i-1];
                    if (p_q[i-1][0]) begin
                        p_d[i][2*DataWidth:DataWidth] = p_q[i-1][2*DataWidth:DataWidth] + {1'b0, m_q[i-1]};
                    end
                    p_d[i] = {1'b0, p_d[i][2*DataWidth:1]};
                end
            end
        end

        always_ff @(posedge clk_i) begin
            if (rst_i) begin
                m_q[i]     <= '0;
                p_q[i]     <= '0;
                valid_q[i] <= 1'b0;
            end else begin
                m_q[i]     <= m_d[i];
                p_q[i]     <= p_d[i];
                valid_q[i] <= valid_d[i];
            end
        end
    end
endgenerate

assign in_ready_o  = out_ready_i;
assign out_valid_o = valid_q[DataWidth-1];
assign y_o         = p_q[DataWidth-1][2*DataWidth-1:0];

endmodule
