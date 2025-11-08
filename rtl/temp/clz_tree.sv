module clz_tree #(
    parameter int DataWidth = 8
) (
    input  logic [DataWidth-1:0] in,
    output logic [$clog2(DataWidth):0] out
);

    // Base case: 1 bit
    if (DataWidth == 1) begin : base
        assign out = (in[0] == 1'b1) ? 0 : 1; 
    end else begin : recurse
        localparam int Half = DataWidth/2;

        logic [$clog2(Half):0] high_count, low_count;
        logic [Half-1:0] high_bits = in[DataWidth-1:Half];
        logic [Half-1:0] low_bits  = in[Half-1:0];

        clz_tree #(.DataWidth(Half)) clz_high (
            .in (high_bits),
            .out(high_count)
        );

        clz_tree #(.DataWidth(Half)) clz_low (
            .in (low_bits),
            .out(low_count)
        );

        always_comb begin
            if (|high_bits) begin
                out = high_count;   // leading ones in high half
            end else begin
                out = Half + low_count;  // skip past high half
            end
        end
    end

endmodule
