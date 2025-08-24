
module max_pipe_naive_mul_tb;

parameter int                   DataWidth = 3;
parameter int                   N         = 20;
parameter logic [DataWidth-1:0] MaxValue  = {DataWidth{1'b1}};

typedef struct packed {
    logic [DataWidth-1:0]   a;
    logic [DataWidth-1:0]   b;
    logic [2*DataWidth-1:0] expected_result;
} mul_td;

mul_td vecs [N];
mul_td expected_q[$];
int send_idx;
int cycle_num;

logic                   clk_i;
logic                   rst_i;

logic                   in_ready_o;
logic                   in_valid_i;
logic [DataWidth-1:0]   a_i;
logic [DataWidth-1:0]   b_i;

logic                   out_ready_i;
logic                   out_valid_o;
logic [2*DataWidth-1:0] y_o;

max_pipe_naive_mul #(
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

initial begin
    clk_i = 0;
    forever begin
        clk_i = !clk_i;
        #1ns;
    end
end

initial begin : gen_vecs
    for (int i = 0; i < N; i++) begin
        vecs[i].a = rand_num();
        vecs[i].b = rand_num();
        vecs[i].expected_result = expected_mul(vecs[i].a, vecs[i].b);
    end
end

always @(posedge clk_i) begin
    if (rst_i) begin
        in_valid_i <= 1'b0;
        a_i        <= '0;
        b_i        <= '0;
        send_idx   <= 0;
        expected_q.delete();
    end else begin
        if (in_ready_o && (send_idx < N)) begin
            a_i        <= vecs[send_idx].a;
            b_i        <= vecs[send_idx].b;
            in_valid_i <= 1'b1;

            expected_q.push_back(vecs[send_idx]);
            send_idx++;
        end else begin
            in_valid_i <= 1'b0;
        end

        if (out_valid_o && out_ready_i) begin
            mul_td t;
            if (expected_q.size() == 0) begin
                $fatal(1, "DUT produced output with empty expected queue");
            end

            t = expected_q.pop_front();

            if (y_o !== t.expected_result) begin
                $display("Mismatch: a=%0d b=%0d expected=%0d got=%0d",
                        t.a, t.b, t.expected_result, y_o);
            end else begin
                $display("OK: a=%0d b=%0d => %0d", t.a, t.b, y_o);
            end
        end
    end
    // $display("Cycle num: %d", cycle_num);
    cycle_num++;
end

// always @(posedge clk_i) out_ready_i <= $urandom_range(0,1);

initial begin
    $dumpfile("dump.fst");
    $dumpvars;
    $display("Begin simulation.");
    $timeformat(-6, 3, "us", 0);

    reset();
    out_ready_i = 1'b1; // Need to test randomization of out_ready_i

    // Start driving after reset
    wait (send_idx == N);
    // Finish when all sent and queue drained to zero.
    wait (expected_q.size() == 0);
    // Small guard to catch late glitches
    repeat (2) @(posedge clk_i);
    
    $display("End simulation.");
    $finish;
end

endmodule
