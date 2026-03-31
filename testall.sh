# Multiplication
make sim TOP=naive_mul_tb
make sim TOP=naive_signed_mul_tb
make sim TOP=max_pipe_naive_mul_tb
make sim TOP=signed_mul_t

# Division
make sim TOP=signed_div_tb

# Compression and Decompression
make sim TOP=bit5totrit3_tb
make sim TOP=bit8totrit5_tb