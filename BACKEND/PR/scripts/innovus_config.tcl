# Flowkit v23.10-a001_1
################################################################################
# Tool attributes (design & library not required)
#
#  Attributes used to drive tool behavior.  Most typically these are set*Mode
#    set_global, or setVar commands
#
#  Further help can be obtained by using the command 'help <COMMAND>'
#
################################################################################
if {[get_flowkit_db flow_step_current] ne ""} {
  puts "INFO: (FLOW-102) : Loading [file tail [info script]] with [get_flowkit_db flow_step_current]"
} else {
  puts "INFO: (FLOW-102) : Loading [file tail [info script]]"
}
################################################################################
# ATTRIBUTES APPLIED BEFORE LOADING A LIBRARY OR DATABASE
################################################################################

# General settings  [get_attribute -category init]
#-------------------------------------------------------------------------------
if {[info exists ::env(LSB_MAX_NUM_PROCESSORS)]} {
  setMultiCpuUsage -localCpu $::env(LSB_MAX_NUM_PROCESSORS)
} elseif {[info exists ::PR_LOCAL_CPU]} {
  setMultiCpuUsage -localCpu $::PR_LOCAL_CPU
}
################################################################################
# ATTRIBUTES APPLIED AFTER LOADING A LIBRARY OR DATABASE
################################################################################
if {[get_designs -quiet *] eq ""} {return}

# Design settings  [setDesignMode -help]
#-------------------------------------------------------------------------------
setDesignMode -process $::PR_PROCESS_NM

# Timing settings  [setAnalysisMode -help]
#-------------------------------------------------------------------------------
setAnalysisMode -cppr             both
setAnalysisMode -analysisType     onChipVariation

# Extraction & Delay settings  [setDelayCalMode -help]
#-------------------------------------------------------------------------------
if [is_flow -after flow:route] {
  setExtractRCMode -engine        postRoute
  setDelayCalMode -SIAware        true
}

# Placement settings  [setPlaceMode -help]
#-------------------------------------------------------------------------------

# Tieoff settings  [setTieHieLoMode -help]
#-------------------------------------------------------------------------------
if {[llength $::PR_TIE_CELLS] != 0} {
  setTieHiLoMode -cell $::PR_TIE_CELLS
}

# Optimization settings  [setOptMode -help]
#-------------------------------------------------------------------------------
setOptMode -addInstancePrefix                           "[get_flowkit_db flow_report_name]_"

# Clock settings  [set_ccopt_mode -help]
#-------------------------------------------------------------------------------
set_ccopt_mode -cts_target_skew    $::CTS_TARGET_SKEW
set_ccopt_mode -cts_target_slew    $::CTS_TARGET_SLEW
if {[info exists ::CTS_MAX_FANOUT]} {
  set_ccopt_property max_fanout $::CTS_MAX_FANOUT
}
set_ccopt_mode -cts_buffer_cells   $::PR_CTS_BUFFER_CELLS
set_ccopt_mode -cts_inverter_cells $::PR_CTS_INVERTER_CELLS

# Filler settings  [setFillerMode -help]
#-------------------------------------------------------------------------------
if {[llength $::PR_FILLER_CELLS] != 0} {
  setFillerMode -core $::PR_FILLER_CELLS
}

# Routing settings  [setNanoRouteMode -help]
#-------------------------------------------------------------------------------
