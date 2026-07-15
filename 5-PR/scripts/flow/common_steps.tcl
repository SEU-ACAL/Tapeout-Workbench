# Flowkit v23.10-a001_1
#- steps.common.tcl file: defines common flow attributes and flowsteps

#===============================================================================
# Common attributes used in implementation flow
#===============================================================================

#- Specify Flow Header (runs at the start of run_flow command)
set_flowkit_db flow_header_tcl {
  um::enable_metric -on

  #- extend flow report name based on context
  if {[is_flow -quiet -inside flow:sta]} {
    set_flowkit_db flow_report_name [get_flowkit_db flow_report_name].sta
  } elseif {[is_flow -quiet -inside flow:eco]} {
    set_flowkit_db flow_report_name [get_flowkit_db flow_report_name].eco
  } elseif {[regexp {block_start|hier_start} [get_flowkit_db flow_step_current]]} {
    set_flowkit_db flow_report_name [string range [lindex [get_flowkit_db flow_hier_path] end] 5 end]
  } else {
  }

  #- Create report dir (if necessary)
  file mkdir [file normalize [file join [get_flowkit_db flow_report_directory] [get_flowkit_db flow_report_name]]]

  #- Load Feature Specified Attributes and Overrides
  uplevel #0 source [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl]
}

#- Specify qor html file to generate at the end of every flow
set_flowkit_db flowtool_metrics_qor_html [get_flowkit_db flow_report_directory]/qor.html

#===============================================================================
# Common steps used in implementation flow
#===============================================================================

##############################################################################
# STEP block_start
##############################################################################
create_flow_step -name block_start -owner cadence {
  set_flowkit_db flow_write_db_common false
}

##############################################################################
# STEP block_finish
##############################################################################
create_flow_step -name block_finish -owner cadence -write_db -categories flow {
  #- Make sure flow_report_name is reset from any reports executed during the flow
  set_flowkit_db flow_report_name [string range [lindex [get_flowkit_db flow_hier_path] end] 5 end]
}

#===============================================================================
# Common steps used in parallel reporting
#===============================================================================

##############################################################################
# STEP report_start
##############################################################################
create_flow_step -name report_start -owner cadence -exclude_time_metric {
}

##############################################################################
# STEP report_finish
##############################################################################
create_flow_step -name report_finish -owner cadence -exclude_time_metric -categories flow {
}

##############################################################################
# STEP innovus_to_tempus
##############################################################################
create_flow_step -name innovus_to_tempus -owner cadence {
  #- create output location
  set design  [dbGet top.name]
  set out_dir [file join [get_flowkit_db flow_db_directory] [get_flowkit_db flow_report_name]]
  file mkdir $out_dir

  #- write design and library information
  saveNetlist -topModuleFirst -topCell $design [file join $out_dir $design.v]

  #- write init_design sequence for STA flow
  set FH [open $out_dir/init_sta.tcl w]
  puts $FH "set init_mmmc_file $::init_mmmc_file"
  puts $FH "set init_verilog [file join $out_dir $design.v]"
  puts $FH "init_design"
  puts $FH "set_flowkit_db flow_report_name [get_flowkit_db flow_report_name]"
  close $FH
}

##############################################################################
# STEP schedule_sta
##############################################################################
create_flow_step -name schedule_sta -owner cadence -skip_metric {
  schedule_flow \
    -flow sta \
    -branch [get_flowkit_db flow_branch] \
    -db [file join [get_flowkit_db flow_db_directory] [get_flowkit_db flow_report_name] init_sta.tcl] \
    -include_in_metrics \
    -no_sync
}
