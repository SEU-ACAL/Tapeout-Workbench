# Project inputs and technology settings.

set ::PR_ROOT [file normalize [file join [file dirname [info script]] ..]]
set ::TOP_MODULE multiplier_pipe3
set ::NETLIST [file join $::PR_ROOT .. 2-SYN outputs 0715_0544 multiplier_pipe3.v]
set ::SDC [file join $::PR_ROOT scripts constraint_pr.sdc]

set ::CELL_LEF /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140lvt_110a/lef/tcbn28hpcplusbwp7t40p140lvt.lef
set ::SITE_LEF [file join $::PR_ROOT scripts core7T.lef]
set ::LIB_ROOT /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a
set ::LIB_SS [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.lib]
set ::LIB_FF [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtffg1p05vm40c_ccs.lib]
set ::TECH_LEF /data2/TSMC28/TF/N28_PRTF_Cad_v1d5a/PR_tech/Cadence/LefHeader/HVH/tsmcn28_10lm5X2Y2RUTRDL.tlef
set ::QRC_TECH /data2/TSMC28/TF/qrcTechFile

set ::FLOORPLAN_DEF ""
set ::CORE_SITE core7T
set ::CORE_ASPECT_RATIO 1.0
set ::CORE_UTILIZATION 0.70
set ::CORE_MARGIN 10.0

set ::CTS_TARGET_SKEW 0.10
set ::CTS_TARGET_SLEW 0.10
set ::PG_RING_HORIZONTAL M9
set ::PG_RING_VERTICAL M8

foreach file [list $::NETLIST $::SDC $::TECH_LEF $::SITE_LEF $::CELL_LEF $::LIB_SS $::LIB_FF $::QRC_TECH] {
  if {![file exists $file]} {
    error "Required PR input is missing: $file"
  }
}
