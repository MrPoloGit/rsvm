// Settings ------------------------------------------------
// Thanks to Ethan Sifferman
// Flags
--timing
-j 0
-Wall
--assert
--trace-fst
--trace-structs
--main-top-name "-"

// Running with +verilator+rand+reset+2
--x-assign unique
--x-initial unique

-Werror-IMPLICIT
-Werror-USERERROR
-Werror-LATCH

// Some compilers need this
-CFLAGS -std=c++20

// Testbench sources ----------------------------------------
// Package
dv/dv_pkg.sv

// Multiplier
dv/mul/naive_mul_tb.sv
dv/mul/max_pipe_naive_mul_tb.sv
dv/mul/naive_signed_mul_tb.sv
dv/mul/signed_mul_tb.sv

// Divider
dv/div/unsigned_div_tb.sv
dv/div/signed_div_tb.sv

// Decompressors
dv/decompressors/bit5totrit3_tb.sv
dv/decompressors/bit8totrit5_tb.sv