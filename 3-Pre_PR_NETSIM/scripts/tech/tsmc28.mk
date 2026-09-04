CORNER ?= ss
ifeq ($(filter $(CORNER),ss tt ff),)
$(error Unsupported CORNER '$(CORNER)'; expected ss, tt, or ff)
endif
TECH_STD_CELL_MODEL ?= /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/verilog/tcbn28hpcplusbwp7t40p140lvt_110a/tcbn28hpcplusbwp7t40p140lvt.v
TECH_SRAM_ROOT ?= /data2/TSMC28/Memory/SRAM
ifeq ($(CORNER),ss)
TECH_SRAM_CORNER ?= ssg0p81v125c
else ifeq ($(CORNER),tt)
TECH_SRAM_CORNER ?= tt0p8v0p9v85c
else
TECH_SRAM_CORNER ?= ffg1p05v0p99vm40c
endif
TECH_SRAM_MODEL_TEMPLATE ?= VERILOG/%s_%s.v
TECH_ROM_MODEL_FILES ?=
