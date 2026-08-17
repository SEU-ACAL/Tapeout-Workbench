# Existing TSMC28 multiplier configuration.  Keep this as the default.
set ::PR_PROCESS_NM 28
set ::TOP_MODULE multiplier_pipe3
set ::NETLIST [file join $::PR_WORKBENCH_ROOT 2-SYN outputs 0715_0544 multiplier_pipe3.v]
set ::SDC [file join $::PR_ROOT scripts constraint_pr.sdc]
set ::PR_SDC_UPSTREAM_DIR [file join $::PR_WORKBENCH_ROOT 2-SYN outputs 0715_0544]
set ::PR_UPSTREAM_SDC [file join $::PR_SDC_UPSTREAM_DIR ${::TOP_MODULE}.sdc]
set ::PR_CLOCK_PORT clock

set ::CELL_LEF /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140lvt_110a/lef/tcbn28hpcplusbwp7t40p140lvt.lef
set ::SITE_LEF [file join $::PR_ROOT scripts core7T.lef]
set ::TECH_LEF /data2/TSMC28/TF/N28_PRTF_Cad_v1d5a/PR_tech/Cadence/LefHeader/HVH/tsmcn28_10lm5X2Y2ZUTRDL.tlef
set ::PR_LEF_FILES [list $::TECH_LEF $::SITE_LEF $::CELL_LEF]
set ::PR_GDS_MAP_GENERATOR /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140lvt_110a/techfiles/gds2map.sh
set ::PR_GDS_MAP_GENERATOR_ARGS {-layer 10 -top 2 -type Z -metalY 2}
set ::PR_GDS_MAP_FILE ""
set ::PR_STDCELL_GDS /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/gds/tcbn28hpcplusbwp7t40p140lvt_110a/tcbn28hpcplusbwp7t40p140lvt.gds
set ::PR_GDS_MERGE_FILES [list $::PR_STDCELL_GDS]

set ::LIB_ROOT /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a
set ::LIB_SS [list [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.lib]]
set ::LIB_FF [list [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtffg1p05vm40c_ccs.lib]]
set ::QRC_ROOT /data2/TSMC28/TF
set ::QRC_TECH_FILES [dict create \
  rc_worst [file join $::QRC_ROOT 1p10m_5x2y2z_rcworst qrcTechFile] \
  rc_best [file join $::QRC_ROOT 1p10m_5x2y2z_rcbest qrcTechFile] \
  c_worst [file join $::QRC_ROOT 1p10m_5x2y2z_cworst qrcTechFile] \
  c_best [file join $::QRC_ROOT 1p10m_5x2y2z_cbest qrcTechFile] \
  rc_typical [file join $::QRC_ROOT 1p10m_5x2y2z_typical qrcTechFile]]
set ::RC_CORNER_SCALES [dict create rc_worst {1.0 1.0 1.0} rc_best {1.0 1.0 1.0} c_worst {1.0 1.0 1.0} c_best {1.0 1.0 1.0} rc_typical {1.0 1.0 1.0}]
set ::RC_CORNER_TEMPERATURES [dict create rc_worst 125 rc_best -40 c_worst 125 c_best -40 rc_typical 25]
set ::PR_MMMC_VIEW_SPECS [list \
  [list view_setup lib_ss rc_worst setup] [list view_setup_cworst lib_ss c_worst setup] \
  [list view_hold lib_ff rc_best hold] [list view_hold_cbest lib_ff c_best hold]]
set ::PR_LIBRARY_PVT [dict create lib_ss {0.81V 125C} lib_ff {1.05V -40C}]
set ::PR_SPEF_RC_CORNERS {rc_worst rc_best}

set ::FLOORPLAN_DEF ""
set ::PR_IO_PLACEMENT_MODE edit_pin
set ::PR_IO_PLACEMENT_CHECK_MODE core_ports
set ::CORE_SITE core7T
set ::CORE_ASPECT_RATIO 1.0
set ::CORE_UTILIZATION 0.70
set ::CORE_MARGIN 10.0
set ::IO_PIN_INPUT_SIDE left
set ::IO_PIN_OUTPUT_SIDE right
set ::IO_PIN_INPUT_LAYER M3
set ::IO_PIN_OUTPUT_LAYER M3
set ::CTS_TARGET_SKEW 0.10
set ::CTS_TARGET_SLEW 0.10
set ::PR_CTS_BUFFER_CELLS {CKBD1BWP7T40P140LVT CKBD2BWP7T40P140LVT CKBD4BWP7T40P140LVT CKBD8BWP7T40P140LVT CKBD16BWP7T40P140LVT CKBD20BWP7T40P140LVT}
set ::PR_CTS_INVERTER_CELLS {INVD1BWP7T40P140LVT INVD2BWP7T40P140LVT INVD4BWP7T40P140LVT INVD8BWP7T40P140LVT}
set ::PR_TIE_CELLS {TIEHBWP7T40P140LVT TIELBWP7T40P140LVT}
set ::PR_FILLER_CELLS {FILL64BWP7T40P140LVT FILL32BWP7T40P140LVT FILL16BWP7T40P140LVT FILL8BWP7T40P140LVT FILL4BWP7T40P140LVT FILL3BWP7T40P140LVT FILL2BWP7T40P140LVT}
set ::PR_WELL_TAP_CELL TAPCELLBWP7T40P140
set ::PR_WELL_TAP_INTERVAL 30
set ::PR_POWER_PIN_MAP {{VDD VDD} {VSS VSS}}
set ::PR_SIGNAL_PAD_CELLS {}
set ::PR_POWER_PAD_CELLS {}
set ::PR_PG_RING_HORIZONTAL M9
set ::PR_PG_RING_VERTICAL M8
set ::PR_PG_RING_WIDTH 2
set ::PR_PG_RING_SPACING 1
set ::PR_PG_RING_OFFSET 1
set ::PR_PG_STRIPE_WIDTH 1
set ::PR_PG_STRIPE_SPACING 1
set ::PR_PG_STRIPE_PITCH 40
