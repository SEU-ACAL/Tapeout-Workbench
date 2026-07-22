# Flowkit v23.10-a001_1
##############################################################################
## LIBRARY SETS
##############################################################################
create_library_set -name lib_ss -timing [list $::LIB_SS]
create_library_set -name lib_ff -timing [list $::LIB_FF]

##############################################################################
## OPERATING CONDITIONS
##############################################################################
foreach rc_corner {rc_worst rc_best c_worst c_best rc_typical} {
  if {![dict exists $::RC_CORNER_TEMPERATURES $rc_corner]} {
    error "RC corner '$rc_corner' has no QRC temperature"
  }
  create_rc_corner -name $rc_corner \
    -T [dict get $::RC_CORNER_TEMPERATURES $rc_corner] \
    -qx_tech_file [dict get $::QRC_TECH_FILES $rc_corner]
}

##############################################################################
## CONSTRAINT MODES
##############################################################################
create_constraint_mode -name func -sdc_files [list $::SDC]

##############################################################################
## DELAY CORNERS AND ANALYSIS VIEWS
##############################################################################
set pr_setup_views {}
set pr_hold_views {}
foreach spec $::PR_MMMC_VIEW_SPECS {
  lassign $spec view library_set rc_corner check_type
  if {$check_type ni {setup hold}} {
    error "Invalid MMMC check type '$check_type' for view '$view'"
  }
  if {![dict exists $::QRC_TECH_FILES $rc_corner]} {
    error "MMMC view '$view' references an undefined RC corner '$rc_corner'"
  }
  if {![dict exists $::PR_LIBRARY_PVT $library_set]} {
    error "MMMC view '$view' references an undefined library PVT '$library_set'"
  }

  set delay_corner dc_$view
  create_delay_corner -name $delay_corner -library_set $library_set -rc_corner $rc_corner
  create_analysis_view -name $view -constraint_mode func -delay_corner $delay_corner
  if {$check_type eq "setup"} {
    lappend pr_setup_views $view
  } else {
    lappend pr_hold_views $view
  }
}

if {[llength $pr_setup_views] == 0 || [llength $pr_hold_views] == 0} {
  error "MMMC configuration must define at least one setup and one hold view"
}

##############################################################################
## ACTIVE VIEWS
##############################################################################
set_analysis_view -setup $pr_setup_views -hold $pr_hold_views

foreach spec $::PR_MMMC_VIEW_SPECS {
  lassign $spec view lib rc_corner check_type
  lassign [dict get $::PR_LIBRARY_PVT $lib] voltage temperature
  lassign [dict get $::RC_CORNER_SCALES $rc_corner] r_scale c_scale xcap_scale
  set rc_temperature [dict get $::RC_CORNER_TEMPERATURES $rc_corner]
  puts "PR_MMMC_VIEW view=$view check=$check_type library=$lib voltage=$voltage temperature=$temperature rc_corner=$rc_corner rc_temperature=${rc_temperature}C qrc=[dict get $::QRC_TECH_FILES $rc_corner] R=$r_scale C=$c_scale XCap=$xcap_scale"
}
