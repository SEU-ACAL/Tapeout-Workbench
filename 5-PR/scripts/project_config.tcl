# Project inputs and technology settings.

set ::PR_ROOT [file normalize [file join [file dirname [info script]] ..]]
set ::TOP_MODULE multiplier_pipe3
set ::NETLIST [file join $::PR_ROOT .. 2-SYN outputs 0715_0544 multiplier_pipe3.v]
set ::SDC [file join $::PR_ROOT scripts constraint_pr.sdc]
# This is the current synthesis handoff.  Confirm the interface timing budget
# before changing the default directory or the PR-only uncertainty below.
set ::PR_SDC_UPSTREAM_DIR [file join $::PR_ROOT .. 2-SYN outputs 0715_0544]
set ::PR_CLOCK_PORT clock

set ::CELL_LEF /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140lvt_110a/lef/tcbn28hpcplusbwp7t40p140lvt.lef
set ::SITE_LEF [file join $::PR_ROOT scripts core7T.lef]
set ::LIB_ROOT /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a
set ::LIB_SS [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.lib]
set ::LIB_FF [file join $::LIB_ROOT tcbn28hpcplusbwp7t40p140lvtffg1p05vm40c_ccs.lib]
set ::TECH_LEF /data2/TSMC28/TF/N28_PRTF_Cad_v1d5a/PR_tech/Cadence/LefHeader/HVH/tsmcn28_10lm5X2Y2RUTRDL.tlef

# Do not use $QRC_ROOT/qrcTechFile: it is the Cbest file.  The non-_T files
# below are the characterized default QRC corners.  The _T variants remain
# available in the PDK but are intentionally not selected without PDK guidance.
set ::QRC_ROOT /data2/TSMC28/TF
set ::QRC_TECH_FILES [dict create \
  rc_worst   [file join $::QRC_ROOT 1p10m_rcworst qrcTechFile] \
  rc_best    [file join $::QRC_ROOT 1p10m_rcbest qrcTechFile] \
  c_worst    [file join $::QRC_ROOT 1p10m_cworst qrcTechFile] \
  c_best     [file join $::QRC_ROOT 1p10m_cbest qrcTechFile] \
  rc_typical [file join $::QRC_ROOT 1p10m_typical qrcTechFile]]

# QRC supplies the physical R/C model.  These unity factors document that no
# additional unqualified derate is being layered onto that model.
set ::RC_CORNER_SCALES [dict create \
  rc_worst   {1.0 1.0 1.0} \
  rc_best    {1.0 1.0 1.0} \
  c_worst    {1.0 1.0 1.0} \
  c_best     {1.0 1.0 1.0} \
  rc_typical {1.0 1.0 1.0}]

set ::FLOORPLAN_DEF ""
set ::CORE_SITE core7T
set ::CORE_ASPECT_RATIO 1.0
set ::CORE_UTILIZATION 0.70
set ::CORE_MARGIN 10.0

set ::CTS_TARGET_SKEW 0.10
set ::CTS_TARGET_SLEW 0.10
set ::PG_RING_HORIZONTAL M9
set ::PG_RING_VERTICAL M8
set ::PR_FINAL_REPORT_DIR [file join $::PR_ROOT reports final]
# Populate this dictionary only with approved signoff waivers, for example:
# dict set ::PR_SIGNOFF_WAIVERS drc "waiver-id: reason"
set ::PR_SIGNOFF_WAIVERS [dict create]

foreach file [concat [list $::NETLIST $::SDC $::TECH_LEF $::SITE_LEF $::CELL_LEF $::LIB_SS $::LIB_FF] [dict values $::QRC_TECH_FILES]] {
  if {![file exists $file]} {
    error "Required PR input is missing: $file"
  }
}

set ::PR_UPSTREAM_SDC [file join $::PR_SDC_UPSTREAM_DIR ${::TOP_MODULE}.sdc]
if {![file exists $::PR_UPSTREAM_SDC]} {
  error "Required upstream SDC is missing: $::PR_UPSTREAM_SDC"
}
