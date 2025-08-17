package config_pkg;

/* verilator lint_off UNUSEDPARAM */
/* verilator lint_off UNUSEDSIGNAL */

// Fixed Point format, can be altered
parameter int FXPPrecision = 8;
parameter int FXPFraction  = -3;

typedef logic signed [FXPPrecision-1:0] fixed_t;

localparam fixed_t FXPMin = (1 << (FXPPrecision-1));
localparam fixed_t FXPMax = (FXPMin - 1);

// 32-Bit IEEE-754 Float, can be adjusted to 16-bit IEEE-754 Float or 64-bit IEEE-754 Float
localparam integer FPBiasedExponent = 8;
localparam integer FPMantissa = 23;
localparam integer FPBias = (1 << (FPBiasedExponent-1))-1;

typedef struct packed {
    logic                        sign;
    logic [FPBiasedExponent-1:0] biased_exponent;
    logic [FPMantissa-1:0]       mantissa;
} float_t;

float_t FPMin = '{
    sign: 1'b1,                                           // negative
    biased_exponent: {{(FPBiasedExponent-1){1'b1}},1'b0}, // max exponent before infinity
    mantissa: {FPMantissa{1'b1}}                          // all 1s
};

float_t FPMax = '{
    sign: 1'b0,                                           // positive
    biased_exponent: {{(FPBiasedExponent-1){1'b1}},1'b0}, // max exponent before infinity
    mantissa: {FPMantissa{1'b1}}                          // all 1s
};

float_t FP_Neg_Inf = '{
    sign: 1'b1,                                         // negative
    biased_exponent: {FPBiasedExponent{1'b1}},          // all 1s
    mantissa: {FPMantissa{1'b1}}                        // all 1s
};

float_t FP_Pos_Inf = '{
    sign: 1'b0,                                         // positive
    biased_exponent: {FPBiasedExponent{1'b1}},          // all 1s
    mantissa: {FPMantissa{1'b1}}                        // all 1s
};

function automatic logic float_sign(float_t f);
    return f.sign;
endfunction

function automatic logic [FPMantissa:0] float_significand(float_t f);
    logic not_subnormal = (f.biased_exponent != 0);
    return {not_subnormal, f.mantissa};
endfunction

function automatic logic signed [FPBiasedExponent-1:0] float_exponent(float_t f);
    return f.biased_exponent
        + FPBiasedExponent'(f.biased_exponent == 0)
        - FPBiasedExponent'(FPBias);
endfunction

function automatic float_t neg(float_t f);
    localparam float_t mask = '{sign: 1, default: 0};
    return f ^ mask;
endfunction

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on UNUSEDPARAM */

endpackage
