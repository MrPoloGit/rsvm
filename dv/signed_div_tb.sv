
module signed_div_tb;

parameter int DataWidth = 4;

logic                  clk_i;
logic                  rst_i;

logic                  in_ready_o;
logic                  in_valid_i;
logic [DataWidth-1: 0] a_i;
logic [DataWidth-1: 0] b_i;

logic                  out_ready_i;
logic                  out_valid_o;
logic [DataWidth-1: 0] y_o;

signed_div #(
    .DataWidth(DataWidth)
) dut (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .in_ready_o(in_ready_o),
    .in_valid_i(in_valid_i),
    .a_i(a_i),
    .b_i(b_i),

    .out_ready_i(out_ready_i),
    .out_valid_o(out_valid_o),
    .y_o(y_o)
);

function automatic logic signed [DataWidth-1:0] rand_num();
    /* verilator lint_off UNUSEDSIGNAL */
    int val = $urandom_range(-(1 << (DataWidth-1)), (1 << (DataWidth-1)) - 1);
    /* verilator lint_on UNUSEDSIGNAL */
    return val[DataWidth-1:0];
    
endfunction

// Expected division result
function automatic logic signed [DataWidth-1:0] expected_div(
    logic signed [DataWidth-1:0] a,
    logic signed [DataWidth-1:0] b
);
    if (b == 0) return '0; // Avoid divide-by-zero
    return a / b;
endfunction

task automatic reset();
    rst_i      = 1;
    in_valid_i  = 0;
    out_ready_i = 0;
    a_i = 0;
    b_i = 0;
    repeat (10) @(posedge clk_i); #1ps;
    rst_i = 0;
endtask

task automatic test(
    logic signed [DataWidth-1:0] a,
    logic signed [DataWidth-1:0] b
);
    logic signed [DataWidth-1:0] expected_result;
    logic signed [DataWidth-1:0] received_result;
    
    // Skip divide by zero cases
    if (b == 0) begin
        $display("Skipping divide by zero case: a=%0d (0x%0h), b=%0d (0x%0h)", 
        a, a,
        b, b,
        );
        return;
    end

    a_i     = a;
    b_i     = b;
    in_valid_i = 1;
    wait(in_ready_o);
    @(posedge clk_i); #1ps;
    in_valid_i = 0;

    out_ready_i = 1;
    wait(out_valid_o); #1ps;
    received_result = y_o;
    @(posedge clk_i); #1ps;
    out_ready_i = 0;

    expected_result = expected_div(a, b);

    if (expected_result != received_result) begin
        $display("Mismatch: a=%0d (0x%0h), b=%0d (0x%0h), expected=%0d (0x%0h), got=%0d (0x%0h)",
            a, a,
            b, b,
            expected_result, expected_result,
            received_result, received_result
        );
    end
endtask

initial begin
    clk_i = 0;
    forever begin
        clk_i = !clk_i;
        #1ns;
    end
end

initial begin
    logic signed [DataWidth-1:0] a, b;

    $dumpfile("dump.fst");
    $dumpvars;
    $display("Begin simulation.");
    $timeformat(-6, 3, "us", 0);

    reset();

    repeat (100) begin
        a = rand_num();
        b = rand_num();
        test(a, b);
    end

    $display("End simulation.");
    $finish;
end


endmodule
