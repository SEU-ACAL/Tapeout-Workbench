CORNER ?= ss
ifeq ($(CORNER),ss)
TECH_CORNER ?= ssg0p81v125c
TECH_STD_CELL_DB ?= /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db
TECH_SRAM_CORNER ?= ssg0p81v125c
else ifeq ($(CORNER),tt)
TECH_CORNER ?= tt0p8v0p9v85c
TECH_STD_CELL_DB ?= /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvttt0p8v0p9v85c_ccs.db
TECH_SRAM_CORNER ?= tt0p8v0p9v85c
else ifeq ($(CORNER),ff)
TECH_CORNER ?= ffg1p05v0p99vm40c
TECH_STD_CELL_DB ?= /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtffg1p05v0p99vm40c_ccs.db
TECH_SRAM_CORNER ?= ffg1p05v0p99vm40c
else
$(error Unsupported CORNER '$(CORNER)'; expected ss, tt, or ff)
endif
TECH_SRAM_ROOT ?= /data2/TSMC28/Memory/SRAM
TECH_SRAM_NAMES ?= chipyard_sram_32x22 chipyard_sram_512x64 chipyard_sram_512x8 chipyard_sram_64x22 chipyard_sram_64x21 chipyard_sram_512x32
TECH_SRAM_DB_TEMPLATE ?= NLDM/%s_%s.db
TECH_ROM_ROOT ?=
TECH_ROM_CORNER ?=
TECH_ROM_DB_TEMPLATE ?=
