`timescale 1ns/1ps

module FXPtoFP_tb;

  // === Parameters ===
  localparam int fxpWidth    = 8;   // fixed-point width
  localparam int fxpFraction = 3;   // number of fractional bits

  // Choose FP format here
  localparam int expWidth    = 8;   // 8 for FP32, 5 for FP16
  localparam int sigWidth    = 23;  // 23 for FP32, 10 for FP16

  localparam int fpWidth     = 1 + expWidth + sigWidth;

  // === DUT IO ===
  logic [fxpWidth-1:0] in;
  logic                isZero;
  logic                sign;
  logic [expWidth-1:0] sExp;
  logic [sigWidth-1:0] sig;

  // === File handles ===
  integer fd;
  integer fd_fp;

  // === DUT instance ===
  FXPtoFP #(
    .fxpWidth(fxpWidth),
    .fxpFraction(fxpFraction),
    .expWidth(expWidth),
    .sigWidth(sigWidth)
  ) dut (
    .in(in),
    .isZero(isZero),
    .sign(sign),
    .sExp(sExp),
    .sig(sig)
  );

  // === Utility function ===
  function shortreal fxp_to_real(input logic [fxpWidth-1:0] raw);
    int signed_val;
    begin
      signed_val = raw;
      if (raw[fxpWidth-1])  // sign extend
        signed_val = raw - (1 << fxpWidth);
      return signed_val / shortreal'(1 << fxpFraction);
    end
  endfunction

  // === Testbench procedure ===
  initial begin
    fd    = $fopen("fxptofp_sv.txt", "w");
    fd_fp = $fopen("fp_sv.txt", "w");

    if (fd == 0 || fd_fp == 0) begin
      $display("ERROR: Could not open one of the output files!");
      $finish;
    end

    // Print header for fxptofp_sv.txt
    if (fpWidth == 16)                   $fwrite(fd, "%-12s %-20s %-6s %-8s  %-12s\n", "number", "fxp", "sign", "sExp", "sig");
    if (fxpWidth == 8 && fpWidth == 32)  $fwrite(fd, "%-12s %-12s %-6s %-11s %-12s\n", "number", "fxp", "sign", "sExp", "sig");
    if (fxpWidth == 16 && fpWidth == 32) $fwrite(fd, "%-12s %-20s %-6s %-11s %-12s\n", "number", "fxp", "sign", "sExp", "sig");

    for (int i = 0; i < (1 << fxpWidth); i++) begin
      real val;
      logic [fpWidth-1:0] fp_bits;

      in = i[fxpWidth-1:0];
      #1; // settle combinational outputs

      val     = fxp_to_real(in);
      fp_bits = {sign, sExp, sig};

      // Printing out
      if (fpWidth == 16)                   $fwrite(fd, "%-12.3f %08b     %01b     %05b     %010b\n", val, in, sign, sExp, sig);
      if (fxpWidth == 8 && fpWidth == 32)  $fwrite(fd, "%-12.3f %08b     %01b     %08b     %023b\n", val, in, sign, sExp, sig);
      if (fxpWidth == 16 && fpWidth == 32) $fwrite(fd, "%-16.8f %016b     %01b     %05b     %010b\n", val, in, sign, sExp, sig);

      // Write just fp_bits to fp_sv.txt
      if (fpWidth == 16) $fwrite(fd_fp, "%016b\n", fp_bits);
      if (fpWidth == 32) $fwrite(fd_fp, "%032b\n", fp_bits);
      
    end

    $fclose(fd);
    $fclose(fd_fp);

    $display("Simulation complete. Results written to fxptofp_sv.txt and fp_sv.txt");
    $finish;
  end

endmodule
