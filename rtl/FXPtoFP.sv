module FXPtoFP#(
    parameter fxpWidth    = 8,
    parameter fxpFraction = 3,
    parameter expWidth    = 8,
    parameter sigWidth    = 23
) (
    input  logic [fxpWidth-1:0] in, 
    output logic                isZero, 
    output logic                sign, 
    output logic [expWidth-1:0] sExp, 
    output logic [sigWidth-1:0] sig
);

  function automatic logic [$clog2(fxpWidth):0] lzc (input logic [fxpWidth-1:0] x);
    logic [$clog2(fxpWidth):0] c;
    begin
      c = 0;
      for (int i = fxpWidth-1; i >= 0; i--) begin
        if (x[i] == 1'b0) c++; else break;
      end
      return c;
    end
  endfunction

  localparam int bias = (1 << (expWidth-1)) - 1;

  logic [$clog2(fxpWidth):0] num_zeros;
  logic [fxpWidth-1:0] absIn;

  // Step 1: sign and abs
  assign sign   = in[fxpWidth-1];
  assign absIn  = sign ? -in : in;
  assign isZero = (absIn == 0);

  // Step 2: leading zeros
  assign num_zeros = lzc(absIn);

  // Step 3: exponent assignment and if 0, just set to 0
  assign sExp = (isZero) ? 0 : bias + ((fxpWidth-1 - num_zeros) - fxpFraction);

  // Step 4: mantissa = shifted absIn into sigWidth bits
  assign sig  = absIn << (sigWidth - (fxpWidth-1 - num_zeros));

endmodule
