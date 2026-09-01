# SMIC180 ChipTop P&R handoff configuration.
#
# This file is intentionally separate from BACKEND/PR, which remains the
# TSMC28 multiplier flow. It captures all known physical inputs and leaves
# tapeout-specific pad-ring and RC extraction inputs explicit.

set ::PR_ROOT [file normalize [file join [file dirname [info script]] ..]]
set ::WORKBENCH_ROOT [file normalize [file join $::PR_ROOT .. ..]]

set ::TOP_MODULE ChipTop
set ::SYNTH_RUN 0816_0804
set ::NETLIST [file join $::WORKBENCH_ROOT 2-SYN outputs $::SYNTH_RUN ChipTop.v]
set ::SDC [file join $::WORKBENCH_ROOT 2-SYN outputs $::SYNTH_RUN ChipTop.sdc]

# The SP018RP pad library selected during synthesis is the 6-metal option.
set ::TECH_LEF /data2/smic180/SCC018UG_UHD_RVT_V0p4a/lef/tf/180MS_1850/scc018u_6m_1tm1.lef
set ::STDCELL_LEF /data2/smic180/SCC018UG_UHD_RVT_V0p4a/lef/macro/scc018ug_uhd_rvt.lef
set ::IO_LEF /data2/smic180/SP018RP_V1p0b/lef/SP018RP_V1p0_6MT.lef
set ::SRAM_LEFS [list \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_32x22/chipyard_sram_32x22.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_32x128/chipyard_sram_32x128.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_1024x8/chipyard_sram_1024x8.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_512x64/chipyard_sram_512x64.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_512x8/chipyard_sram_512x8.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_64x22/chipyard_sram_64x22.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_64x21/chipyard_sram_64x21.lef \
    /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722/chipyard_sram_512x32/chipyard_sram_512x32.lef]

set ::LIB_SS /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c_ccs.lib
set ::IO_LIB_SS /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_max.lib
set ::SRAM_DB_ROOT /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
set ::SRAM_CORNER ss_1.62_125

# Native 6-metal QRC files supplied with the SMIC180 voltage-storm kit.
# Use the RC data characterized at the same PVT as the timing libraries.
set ::SMIC180_QRC_TECHFILES [dict create \
    rc_setup /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/voltagestorm/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c/techonly.cl/qrcTechFile_RCgen \
    rc_hold  /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/voltagestorm/1.8v/scc018ug_uhd_rvt_ff_v1p98_-40c/techonly.cl/qrcTechFile_RCgen]
set ::SMIC180_QRC_TEMPERATURES [dict create rc_setup 125 rc_hold -40]
set ::PAD_RING_DEF ""

# ChipTop currently contains signal pads only. A tapeout handoff must include
# an explicit supply/ground pad plan using SP018RP PVDD*/PVSS* macros.
set ::REQUIRED_POWER_PAD_PREFIXES {PVDD PVSS}
set ::CORE_SITE uhd_CoreSite
set ::CORE_UTILIZATION 0.65
set ::CORE_ASPECT_RATIO 1.0
set ::CORE_MARGIN 50.0
