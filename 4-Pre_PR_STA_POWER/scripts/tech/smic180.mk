CORNER ?= ss
ifeq ($(CORNER),ss)
TECH_CORNER ?= ss_v1p62_125c
TECH_STD_CELL_DB ?= /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c_ccs.db
TECH_IO_DB ?= /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_max.db
TECH_SRAM_CORNER ?= ss_1.62_125
TECH_ROM_CORNER ?= ss_1.62_125
else ifeq ($(CORNER),tt)
TECH_CORNER ?= tt_v1p8_25c
TECH_STD_CELL_DB ?= /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_tt_v1p8_25c_ccs.db
TECH_IO_DB ?= /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_typ.db
TECH_SRAM_CORNER ?= tt_1.8_25
TECH_ROM_CORNER ?= tt_1.8_25
else ifeq ($(CORNER),ff)
TECH_CORNER ?= ff_v1p98_-40c
TECH_STD_CELL_DB ?= /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ff_v1p98_-40c_ccs.db
TECH_IO_DB ?= /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_min.db
TECH_SRAM_CORNER ?= ff_1.98_-40
TECH_ROM_CORNER ?= ff_1.98_-40
else
$(error Unsupported CORNER '$(CORNER)'; expected ss, tt, or ff)
endif
TECH_SRAM_ROOT ?= /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
TECH_SRAM_NAMES ?= chipyard_sram_32x22 chipyard_sram_32x128 chipyard_sram_1024x8 chipyard_sram_512x64 chipyard_sram_512x8 chipyard_sram_64x128 chipyard_sram_64x22 chipyard_sram_64x21 chipyard_sram_512x32
TECH_SRAM_DB_TEMPLATE ?= %s_%s.db
TECH_ROM_ROOT ?= /data2/smic180/rom-ip
TECH_ROM_DB_TEMPLATE ?= %s_%s.db
