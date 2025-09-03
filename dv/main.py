import struct
import math
import numpy as np  # for half precision

# -------------------------------
# Definitions
# -------------------------------
# Fixed-point configuration
fxpWidth    = 8       # total number of bits
fxpFraction = 3        # number of fractional bits

# Floating-point target precision: 16 or 32
fpWidth     = 32       # <--- change this to 16 or 32

# Assign FP format parameters
if fpWidth == 16:
    exp_bits = 5
    mant_bits = 10
    bias = 15
elif fpWidth == 32:
    exp_bits = 8
    mant_bits = 23
    bias = 127
else:
    raise ValueError("fpWidth must be 16 or 32")


# -------------------------------
# Conversion helpers
# -------------------------------
def float_to_bin32(value: float) -> str:
    [bits] = struct.unpack(">I", struct.pack(">f", value))
    return f"{bits:032b}"

def bin32_to_float(bits: str) -> float:
    as_int = int(bits, 2)
    return struct.unpack(">f", struct.pack(">I", as_int))[0]

def float_to_bin16(value: float) -> str:
    h = np.float16(value)
    [bits] = struct.unpack("<H", h.tobytes())  # numpy is little-endian
    return f"{bits:016b}"

def bin16_to_float(bits: str) -> float:
    as_int = int(bits, 2)
    return np.frombuffer(struct.pack(">H", as_int), dtype=np.float16)[0].item()

def fxp_to_real(raw: int) -> float:
    if raw & (1 << (fxpWidth - 1)):  # sign extend
        raw -= (1 << fxpWidth)
    return raw / (1 << fxpFraction)


# -------------------------------
# Manual FP component extraction
# -------------------------------
def fxp_to_fp_components(raw: int):
    real_val = fxp_to_real(raw)

    if real_val == 0.0:
        return 0, 0, 0

    sign = 0 if real_val >= 0 else 1
    abs_val = abs(real_val)

    exp_unbiased = math.floor(math.log2(abs_val))
    biased_exp = exp_unbiased + bias

    frac = abs_val / (2 ** exp_unbiased) - 1.0
    mantissa = int(frac * (1 << mant_bits)) & ((1 << mant_bits) - 1)

    return sign, biased_exp, mantissa


# -------------------------------
# Main
# -------------------------------
def main():
    with open("fxp_table.txt", "w") as f_table, open("fp_nums.txt", "w") as f_fp:
        # Headers
        f_table.write(
            f"{'real':<12}{'fxp':<{fxpWidth+4}}{'fp bits':<{fpWidth+8}}"
            f"{'decoded':<14}{'sign':<6}{'exp':<{exp_bits+4}}{'mantissa':<{mant_bits+3}}{'check':<10}\n"
        )

        for raw in range(1 << fxpWidth):
            val = fxp_to_real(raw)
            fxp_bits = f"{raw:0{fxpWidth}b}"

            if fpWidth == 32:
                fp_bits = float_to_bin32(val)
                fp_val  = bin32_to_float(fp_bits)
            else:  # fp16
                fp_bits = float_to_bin16(val)
                fp_val  = bin16_to_float(fp_bits)

            # Component verification
            sign, exp, mantissa = fxp_to_fp_components(raw)

            # Recombine into bitstring
            combined = (
                (sign << (exp_bits + mant_bits))
                | (exp << mant_bits)
                | mantissa
            )
            combined_bits = f"{combined:0{fpWidth}b}"

            # Check if matches NumPy/struct result
            match = "OK" if combined_bits == fp_bits else "MISMATCH"

            # Write combined table
            f_table.write(
                f"{val:<12.6f}{fxp_bits:<{fxpWidth+4}}{fp_bits:<{fpWidth+8}}"
                f"{fp_val:<14.6f}{sign:<6}{exp:0{exp_bits}b}   {mantissa:0{mant_bits}b}   {match:<10}\n"
            )

            # Just fp bits
            f_fp.write(fp_bits + "\n")

    print(f"Results written to fxp_table.txt and fp_nums.txt for fp{fpWidth}")


if __name__ == "__main__":
    main()
