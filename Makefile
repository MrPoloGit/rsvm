# ---- Project config ----
TOP           ?= signed_div_tb
RTL_DIR       ?= rtl
DV_DIR        ?= dv
BUILD_DIR     ?= obj_dir
WAVE_FORMAT   ?= fst
SIMULATOR     ?= verilator


RTL_FILELIST  ?= $(RTL_DIR)/rtl.f
DV_FILELIST   ?= $(DV_DIR)/dv.f
VERILATOR_FL  ?= -f $(DV_DIR)/verilator.f
MDIR := verilator_dir

.PHONY: all sim build run lint clean help
all: sim


build:
	verilator --binary \
	  --Mdir $(MDIR) \
	  -f dv/dv.f \
	  -f rtl/rtl.f \
	  -f dv/verilator.f \
	  --top $(TOP)

run:
	$(MDIR)/V$(TOP) +verilator+rand+reset+2

sim: build run

lint:
	verilator lint.vlt -f rtl/rtl.f -f dv/dv.f --lint-only

clean:
	rm -rf $(BUILD_DIR) dump.$(WAVE_FORMAT) *.log verilator_dir/

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
