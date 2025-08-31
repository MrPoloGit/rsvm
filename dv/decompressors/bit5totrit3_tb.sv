module bit5totrit3_tb
    import config_pkg::*;
    import dv_pkg::*;
;

logic [4:0]     b_i;
ternary_t [2:0] t_o;

bit5totrit3 dut (
    .b_i(b_i),
    .t_o(t_o)
);

function automatic ternary_t [2:0] expected_trit3_2 (logic [4:0] b);
    logic [5:0] t;

    casez (b)
        5'b?0001: t = 6'b000000;
        5'b?0010: t = 6'b000001;
        5'b?0110: t = 6'b000011;
        5'b00?00: t = 6'b000100;
        5'b01?00: t = 6'b001100;
        5'b00011: t = 6'b010101;
        5'b00101: t = 6'b010100;
        5'b00111: t = 6'b010111;
        5'b01001: t = 6'b010000;
        5'b01010: t = 6'b010001;
        5'b01011: t = 6'b011101;
        5'b01101: t = 6'b011100;
        5'b01110: t = 6'b010011;
        5'b01111: t = 6'b011111;

        5'b10000: t = 6'b000101;
        5'b10011: t = 6'b110101;
        5'b10100: t = 6'b000111;
        5'b10101: t = 6'b110100;
        5'b10111: t = 6'b110111;
        5'b11000: t = 6'b001101;
        5'b11001: t = 6'b110000;
        5'b11010: t = 6'b110001;
        5'b11011: t = 6'b111101;
        5'b11100: t = 6'b001111;
        5'b11101: t = 6'b111100;
        5'b11110: t = 6'b110011;
        5'b11111: t = 6'b111111;

        default:  t = 6'bxxxxxx;
    endcase

    return t;
endfunction

task automatic test();
    int b;
    ternary_t [2:0] expected_result;
    ternary_t [2:0] received_result;

    for(b = 0; b < 32; b++) begin
        b_i = b[4:0];
        #100ns;
        received_result = t_o;
        expected_result = expected_trit3_2(b_i);
        if (expected_result != received_result) begin
            $display("Mismatch: b=%d (%b), expected_result=%p, received_result=%p",
                b_i, b_i, expected_result, received_result);

            $write("  expected_result (ternary): ");
            foreach (expected_result[i]) $write("%0d ", expected_result[i]);
            $write("\n  expected_result (binary) : ");
            foreach (expected_result[i]) $write("%b ", expected_result[i]);
            $write("\n");

            $write("  received_result (ternary): ");
            foreach (received_result[i]) $write("%0d ", received_result[i]);
            $write("\n  received_result (binary) : ");
            foreach (received_result[i]) $write("%b ", received_result[i]);
            $write("\n");
        end
    end
endtask

initial begin : simulation_timeout
    #10s;
    $fatal(1, "Simulation timed out at %0t", $time);
end

initial begin
    $dumpfile("dump.fst");
    $dumpvars;
    $display("Begin simulation.");
    $timeformat(-6, 3, "us", 0);

    test();
    
    $display("End simulation.");
    $finish;
end

endmodule
