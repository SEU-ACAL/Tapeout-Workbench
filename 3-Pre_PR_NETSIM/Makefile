SHELL := /bin/bash

TECH ?= tsmc28
TECH_CONFIG := scripts/tech/$(TECH).mk
ifeq ($(wildcard $(TECH_CONFIG)),)
$(error Unknown TECH '$(TECH)'; expected a configuration under scripts/tech)
endif
include $(TECH_CONFIG)

TAPE_ENV ?=
SOC_GENERATOR_DIR := $(TAPE_ENV)/soc-generator
CONFIG ?= chipyard.harness.TestHarness.TapeoutConfig
BUILD_DIR ?= $(SOC_GENERATOR_DIR)/sims/vcs/generated-src/$(CONFIG)
NETLIST_RUN ?= 0720_1845
NETLIST ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/ChipTop.v
SDF ?= $(CURDIR)/inputs/$(NETLIST_RUN)/ChipTop.sdf
TOP ?= ChipTop
TB ?= TestDriver
CLOCK_PERIOD ?= 1.0
RESET_DELAY ?= 777.7
TIMEOUT_CYCLES ?= 10000000
WAVEFORM ?= 0

STD_CELL_MODEL ?= $(TECH_STD_CELL_MODEL)
SRAM_ROOT ?= $(TECH_SRAM_ROOT)
SRAM_CORNER ?= $(TECH_SRAM_CORNER)
SRAM_MODEL_TEMPLATE ?= $(TECH_SRAM_MODEL_TEMPLATE)

GEN_DIR := $(CURDIR)/gen/$(CONFIG)/$(NETLIST_RUN)
HARNESS_FILELIST := $(GEN_DIR)/harness.f
SRAM_FILELIST := $(GEN_DIR)/sram.f
GLS_FILELIST := $(GEN_DIR)/gls.f
TEST_DRIVER := $(SOC_GENERATOR_DIR)/generator/rocket-chip/src/main/resources/vsrc/TestDriver.v
SDF_ANNOTATE := $(CURDIR)/tb/sdf_annotate.sv
PREPARE_FILELIST := $(CURDIR)/scripts/prepare_gls_filelist.sh
VCS_MAKE_WRAPPER := $(CURDIR)/scripts/vcs_make_wrapper.sh

VCS ?= vcs -full64
RISCV ?=
DRAMSIM_DIR ?= $(TAPE_ENV)/dependencies/tools/DRAMSim2
DRAMSIM_INI_DIR ?= $(SOC_GENERATOR_DIR)/generator/testchipip/src/main/resources/dramsim2_ini

ifeq ($(WAVEFORM),1)
WAVEFORM_SUFFIX := -fsdb
WAVEFORM_VCS_FLAGS := +define+DEBUG -debug_access+all -kdb -lca
else ifeq ($(WAVEFORM),0)
WAVEFORM_SUFFIX :=
WAVEFORM_VCS_FLAGS :=
else
$(error WAVEFORM must be 0 or 1)
endif

ZERO_SIM := $(GEN_DIR)/simv-gls-zero$(WAVEFORM_SUFFIX)
SDF_SIM := $(GEN_DIR)/simv-gls-sdf$(WAVEFORM_SUFFIX)
ZERO_MDIR := simv-gls-zero$(WAVEFORM_SUFFIX).daidir
SDF_MDIR := simv-gls-sdf$(WAVEFORM_SUFFIX).daidir
GLS_PRODUCTS := \
	$(GEN_DIR)/simv-gls-zero \
	$(GEN_DIR)/simv-gls-zero-fsdb \
	$(GEN_DIR)/simv-gls-sdf \
	$(GEN_DIR)/simv-gls-sdf-fsdb

