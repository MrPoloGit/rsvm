// If you are compute bound it would probably better to use LUTs instead of this
module bit5totrit3 import config_pkg::*; (
    input logic [4:0]     b_i,
    output ternary_t [2:0] t_o
);

logic [4:0] b;
logic [5:0] t;

logic [1:0] x;

assign b = b_i;

assign x[0] = b[0] & (b[1] | b[2]);
assign x[1] = b[0] | b[1];

assign t[0] = b[1] | ~b[0] & b[4];
assign t[1] = t[0] & b[2];
assign t[2] = x[0] | ~x[1];
assign t[3] = t[2] & b[3];
assign t[4] = x[0] | b[3] & x[1];
assign t[5] = t[4] & b[4];


// Will verilator understand this?
// assign t_o = t;

assign t_o[0] = t[1:0];
assign t_o[1] = t[3:2];
assign t_o[2] = t[5:4];

endmodule
