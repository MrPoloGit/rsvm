# ---- Makefile ---- #
TOP          ?= signed_div_tb
RTL_DIR      ?= rtl
DV_DIR       ?= dv
BUILD_DIR    ?= obj_dir
WAVE_FORMAT  ?= fst
SIMULATOR    ?= verilator

RTL_FILELIST ?= $(RTL_DIR)/rtl.f
DV_FILELIST  ?= $(DV_DIR)/dv.f
VERILATOR_FL ?= -f $(DV_DIR)/verilator.f
MDIR 		 ?= $(TOP)

.PHONY: sim build run lint clean help all

build:
	mkdir -p verilator_dir/
	verilator --binary \
	  -Wno-fatal \
	  --Mdir verilator_dir/$(MDIR) \
	  -f dv/dv.f \
	  -f rtl/rtl.f \
	  -f dv/verilator.f \
	  --top $(TOP)

run:
	verilator_dir/$(MDIR)/V$(TOP) +verilator+rand+reset+2

sim: 
	@echo "Running simulation for $(TOP)"
	make build 
	make run

sim-all:
	$(MAKE) sim TOP=naive_mul_tb
	$(MAKE) sim TOP=naive_signed_mul_tb
	$(MAKE) sim TOP=max_pipe_naive_mul_tb
	$(MAKE) sim TOP=signed_mul_tb
	$(MAKE) sim TOP=signed_div_tb
	$(MAKE) sim TOP=bit5totrit3_tb
	$(MAKE) sim TOP=bit8totrit5_tb

lint:
	verilator lint.vlt -f rtl/rtl.f -f dv/dv.f --lint-only -Wno-fatal

clean:
	rm -rf $(BUILD_DIR) dump.$(WAVE_FORMAT) *.log verilator_dir/ *.txt

help:
	@echo "Targets:"
	@echo "  sim    - build and run"
	@echo "  build  - build only"
	@echo "  run    - run built sim"
	@echo "  lint   - verilator lint w/ config"
	@echo "  clean  - remove build artifacts"
	@echo ""
	@echo "Vars (override like VAR=value make sim):"
	@echo "  TOP=$(TOP)"
	@echo "  RTL_FILELIST=$(RTL_FILELIST)"
	@echo "  DV_FILELIST=$(DV_FILELIST)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo "  EXTRA_C_SOURCES=$(EXTRA_C_SOURCES)"

all: 
	chmod +x testall.sh
	./testall.sh