VCS_FLAGS := -notice -line \
	+lint=all,noVCDE,noONGS,noUI \
	-error=PCWM-L -error=noZMMCM \
	-timescale=1ns/10ps -quiet -q +rad +vcs+lic+wait +vc+list \
	-debug_pp \
	-Mmakep=$(VCS_MAKE_WRAPPER) \
	-f $(GLS_FILELIST) \
	-sverilog +systemverilogext+.sv+.svi+.svh+.svt -assert svaext +libext+.sv \
	+v2k +verilog2001ext+.v95+.vt+.vp +libext+.v \
	-top $(TB) +incdir+$(BUILD_DIR)/gen-collateral \
	+define+CLOCK_PERIOD=$(CLOCK_PERIOD) +define+RESET_DELAY=$(RESET_DELAY) \
	+define+MODEL=TestHarness +define+PRINTF_COND=$(TB).printf_cond \
	+define+STOP_COND=!$(TB).reset \
	+define+RANDOMIZE_MEM_INIT +define+RANDOMIZE_REG_INIT \
	+define+RANDOMIZE_GARBAGE_ASSIGN +define+RANDOMIZE_INVALID_ASSIGN \
	+define+VCS +define+FSDB +define+GATE_LEVEL \
	-CFLAGS "-O3 -std=c++17 -I$(RISCV)/include -I$(DRAMSIM_DIR) -I$(BUILD_DIR)/gen-collateral" \
	-LDFLAGS "-L$(RISCV)/lib -Wl,-rpath,$(RISCV)/lib -L$(SOC_GENERATOR_DIR)/sims/vcs -L$(DRAMSIM_DIR) -no-pie" \
	-lriscv -lfesvr -ldramsim

ZERO_VCS_FLAGS := +define+UNIT_DELAY +define+no_warning +nospecify
SDF_VCS_FLAGS := +define+SDF +define+SDF_FILE=\"$(abspath $(SDF))\" +neg_tchk -top sdf_annotate
RUN_FLAGS ?= +dramsim +dramsim_ini_dir=$(DRAMSIM_INI_DIR) +max-cycles=$(TIMEOUT_CYCLES)
ifdef RANDOM_SEED
SEED_FLAG = +ntb_random_seed=$(RANDOM_SEED)
else
SEED_FLAG = +ntb_random_seed_automatic
endif
LOADMEM ?= 1
ifeq ($(LOADMEM),1)
LOADMEM_FLAG = +loadmem=$(BINARY)
else ifneq ($(LOADMEM),)
LOADMEM_FLAG = +loadmem=$(LOADMEM)
endif
ifeq ($(WAVEFORM),1)
WAVEFORM_RUN_ZERO := +fsdbfile=$(GEN_DIR)/run-zero.fsdb
WAVEFORM_RUN_SDF := +fsdbfile=$(GEN_DIR)/run-sdf.fsdb
endif

.PHONY: help check-config prepare gls_zero gls_sdf run_zero run_sdf clean-gls

help:
	@printf '%s\n' \
	  'Run from the Chipyard Nix development shell so RISCV and VCS are exported.' \
	  'make gls_zero [TECH=tsmc28|smic180] [NETLIST_RUN=<run>]  Build no-SDF gate-level simulation.' \
	  'make gls_sdf [TECH=tsmc28|smic180] SDF=<path>             Build gate-level simulation with SDF.' \
	  'make run_zero BINARY=<elf>          Run no-SDF gate-level simulation.' \
	  'make run_sdf SDF=<path> BINARY=<elf> Run SDF gate-level simulation.' \
	  'TECH defaults to tsmc28; STD_CELL_MODEL, SRAM_ROOT, SRAM_CORNER, and SRAM_MODEL_TEMPLATE remain overridable.' \
	  'Add WAVEFORM=1 to build and run commands to write an FSDB file.' \
	  'make clean-gls                       Remove GLS simulators and VCS Mdirs, preserving FSDB files.'

check-config:
	@test -n '$(TAPE_ENV)' || { echo 'TAPE_ENV is unset; provide the tape-env repository root path'; exit 2; }
	@test -n '$(STD_CELL_MODEL)' || { echo 'STD_CELL_MODEL is unset; provide the standard-cell Verilog model path'; exit 2; }
	@test -n '$(SRAM_ROOT)' || { echo 'SRAM_ROOT is unset; provide the SRAM model root path'; exit 2; }
	@test -n '$(SRAM_MODEL_TEMPLATE)' || { echo 'SRAM_MODEL_TEMPLATE is unset; provide the per-macro Verilog path template'; exit 2; }

