// If you are compute bound it would probably better to use LUTs instead of this
module bit8totrit5 import config_pkg::*; (
    input  logic [7:0]     b_i,
    output ternary_t [4:0] t_o
);

    logic [7:0] b;
    logic [9:0] t;

    logic [9:0] x;
    logic [9:0] y;
    logic [2:0] z;

    assign b = b_i;

    assign x[0] = y[1] & b[2];
    assign x[1] = (~b[0] | b[5]) & ~b[6] & ~b[1] & b[2] | ~b[3] | x[0];
    assign x[2] = z[2] & b[3] & b[2];
    assign x[3] = (b[0] & z[0] | z[2]) & ~b[7] & y[9];
    assign x[4] = y[2] & ~b[5] | z[1] | y[1];
    assign x[5] = y[3] & ~b[6] & ~b[5] | y[6] & b[2] & b[6] | y[5] & y[9];
    assign x[6] = (y[8] | b[1] & ~b[4]) & b[2] | y[8] & ~b[4] & b[3] | y[7] | b[0] & z[1] | y[1];
    assign x[7] = ~b[0] & ~b[2] & (~b[1] | b[3]) | y[2] & b[5];
    assign x[8] = (~b[7] | ~y[9]) & y[1] | y[7];
    assign x[9] = y[6] & ~b[2] | y[4] & ~b[3] | x[2] & b[6] & b[4] | y[5] | y[3] & ~b[7] & b[6];

    assign y[0] = ~b[1] & ~y[9] | b[7] & z[0] | y[5] | b[1] & y[9] & b[7];
    assign y[1] = b[0] & b[1];
    assign y[2] = ~y[4] & (b[0] ^ b[1]) & ~b[3] & ~b[2];
    assign y[3] = b[0] & ~b[1] & b[3];
    assign y[4] = ~(b[0] | ~b[4]);
    assign y[5] = ~b[0] & ~b[1];
    assign y[6] = ~b[0] & b[3];
    assign y[7] = x[2] & ~b[6];
    assign y[8] = b[0] & b[7] & b[6];
    assign y[9] = ~(~b[3] | b[2]);

    assign z[0] = ~b[6] & ~b[1] & b[5];
    assign z[1] = ~b[3] & b[2];
    assign z[2] = ~b[0] & b[1];

    assign t[0] = x[0] | y[0];
    assign t[1] = b[4] & y[0] | b[3] & x[0];
    assign t[2] = x[8] | x[9];
    assign t[3] = b[5] & x[9] | b[4] & x[8];
    assign t[4] = x[6] & x[7];
    assign t[5] = b[6] & x[7] | b[5] & x[6];
    assign t[6] = x[4] | x[5];
    assign t[7] = b[7] & x[5] | b[6] & x[4];
    assign t[8] = x[1] | x[3];
    assign t[9] = b[4] & x[3] | b[7] & x[1];

    assign t_o = t;

endmodule
