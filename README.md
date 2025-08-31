# RSVM: Random System Verilog Modules

will be changing the name to MRSVM, Random System Verilog modules

## Setup
```bash
# Repository setup
git clone git@github.com:MrPoloGit/custom_sv_modules.git

# Include third party modules
git submodule update --init --recursive

# Installing verilator, or you can use oss-cad-suite
# Linux
sudo apt install verilator

# Windows (in wls)
sudo apt install verilator

# Mac
brew install
```

## Running
```bash
# TOP to specify the testbench file
make sim TOP=testbench
make build TOP=testbench
make run TOP=testbench

# Runs lint on every module
make lint

# To clean up everything
make clean

# To get help
make help

# To run simulation all modules
make all
```

## Notes
### Documentation
- Within docs are md files with simple documentation

### Working Systems
- Linux Works, with oss-cad-suite
- Mac Works, with brew installation
- Windows WSL, isn't tested by me

### Possible future stuff
- floating point implementations
- fixed point implementations
- 8 bits to 5 ternary decompression
- VHDL usage
- cocoTB usage
- FXP to rawFP
- FXP to RecFP
- Modules that work with HardFloat
- FXP modules like HardFloat
- lol maybe make HardFix
- binary search count leading zeros experiment? pipelinable theoretically?
- tree LZD
- signed naive mul, then add handling for fxp, than truncation and sat max and min
- 3 cycle mul, first pass straight to ultiply, wait cycle then arithmatic shit
