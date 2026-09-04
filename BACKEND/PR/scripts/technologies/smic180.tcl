# SMIC180 ChipTop implementation configuration, using the 6-metal SP018RP IO kit.
set ::PR_PROCESS_NM 180
set ::TOP_MODULE ChipTop
set ::PR_SYNTH_RUN 0816_0804
set ::PR_LOCAL_CPU 8
set ::NETLIST [file join $::PR_WORKBENCH_ROOT 2-SYN outputs $::PR_SYNTH_RUN ChipTop.v]
set ::SDC [file join $::PR_ROOT scripts technologies smic180_impl.sdc]
set ::PR_SDC_UPSTREAM_DIR [file join $::PR_WORKBENCH_ROOT 2-SYN outputs $::PR_SYNTH_RUN]
set ::PR_UPSTREAM_SDC [file join $::PR_SDC_UPSTREAM_DIR ${::TOP_MODULE}.sdc]
set ::PR_CLOCK_PORT clock

set ::TECH_LEF /data2/smic180/SCC018UG_UHD_RVT_V0p4a/lef/tf/180MS_1850/scc018u_6m_1tm1.lef
set ::CELL_LEF /data2/smic180/SCC018UG_UHD_RVT_V0p4a/lef/macro/scc018ug_uhd_rvt.lef
set ::IO_LEF /data2/smic180/SP018RP_V1p0b/lef/SP018RP_V1p0_6MT.lef
set ::SRAM_ROOT /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
set ::PR_SRAM_NAMES {chipyard_sram_32x22 chipyard_sram_32x128 chipyard_sram_1024x8 chipyard_sram_512x64 chipyard_sram_512x8 chipyard_sram_64x128 chipyard_sram_64x22 chipyard_sram_64x21 chipyard_sram_512x32}
set ::PR_SRAM_LEFS {}
set ::PR_SRAM_GDS_FILES {}
set ::PR_SRAM_LIB_SS {}
set ::PR_SRAM_LIB_FF {}
foreach sram $::PR_SRAM_NAMES {
  lappend ::PR_SRAM_LEFS [file join $::SRAM_ROOT $sram ${sram}.lef]
  lappend ::PR_SRAM_GDS_FILES [file join $::SRAM_ROOT $sram ${sram}.gds]
  lappend ::PR_SRAM_LIB_SS [file join $::SRAM_ROOT $sram ${sram}_ss_1.62_125.lib]
  lappend ::PR_SRAM_LIB_FF [file join $::SRAM_ROOT $sram ${sram}_ff_1.98_-40.lib]
}
set ::PR_LEF_FILES [concat [list $::TECH_LEF $::CELL_LEF $::IO_LEF] $::PR_SRAM_LEFS]

set ::SMIC180_LIB_ROOT /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v
set ::LIB_SS [concat [list [file join $::SMIC180_LIB_ROOT scc018ug_uhd_rvt_ss_v1p62_125c_ccs.lib] /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_max.lib] $::PR_SRAM_LIB_SS]
set ::LIB_FF [concat [list [file join $::SMIC180_LIB_ROOT scc018ug_uhd_rvt_ff_v1p98_-40c_ccs.lib] /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_min.lib] $::PR_SRAM_LIB_FF]
set ::QRC_TECH_FILES [dict create \
  rc_setup /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/voltagestorm/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c/techonly.cl/qrcTechFile_RCgen \
  rc_hold /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/voltagestorm/1.8v/scc018ug_uhd_rvt_ff_v1p98_-40c/techonly.cl/qrcTechFile_RCgen]
set ::RC_CORNER_SCALES [dict create rc_setup {1.0 1.0 1.0} rc_hold {1.0 1.0 1.0}]
set ::RC_CORNER_TEMPERATURES [dict create rc_setup 125 rc_hold -40]
set ::PR_MMMC_VIEW_SPECS [list [list view_setup lib_ss rc_setup setup] [list view_hold lib_ff rc_hold hold]]
set ::PR_LIBRARY_PVT [dict create lib_ss {1.62V 125C} lib_ff {1.98V -40C}]
set ::PR_SPEF_RC_CORNERS {rc_setup rc_hold}

