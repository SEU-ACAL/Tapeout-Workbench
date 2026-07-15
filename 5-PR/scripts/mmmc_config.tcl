# Flowkit v23.10-a001_1
##############################################################################
## LIBRARY SETS
##############################################################################
create_library_set -name lib_ss -timing [list $::LIB_SS]
create_library_set -name lib_ff -timing [list $::LIB_FF]

##############################################################################
## OPERATING CONDITIONS
##############################################################################
create_rc_corner -name rc_qrc -qx_tech_file $::QRC_TECH

##############################################################################
## DELAY CORNERS
##############################################################################
create_delay_corner -name dc_ss -library_set lib_ss -rc_corner rc_qrc
create_delay_corner -name dc_ff -library_set lib_ff -rc_corner rc_qrc

##############################################################################
## CONSTRAINT MODES
##############################################################################
create_constraint_mode -name func -sdc_files [list $::SDC]

##############################################################################
## ANALYSIS VIEWS
##############################################################################
create_analysis_view -name view_setup -constraint_mode func -delay_corner dc_ss
create_analysis_view -name view_hold -constraint_mode func -delay_corner dc_ff

##############################################################################
## ACTIVE VIEWS
##############################################################################
set_analysis_view -setup {view_setup} -hold {view_hold}
