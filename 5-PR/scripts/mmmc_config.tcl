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
  create_rc_corner -name $rc_corner -qx_tech_file [dict get $::QRC_TECH_FILES $rc_corner]
}

##############################################################################
## DELAY CORNERS
##############################################################################
create_delay_corner -name dc_setup -library_set lib_ss -rc_corner rc_worst
create_delay_corner -name dc_hold  -library_set lib_ff -rc_corner rc_best

##############################################################################
## CONSTRAINT MODES
##############################################################################
create_constraint_mode -name func -sdc_files [list $::SDC]

##############################################################################
## ANALYSIS VIEWS
##############################################################################
create_analysis_view -name view_setup -constraint_mode func -delay_corner dc_setup
create_analysis_view -name view_hold -constraint_mode func -delay_corner dc_hold

##############################################################################
## ACTIVE VIEWS
##############################################################################
set_analysis_view -setup {view_setup} -hold {view_hold}

foreach {view lib voltage temperature rc_corner} {
  view_setup lib_ss 0.81V 125C rc_worst
  view_hold  lib_ff 1.05V -40C rc_best
} {
  lassign [dict get $::RC_CORNER_SCALES $rc_corner] r_scale c_scale xcap_scale
  puts "PR_MMMC_VIEW view=$view library=$lib voltage=$voltage temperature=$temperature rc_corner=$rc_corner qrc=[dict get $::QRC_TECH_FILES $rc_corner] R=$r_scale C=$c_scale XCap=$xcap_scale"
}
