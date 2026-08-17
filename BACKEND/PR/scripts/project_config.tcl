# Shared P&R configuration.  Select a technology before sourcing run_flow.tcl:
#   PR_TECHNOLOGY=smic180 innovus -no_gui -execute "source scripts/run_flow.tcl; ..."
# The default preserves the existing TSMC28 multiplier implementation flow.

set ::PR_ROOT [file normalize [file join [file dirname [info script]] ..]]
set ::PR_WORKBENCH_ROOT [file normalize [file join $::PR_ROOT .. ..]]
if {![info exists ::PR_TECHNOLOGY]} {
  if {[info exists ::env(PR_TECHNOLOGY)] && $::env(PR_TECHNOLOGY) ne ""} {
    set ::PR_TECHNOLOGY $::env(PR_TECHNOLOGY)
  } else {
    set ::PR_TECHNOLOGY tsmc28
  }
}

set pr_technology_file [file join $::PR_ROOT scripts technologies ${::PR_TECHNOLOGY}.tcl]
if {![file isfile $pr_technology_file]} {
  error "Unsupported PR_TECHNOLOGY '$::PR_TECHNOLOGY'; expected one of: tsmc28, smic180"
}
source $pr_technology_file

# A pad-aware technology can receive its approved pad-ring DEF without editing
# the technology file. The default remains empty for the TSMC core flow.
if {[info exists ::env(PR_FLOORPLAN_DEF)] && $::env(PR_FLOORPLAN_DEF) ne ""} {
  set ::FLOORPLAN_DEF [file normalize $::env(PR_FLOORPLAN_DEF)]
}

set ::PR_FINAL_REPORT_DIR [file join $::PR_ROOT reports $::PR_TECHNOLOGY final]
set ::PR_OUTPUT_DIR [file join $::PR_ROOT outputs $::PR_TECHNOLOGY]
set ::PR_SIGNOFF_WAIVERS [dict create]

foreach file [concat [list $::NETLIST $::SDC $::PR_UPSTREAM_SDC] \
    $::PR_LEF_FILES $::LIB_SS $::LIB_FF [dict values $::QRC_TECH_FILES] \
    $::PR_GDS_MERGE_FILES] {
  if {![file isfile $file]} {
    error "Required PR input is missing: $file"
  }
}
if {$::PR_GDS_MAP_GENERATOR ne "" && ![file isfile $::PR_GDS_MAP_GENERATOR]} {
  error "Required GDS map generator is missing: $::PR_GDS_MAP_GENERATOR"
}
if {$::PR_GDS_MAP_FILE ne "" && ![file isfile $::PR_GDS_MAP_FILE]} {
  error "Required GDS map file is missing: $::PR_GDS_MAP_FILE"
}
if {$::PR_GDS_MAP_GENERATOR eq "" && $::PR_GDS_MAP_FILE eq ""} {
  error "Technology $::PR_TECHNOLOGY provides neither PR_GDS_MAP_GENERATOR nor PR_GDS_MAP_FILE"
}

puts "PR_TECHNOLOGY name=$::PR_TECHNOLOGY process=${::PR_PROCESS_NM}nm top=$::TOP_MODULE"
