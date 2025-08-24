
module naive_mul_tb;

parameter int DataWidth = 4;
parameter logic [DataWidth-1:0] MaxValue = {DataWidth{1'b1}};

logic                   clk_i;
logic                   rst_i;

logic                   in_ready_o;
logic                   in_valid_i;
logic [DataWidth-1:0]   a_i;
logic [DataWidth-1:0]   b_i;

logic                   out_ready_i;
logic                   out_valid_o;
logic [2*DataWidth-1:0] y_o;

naive_mul #(
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

function automatic logic [DataWidth-1:0] rand_num();
    /* verilator lint_off UNUSEDSIGNAL */
    int num, r;
    /* verilator lint_on UNUSEDSIGNAL */
    num = $urandom_range(0, 2);

    case (num)
        /* verilator lint_off WIDTHEXPAND */
        0: r = 0;
        1: r = MaxValue;
        2: r = $urandom_range(0, MaxValue);
        /* verilator lint_on WIDTHEXPAND */
    endcase

    return r[DataWidth-1:0];
endfunction

function automatic logic [2*DataWidth-1:0] expected_mul(
    logic [DataWidth-1:0] a,
    logic [DataWidth-1:0] b
);
    return a * b;
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
    logic [DataWidth-1:0] a,
    logic [DataWidth-1:0] b
);
    logic [2*DataWidth-1:0] expected_result;
    logic [2*DataWidth-1:0] received_result;

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

    expected_result = expected_mul(a, b);

    if (expected_result != received_result) begin
        $display("Mismatch: a=%0d, b=%0d, expected=%0d, received=%0d",
                a, b, expected_result, received_result
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
    logic [DataWidth-1:0] a, b;

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