set ::PR_GDS_MAP_GENERATOR ""
set ::PR_GDS_MAP_GENERATOR_ARGS {}
set ::PR_GDS_MAP_FILE /data2/smic180/SCC018UG_UHD_RVT_V0p4a/lef/tf/180MS_1850/encStreamout018.map
set ::PR_STDCELL_GDS /data2/smic180/SCC018UG_UHD_RVT_V0p4a/gds/scc018ug_uhd_rvt.gds
set ::PR_IO_GDS /data2/smic180/SP018RP_V1p0b/gds/SP018RP_V1p0_6MT.gds
set ::PR_GDS_MERGE_FILES [concat [list $::PR_STDCELL_GDS $::PR_IO_GDS] $::PR_SRAM_GDS_FILES]

# ChipTop already contains physical SP018RP signal pads.  A qualified pad-ring
# DEF or pad placement script is mandatory; generic core editPin is invalid.
set ::FLOORPLAN_DEF ""
set ::PR_IO_FILE [file join $::PR_ROOT scripts technologies smic180.io]
set ::PR_IO_PLACEMENT_MODE pad_ring_iofile
set ::PR_IO_PLACEMENT_CHECK_MODE pad_cells
set ::PR_PAD_RING_SCRIPT [file join $::PR_ROOT scripts technologies smic180_pad_ring.tcl]
set ::PR_SIGNAL_PAD_CELLS {PB8R POT8R PIR}
set ::PR_POWER_PAD_CELLS {PVDD1R PVSS1R}
set ::PR_CORNER_CELL PCORNERR
set ::PR_CORNER_INSTANCES {PR_CORNER_SW PR_CORNER_SE PR_CORNER_NE PR_CORNER_NW}
set ::CORE_SITE uhd_CoreSite
set ::CORE_ASPECT_RATIO 1.0
set ::CORE_UTILIZATION 0.65
set ::CORE_MARGIN 50.0
set ::CTS_TARGET_SKEW 1.0
set ::CTS_TARGET_SLEW 1.0
# Keep physical CTS branching aligned with the design-wide data-path DRV
# target inherited from synthesis SDC. CCOpt otherwise defaults to 100.
set ::CTS_MAX_FANOUT 32
set ::PR_CTS_BUFFER_CELLS {CLKBUFUHDV1 CLKBUFUHDV2 CLKBUFUHDV3 CLKBUFUHDV4 CLKBUFUHDV6 CLKBUFUHDV8 CLKBUFUHDV16 CLKBUFUHDV20 CLKBUFUHDV24}
set ::PR_CTS_INVERTER_CELLS {CLKINUHDV1 CLKINUHDV2 CLKINUHDV3 CLKINUHDV4 CLKINUHDV6 CLKINUHDV8 CLKINUHDV16 CLKINUHDV20 CLKINUHDV24}
set ::PR_TIE_CELLS {}
set ::PR_FILLER_CELLS {F_FILLUHD32 F_FILLUHD16 F_FILLUHD8 F_FILLUHD4 F_FILLUHD2 F_FILLUHD1}
set ::PR_WELL_TAP_CELL ""
set ::PR_WELL_TAP_INTERVAL 0
set ::PR_POWER_PIN_MAP {{VDD VDD} {VDD VNW} {VSS VSS} {VSS VPW}}
set ::PR_PG_RING_HORIZONTAL METAL6
set ::PR_PG_RING_VERTICAL METAL5
set ::PR_PG_RING_WIDTH 10
set ::PR_PG_RING_SPACING 5
set ::PR_PG_RING_OFFSET 5
set ::PR_PG_STRIPE_WIDTH 5
set ::PR_PG_STRIPE_SPACING 5
set ::PR_PG_STRIPE_PITCH 100
