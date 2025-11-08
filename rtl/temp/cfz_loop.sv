module cfz_loop # (
    parameter DataWidth = 8;
) {
    input  logic [(DataWidth-1):0]      in,
    output logic [($clog2(DataWidth)):0] out
}

    always_comb begin
        out = 0;
        for (int i = 0; i < DataWidth; i++) begin
            if (in[i]) out = out++;
        end
    end

endmodule
