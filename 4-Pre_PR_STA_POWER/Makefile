SHELL := /bin/bash

TECH ?= smic180
TECH_CONFIG := scripts/tech/$(TECH).mk
ifeq ($(wildcard $(TECH_CONFIG)),)
$(error Unknown TECH '$(TECH)'; expected a configuration under scripts/tech)
endif
include $(TECH_CONFIG)

NETLIST_RUN ?= 0731_0611
TOP ?= ChipTop
NETLIST ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/$(TOP).v
SDC ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/$(TOP).sdc
SDF_OUT ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/$(TOP).sdf
CONFIG ?= chipyard.harness.TestHarness.TapeoutConfig
FSDB ?= $(CURDIR)/../3-Pre_PR_NETSIM/gen/$(CONFIG)/$(NETLIST_RUN)/run-sdf.fsdb
POWER_OUT_DIR ?= $(CURDIR)/outputs/$(TECH)/$(NETLIST_RUN)/sdf-fsdb
ACTIVITY_STRIP_PATH ?= TestDriver/testHarness/chiptop0
POWER_START_NS ?= 1000
POWER_END_NS ?= -1
STD_CELL_DB ?= $(TECH_STD_CELL_DB)
IO_DB ?= $(TECH_IO_DB)
SRAM_ROOT ?= $(TECH_SRAM_ROOT)
SRAM_CORNER ?= $(TECH_SRAM_CORNER)
SRAM_DB_TEMPLATE ?= $(TECH_SRAM_DB_TEMPLATE)
ROM_ROOT ?= $(TECH_ROM_ROOT)
ROM_CORNER ?= $(TECH_ROM_CORNER)
ROM_DB_TEMPLATE ?= $(TECH_ROM_DB_TEMPLATE)
PT_SHELL ?= pt_shell

.PHONY: help check-config sdf power sdf_power

help:
	@printf '%s\n' \
	  'make sdf [TECH=smic180|tsmc28] [NETLIST_RUN=<run>]  Verify DC-generated ChipTop.sdf for GLS.' \
	  'make sdf_power BINARY=<elf> [TECH=smic180|tsmc28] [NETLIST_RUN=<run>]  Run SDF GLS with FSDB, then report power.' \
	  'make power [TECH=smic180|tsmc28] [NETLIST_RUN=<run>]  Report averaged power directly from the SDF FSDB.' \
	  'TECH defaults to smic180 for the latest netlist; STD_CELL_DB, SRAM_ROOT, SRAM_CORNER, SRAM_DB_TEMPLATE, ROM_ROOT, ROM_CORNER, and ROM_DB_TEMPLATE remain overridable.' \
	  'sdf_power requires TAPE_ENV and RISCV from the Chipyard Nix shell. It emits only run-sdf.fsdb as waveform output.' \
	  'Generate SDF with: (cd ../2-SYN && ./run_core --run-id <run> ...). Override NETLIST, SDC, SDF_OUT, FSDB, TOP, CONFIG, PT_SHELL, POWER_START_NS, or POWER_END_NS as needed.'

check-config:
	@test -n '$(STD_CELL_DB)' || { echo 'STD_CELL_DB is unset; provide the standard-cell power .db path'; exit 2; }
	@test -n '$(SRAM_ROOT)' || { echo 'SRAM_ROOT is unset; provide the SRAM library root path'; exit 2; }
	@if [ -n '$(ROM_ROOT)' ]; then \
		for rom_name in S018VM_X64Y16D64_PM S018VM_X8Y16D64_PM; do \
			rom_db=$$(printf '$(ROM_ROOT)/$(ROM_DB_TEMPLATE)' "$$rom_name" '$(ROM_CORNER)'); \
			test -s "$$rom_db" || { echo "Missing ROM power .db: $$rom_db"; exit 2; }; \
		done; \
	fi

sdf: $(SDF_OUT)
	@test -s $(SDF_OUT) || { echo 'Missing DC-generated SDF: $(SDF_OUT)' >&2; exit 2; }

power: check-config $(FSDB) scripts/pt_chiptop_power.tcl scripts/chiptop_common.tcl
	@mkdir -p $(POWER_OUT_DIR)
	@TOP='$(TOP)' \
	 NETLIST='$(abspath $(NETLIST))' \
	 SDC='$(abspath $(SDC))' \
	 FSDB='$(abspath $(FSDB))' \
	 ACTIVITY_STRIP_PATH='$(ACTIVITY_STRIP_PATH)' \
	 POWER_START_NS='$(POWER_START_NS)' \
	 POWER_END_NS='$(POWER_END_NS)' \
	 POWER_OUT_DIR='$(abspath $(POWER_OUT_DIR))' \
	 STDCELL_DB='$(abspath $(STD_CELL_DB))' \
	 IO_DB='$(abspath $(IO_DB))' \
	 SRAM_ROOT='$(abspath $(SRAM_ROOT))' \
	 SRAM_CORNER='$(SRAM_CORNER)' \
	 SRAM_DB_TEMPLATE='$(SRAM_DB_TEMPLATE)' \
	 ROM_ROOT='$(ROM_ROOT)' \
	 ROM_CORNER='$(ROM_CORNER)' \
	 ROM_DB_TEMPLATE='$(ROM_DB_TEMPLATE)' \
	 TECH='$(TECH)' \
	 TECH_CORNER='$(TECH_CORNER)' \
	 $(PT_SHELL) -file scripts/pt_chiptop_power.tcl -output_log_file $(POWER_OUT_DIR)/power.log
	@grep -q 'Wrote power reports to' $(POWER_OUT_DIR)/power.log

sdf_power: check-config
	@test -n '$(BINARY)' || { echo 'Set BINARY=<ELF>'; exit 2; }
	$(MAKE) sdf
	$(MAKE) -C ../3-Pre_PR_NETSIM gls_sdf \
		TECH='$(TECH)' NETLIST_RUN='$(NETLIST_RUN)' TOP='$(TOP)' CONFIG='$(CONFIG)' \
		SDF='$(SDF_OUT)' WAVEFORM=1
	$(MAKE) -C ../3-Pre_PR_NETSIM run_sdf \
		TECH='$(TECH)' NETLIST_RUN='$(NETLIST_RUN)' TOP='$(TOP)' CONFIG='$(CONFIG)' \
		SDF='$(SDF_OUT)' WAVEFORM=1 BINARY='$(BINARY)'
	$(MAKE) power FSDB='$(FSDB)' POWER_OUT_DIR='$(POWER_OUT_DIR)'
