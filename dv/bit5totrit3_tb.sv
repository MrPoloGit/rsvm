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

function automatic ternary_t [2:0] expected_trit3 (logic [4:0] b);
    int i;
    int val;
    int temp;
    int remainder;
    ternary_t [2:0] t;

    val = b;
    for (i = 2; i >= 0; i--) begin
        temp = val / 3;
        remainder = val % 3;

        case(remainder)
            0: begin
                t[i] = -1;
            end
            1: begin
                t[i] = 0;
            end
            2: begin
                t[i] = 1;
            end
            default: t[i] = 0;
        endcase
    end

    return t;
endfunction

task automatic test();
    int b;
    ternary_t [2:0] expected_result;
    ternary_t [2:0] received_result;

    for(b = 0; b < 32; b++) begin
        b_i = b[4:0];
        received_result = t_o;
        expected_result = expected_trit3(b);
        #100ps;
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