prepare: check-config $(GLS_FILELIST)

$(GLS_FILELIST): $(PREPARE_FILELIST) $(NETLIST) $(TEST_DRIVER) $(SDF_ANNOTATE)
	@NETLIST='$(abspath $(NETLIST))' \
	 BUILD_DIR='$(abspath $(BUILD_DIR))' \
	 TOP='$(TOP)' \
	 TEST_DRIVER='$(abspath $(TEST_DRIVER))' \
	 SDF_ANNOTATE='$(abspath $(SDF_ANNOTATE))' \
	 STD_CELL_MODEL='$(abspath $(STD_CELL_MODEL))' \
	 SRAM_ROOT='$(abspath $(SRAM_ROOT))' \
	 SRAM_CORNER='$(SRAM_CORNER)' \
	 SRAM_MODEL_TEMPLATE='$(SRAM_MODEL_TEMPLATE)' \
	 HARNESS_FILELIST='$(abspath $(HARNESS_FILELIST))' \
	 SRAM_FILELIST='$(abspath $(SRAM_FILELIST))' \
	 GLS_FILELIST='$(abspath $(GLS_FILELIST))' \
	 '$(PREPARE_FILELIST)'

$(ZERO_SIM): check-config $(GLS_FILELIST) Makefile
	@test -n '$(RISCV)' || { echo 'RISCV is unset; enter the Chipyard Nix development shell first'; exit 2; }
	# Match Chipyard: never reuse a VCS Mdir across compile invocations.
	@rm -rf $(GEN_DIR)/$(ZERO_MDIR)
	$(VCS) $(VCS_FLAGS) $(ZERO_VCS_FLAGS) $(WAVEFORM_VCS_FLAGS) -o $@ -Mdir=$(GEN_DIR)/$(ZERO_MDIR) -l $@.compile.log

$(SDF_SIM): check-config $(GLS_FILELIST) $(SDF) Makefile
	@test -n '$(RISCV)' || { echo 'RISCV is unset; enter the Chipyard Nix development shell first'; exit 2; }
	# Match Chipyard: never reuse a VCS Mdir across compile invocations.
	@rm -rf $(GEN_DIR)/$(SDF_MDIR)
	$(VCS) $(VCS_FLAGS) $(SDF_VCS_FLAGS) $(WAVEFORM_VCS_FLAGS) -o $@ -Mdir=$(GEN_DIR)/$(SDF_MDIR) -l $@.compile.log

gls_zero: $(ZERO_SIM)
gls_sdf: $(SDF_SIM)

$(SDF):
	@echo "Missing SDF: $@" >&2
	@echo "Set SDF=<path> or generate it with: make -C ../4-Pre_PR_STA_POWER sdf NETLIST_RUN=$(NETLIST_RUN)" >&2
	@exit 2

run_zero: $(ZERO_SIM)
	@test -n '$(BINARY)' || { echo 'Set BINARY=<ELF>'; exit 2; }
	$(ZERO_SIM) +permissive $(RUN_FLAGS) $(SEED_FLAG) $(LOADMEM_FLAG) $(WAVEFORM_RUN_ZERO) +permissive-off $(BINARY) -l $(GEN_DIR)/run-zero.log

run_sdf: $(SDF_SIM)
	@test -n '$(BINARY)' || { echo 'Set BINARY=<ELF>'; exit 2; }
	$(SDF_SIM) +permissive $(RUN_FLAGS) $(SEED_FLAG) $(LOADMEM_FLAG) $(WAVEFORM_RUN_SDF) +permissive-off $(BINARY) -l $(GEN_DIR)/run-sdf.log

clean-gls:
	@rm -rf $(GLS_PRODUCTS) $(addsuffix .daidir,$(GLS_PRODUCTS))
