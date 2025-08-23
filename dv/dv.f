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
dv/unsigned_mul_tb.sv
dv/signed_mul_tb.sv

// Divider
dv/unsigned_div_tb.sv
dv/signed_div_tb.sv

// Decompressors
dv/bit5totrit3_tb.sv
dv/bit8totrit5_tb.sv