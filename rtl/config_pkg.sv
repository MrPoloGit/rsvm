package config_pkg;

/* verilator lint_off UNUSEDPARAM */
parameter int FXPPrecision = 8;
parameter int FXPExponent = -3;

typedef logic signed [FXPPrecision-1:0] fixed_point_t;

localparam fixed_point_t FXPMin = (1 << (FXPPrecision-1));
localparam fixed_point_t FXPMax = (FXPMin - 1);
/* verilator lint_on UNUSEDPARAM */

endpackage
