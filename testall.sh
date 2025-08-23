#!/bin/bash

# All modules
# Multipliers
make sim TOP=signed_mul_tb

# Dividers
make sim TOP=signed_div_tb

# Decompressors
make sim TOP=bit5totrit3_tb
make sim TOP=bit8totrit5_tb
