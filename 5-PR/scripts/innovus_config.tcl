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
}
################################################################################
# ATTRIBUTES APPLIED AFTER LOADING A LIBRARY OR DATABASE
################################################################################
if {[get_designs -quiet *] eq ""} {return}

# Design settings  [setDesignMode -help]
#-------------------------------------------------------------------------------
setDesignMode -process 28

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
setTieHiLoMode -cell {TIEHBWP7T40P140LVT TIELBWP7T40P140LVT}

# Optimization settings  [setOptMode -help]
#-------------------------------------------------------------------------------
setOptMode -addInstancePrefix                           "[get_flowkit_db flow_report_name]_"

# Clock settings  [set_ccopt_mode -help]
#-------------------------------------------------------------------------------
set_ccopt_mode -cts_target_skew    $::CTS_TARGET_SKEW
set_ccopt_mode -cts_target_slew    $::CTS_TARGET_SLEW
set_ccopt_mode -cts_buffer_cells   {CKBD1BWP7T40P140LVT CKBD2BWP7T40P140LVT CKBD4BWP7T40P140LVT CKBD8BWP7T40P140LVT}
set_ccopt_mode -cts_inverter_cells {INVD1BWP7T40P140LVT INVD2BWP7T40P140LVT INVD4BWP7T40P140LVT INVD8BWP7T40P140LVT}

# Filler settings  [setFillerMode -help]
#-------------------------------------------------------------------------------
setFillerMode -core {FILL64BWP7T40P140LVT FILL32BWP7T40P140LVT FILL16BWP7T40P140LVT FILL8BWP7T40P140LVT FILL4BWP7T40P140LVT FILL3BWP7T40P140LVT FILL2BWP7T40P140LVT}

# Routing settings  [setNanoRouteMode -help]
#-------------------------------------------------------------------------------
