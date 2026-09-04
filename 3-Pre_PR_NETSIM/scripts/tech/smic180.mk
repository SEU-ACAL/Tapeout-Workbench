CORNER ?= ss
ifeq ($(filter $(CORNER),ss tt ff),)
$(error Unsupported CORNER '$(CORNER)'; expected ss, tt, or ff)
endif
TECH_STD_CELL_MODEL ?= /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/verilog/scc018ug_uhd_rvt.v
TECH_IO_CELL_MODEL ?= /data2/smic180/SP018RP_V1p0b/verilog/SP018RP_V1p1.v
TECH_SRAM_ROOT ?= /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
ifeq ($(CORNER),ss)
TECH_SRAM_CORNER ?= ss_1.62_125
else ifeq ($(CORNER),tt)
TECH_SRAM_CORNER ?= tt_1.8_25
else
TECH_SRAM_CORNER ?= ff_1.98_-40
endif
TECH_SRAM_MODEL_TEMPLATE ?= %s.v
TECH_ROM_MODEL_FILES ?= /data2/smic180/rom-ip/bootrom/S018VM_X64Y16D64_PM.v /data2/smic180/rom-ip/debugrom/S018VM_X8Y16D64_PM.v
