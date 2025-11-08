module clz_loop # (
    parameter DataWidth = 8;
) {
    input  logic [(DataWidth-1):0]      in,
    output logic [($clog2(DataWidth)):0] out
}

    always_comb begin
        out = 0;
        for (int i = DataWidth-1; i >= 0; i--) begin
            if (in[i]) out = out++;
        end
    end

endmodule
