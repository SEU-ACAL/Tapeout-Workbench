SHELL := /bin/bash

NETLIST_RUN ?= 0720_1845
TOP ?= ChipTop
NETLIST ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/$(TOP).v
SDC ?= $(CURDIR)/../2-SYN/outputs/$(NETLIST_RUN)/$(TOP).sdc
SDF_OUT ?= $(CURDIR)/../3-Pre_PR_NETSIM/inputs/$(NETLIST_RUN)/$(TOP).sdf
FSDB ?= $(CURDIR)/../3-Pre_PR_NETSIM/gen/chipyard.harness.TestHarness.TapeoutConfig/$(NETLIST_RUN)/run-zero.fsdb
SAIF ?= $(CURDIR)/outputs/$(NETLIST_RUN)/zero-fsdb/run-zero.saif
POWER_OUT_DIR ?= $(CURDIR)/outputs/$(NETLIST_RUN)/zero-fsdb
ACTIVITY_STRIP_PATH ?= TestDriver/testHarness/chiptop0
POWER_START_NS ?= 1000
STD_CELL_DB ?=
SRAM_ROOT ?=
SRAM_CORNER ?= ssg0p81v125c
PT_SHELL ?= pt_shell
FSDB2SAIF ?=

.PHONY: help check-config check-power sdf saif power clean-sdf

help:
	@printf '%s\n' \
	  'make sdf [NETLIST_RUN=<run>]  Export ChipTop MAXIMUM SDF for GLS.' \
	  'make power [NETLIST_RUN=<run>] Convert zero-delay FSDB to SAIF and report averaged power.' \
	  'Set STD_CELL_DB, SRAM_ROOT, and FSDB2SAIF (W-2024) in the environment.' \
	  'Override NETLIST, SDC, SDF_OUT, FSDB, SAIF, TOP, PT_SHELL, or FSDB2SAIF as needed.'

check-config:
	@test -n '$(STD_CELL_DB)' || { echo 'STD_CELL_DB is unset; provide the standard-cell power .db path'; exit 2; }
	@test -n '$(SRAM_ROOT)' || { echo 'SRAM_ROOT is unset; provide the SRAM library root path'; exit 2; }

check-power: check-config
	@test -n '$(FSDB2SAIF)' || { echo 'FSDB2SAIF is unset; provide a Verdi W-2024 fsdb2saif executable'; exit 2; }

sdf: check-config $(NETLIST) $(SDC) scripts/pt_chiptop_sdf.tcl scripts/chiptop_common.tcl
	@mkdir -p $(dir $(SDF_OUT))
	@NETLIST='$(abspath $(NETLIST))' \
	 SDC='$(abspath $(SDC))' \
	 SDF_OUT='$(abspath $(SDF_OUT))' \
	 STDCELL_DB='$(abspath $(STD_CELL_DB))' \
	 SRAM_ROOT='$(abspath $(SRAM_ROOT))' \
	 SRAM_CORNER='$(SRAM_CORNER)' \
	 TOP='$(TOP)' \
	 $(PT_SHELL) -f scripts/pt_chiptop_sdf.tcl | tee $(dir $(SDF_OUT))/pt-sdf.log
	@grep -q 'Wrote SDF:' $(dir $(SDF_OUT))/pt-sdf.log

saif: check-power $(SAIF)

$(SAIF): $(FSDB)
	@mkdir -p $(dir $@)
	$(FSDB2SAIF) $(FSDB) -s /$(ACTIVITY_STRIP_PATH) -bt $(POWER_START_NS)ns -o $@

power: check-power $(SAIF) scripts/pt_chiptop_power.tcl scripts/chiptop_common.tcl
	@mkdir -p $(POWER_OUT_DIR)
	@TOP='$(TOP)' \
	 NETLIST='$(abspath $(NETLIST))' \
	 SDC='$(abspath $(SDC))' \
	 ACTIVITY_FORMAT=saif \
	 ACTIVITY_FILE='$(abspath $(SAIF))' \
	 ACTIVITY_STRIP_PATH='$(ACTIVITY_STRIP_PATH)' \
	 POWER_OUT_DIR='$(abspath $(POWER_OUT_DIR))' \
	 STDCELL_DB='$(abspath $(STD_CELL_DB))' \
	 SRAM_ROOT='$(abspath $(SRAM_ROOT))' \
	 SRAM_CORNER='$(SRAM_CORNER)' \
	 $(PT_SHELL) -file scripts/pt_chiptop_power.tcl -output_log_file $(POWER_OUT_DIR)/power.log
	@grep -q 'Wrote power reports to' $(POWER_OUT_DIR)/power.log

clean-sdf:
	rm -f $(SDF_OUT) $(dir $(SDF_OUT))/pt-sdf.log
