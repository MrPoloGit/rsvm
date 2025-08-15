package config_pkg;

/* verilator lint_off UNUSEDPARAM */
parameter int FXPPrecision = 8;
parameter int FXPExponent = -3;

typedef logic signed [FXPPrecision-1:0] fxp_t;

localparam fxp_t FXPMin = (1 << (FXPPrecision-1));
localparam fxp_t FXPMax = (FXPMin - 1);

// Need to add floating point, and all other unqiue numerical types I may try
/* verilator lint_on UNUSEDPARAM */

endpackage
