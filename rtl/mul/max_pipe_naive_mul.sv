module max_pipe_naive_mul #(
    parameter DataWidth = 4
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
logic [2*DataWidth:0] tmp;

generate
    genvar i;
    for (i = 0; i < DataWidth; i++) begin
        always_comb begin
            m_d[i]     = m_q[i];
            p_d[i]     = p_q[i];
            valid_d[i] = valid_q[i];
            tmp        = '0;

            if (out_ready_i) begin
                if (i == 0) begin
                    
                    m_d[i]     = a_i;
                    p_d[i]     = {{(DataWidth+1){1'b0}}, b_i};;
                    valid_d[i] = in_valid_i;
                end else begin
                    m_d[i]     = m_q[i-1];
                    valid_d[i] = valid_q[i-1];

                    tmp = p_q[i-1]; // use registered previous stage

                    if (tmp[0]) begin
                        tmp[2*DataWidth:DataWidth] =
                            tmp[2*DataWidth:DataWidth] + {1'b0, m_q[i-1]};  // add multiplicand
                    end

                    // logical right shift by 1 (guard-in zero)
                    p_d[i] = {1'b0, tmp[2*DataWidth:1]};
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
