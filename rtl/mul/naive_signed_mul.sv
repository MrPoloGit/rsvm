module naive_signed_mul #(
    parameter DataWidth = 4,
    parameter int Log2DataWidth = $clog2(DataWidth)
) (
    input  logic                          clk_i,
    input  logic                          rst_i,

    output logic                          in_ready_o,
    input  logic                          in_valid_i,
    input  logic signed [DataWidth-1:0]   a_i,
    input  logic signed [DataWidth-1:0]   b_i,

    output logic                          out_valid_o,
    input  logic                          out_ready_i,
    output logic signed [2*DataWidth-1:0] y_o
);

    typedef enum logic[2:0] {
        IDLE,
        CALC,
        POSTOP,
        DONE
    } state_t;

    state_t state_d, state_q;

    logic [DataWidth-1:0] m_d, m_q;
    logic [2*DataWidth:0] p_d, p_q;

    logic [Log2DataWidth:0] iter_d, iter_q;

    logic a_sign_d, a_sign_q;
    logic b_sign_d, b_sign_q;

    always_comb begin
        state_d     = state_q;
        m_d         = m_q;
        p_d         = p_q;
        iter_d      = iter_q;
        a_sign_d    = a_sign_q;
        b_sign_d    = b_sign_q;

        in_ready_o  = 0;
        out_valid_o = 0;

        case (state_q)
            IDLE: begin
                in_ready_o = 1;
                if (in_valid_i) begin
                    a_sign_d = a_i[DataWidth-1];
                    m_d = a_i[DataWidth-1] ? -a_i : a_i;


                    b_sign_d = b_i[DataWidth-1];
                    p_d = b_i[DataWidth-1] ? -b_i : b_i;

                    iter_d = '0;
                    state_d = CALC;
                end
            end
            CALC: begin
                if (iter_q < DataWidth) begin
                    if (p_q[0]) begin
                        p_d[2*DataWidth:DataWidth] = p_q[2*DataWidth:DataWidth] + {1'b0, m_q};
                    end
                    p_d    = p_d >> 1;
                    iter_d = iter_q + 1;
                end else begin
                    if (a_sign_q ^ b_sign_q) p_d = -p_q;
                    state_d = DONE;
                end
            end
            DONE: begin
                out_valid_o = 1;
                if (out_ready_i) begin
                    state_d = IDLE;
                end
            end
            default: state_d = IDLE;
        endcase
    end

    assign y_o = p_q[2*DataWidth-1:0];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q  <= IDLE;
            m_q      <= '0;
            p_q      <= '0;
            iter_q   <= '0;
            a_sign_q <= 0;
            b_sign_q <= 0;
        end else begin
            state_q  <= state_d;
            m_q      <= m_d;
            p_q      <= p_d;
            iter_q   <= iter_d;
            a_sign_q <= a_sign_d;
            b_sign_q <= b_sign_d;
        end
    end
endmodule
