# Flowkit v23.10-a001_1
################################################################################
# This file contains content which is used to customize the refererence flow
# process.  Commands such as 'create_flow', 'create_flow_step' and 'edit_flow'
# would be most prevalent.  For example:
#
# create_flow_step -name write_sdf -write_db {
#   write_sdf [get_flowkit_db flow_report_directory]/[get_flowkit_db local_flow].sdf
# }
#
# edit_flow -after flow_step:innovus_report_late_timing -append flow_step:write_sdf
#
################################################################################

################################################################################
# FLOW CUSTOMIZATIONS / FLOW STEP ADDITIONS
################################################################################
# Directory root of the flow scripts, can be used with file join to normalize paths to flow files.
set_flowkit_db init_flow_directory    [file dirname [file normalize [info script]]]

proc ::pr_read_report {path} {
  if {![file exists $path] || [file size $path] == 0} {
    error "Required signoff report is missing or empty: $path"
  }
  set report [open $path r]
  set text [read $report]
  close $report
  return $text
}

proc ::pr_timing_report_name {name} {
  set report_name [string map [list " " "_" "/" "_" "\\" "_" ":" "_" "{" "_" "}" "_"] $name]
  regsub -all {[^A-Za-z0-9_.-]} $report_name _ report_name
  return $report_name
}

proc ::pr_apply_upstream_path_groups {sdc_file} {
  if {![file exists $sdc_file]} {
    error "Cannot apply path groups from missing SDC: $sdc_file"
  }

  # Innovus treats SDC files loaded by create_constraint_mode as mode-local and
  # ignores group_path.  Re-source the upstream SDC after init_design with all
  # non-group commands temporarily disabled so the original group definitions
  # remain the single source of truth and become global as required by Innovus.
  set disabled_commands {
    set_units
    set_max_transition
    set_max_fanout
    set_ideal_network
    create_clock
    set_clock_uncertainty
    set_clock_transition
    set_input_delay
    set_output_delay
  }
  set saved_commands {}
  foreach command $disabled_commands {
    set original_command ::$command
    if {[llength [info commands $original_command]] == 0} {
      continue
    }
    set saved_command ::pr_path_group_saved_$command
    rename $original_command $saved_command
    proc $original_command {args} {}
    lappend saved_commands [list $original_command $saved_command]
  }

  set status [catch {uplevel #0 [list source $sdc_file]} result options]
  foreach command_pair [lreverse $saved_commands] {
    lassign $command_pair original_command saved_command
    rename $original_command {}
    rename $saved_command $original_command
  }
  if {$status != 0} {
    return -options $options $result
  }

  set path_groups [get_path_groups -include_internal_groups *]
  set path_group_names {}
  foreach_in_collection path_group $path_groups {
    lappend path_group_names [get_object_name $path_group]
  }
  puts "PR_PATH_GROUPS groups=$path_group_names source=$sdc_file"
}

proc ::pr_write_grouped_timing_reports {report_dir check_type} {
  if {$check_type eq "setup"} {
    set views [all_setup_analysis_views]
    set analysis_flag -late
  } elseif {$check_type eq "hold"} {
    set views [all_hold_analysis_views]
    set analysis_flag -early
  } else {
    error "Unsupported timing report type '$check_type'"
  }

  if {[llength $views] == 0} {
    error "No active $check_type analysis views are available for reporting"
  }

  set timing_dir [file join $report_dir timing $check_type]
  file mkdir $timing_dir
  set index [open [file join $timing_dir index.rpt] w]
  puts $index "TIMING REPORT INDEX"
  puts $index "check_type=$check_type"
  puts $index "active_views=$views"
  puts $index ""

  if {[catch {get_path_groups -include_internal_groups *} path_groups] || $path_groups eq ""} {
    close $index
    error "No path groups are defined; cannot produce grouped $check_type timing reports"
  }

  foreach view $views {
    set view_dir [file join $timing_dir [::pr_timing_report_name $view]]
    file mkdir $view_dir
    puts $index "VIEW: $view"
    puts $index "  summary: [file join [file tail $view_dir] summary.rpt]"
    puts $index "  constraints: [file join [file tail $view_dir] constraints.rpt]"

    report_analysis_summary $analysis_flag -view $view > [file join $view_dir summary.rpt]
    report_constraint $analysis_flag -all_violators -view $view > [file join $view_dir constraints.rpt]

    foreach_in_collection path_group $path_groups {
      set group_name [get_object_name $path_group]
      set group_dir [file join $view_dir [::pr_timing_report_name $group_name]]
      file mkdir $group_dir
      puts $index "  GROUP: $group_name"
      puts $index "    endpoints: [file join [file tail $group_dir] endpoints.rpt]"
      puts $index "    worst_path: [file join [file tail $group_dir] worst_path.rpt]"

      report_timing $analysis_flag -view $view -path_group $group_name \
        -max_paths 200 -nworst 1 -path_type end_slack_only > [file join $group_dir endpoints.rpt]
      report_timing $analysis_flag -view $view -path_group $group_name \
        -max_paths 1 -nworst 1 -path_type full_clock -net > [file join $group_dir worst_path.rpt]
    }
    puts $index ""
  }
  close $index
}

proc ::pr_gate_signoff_report {name path} {
  set text [::pr_read_report $path]
  if {[regexp -nocase {\mERROR\M} $text]} {
    error "Signoff $name report contains ERROR: $path"
  }

  # Innovus uses report-specific prose for clean verification results.
  # Handle those forms before falling back to numeric summary parsing.
  if {[regexp -nocase {no\s+(?:drc\s+)?violations?\s+were\s+found|no\s+violations?\s+found|found\s+no\s+problems(?:\s+or\s+warnings)?} $text]} {
    set ::PR_SIGNOFF_CHECK_STATUS($name) pass
    puts "PR_SIGNOFF_CHECK name=$name status=pass count=0"
    return
  }

  set count ""
  foreach pattern {
    {(?:total|number of)[^\n]*(?:violations?|errors?|opens?|shorts?|unconnected)[^0-9]*([0-9]+)}
    {(?:violations?|errors?|opens?|shorts?|unconnected)[[:space:]]*[:=][[:space:]]*([0-9]+)}
  } {
    if {[regexp -nocase $pattern $text -> count]} {
      break
    }
  }

  if {$count eq ""} {
    error "Cannot determine $name signoff count from $path; delivery is blocked"
  }
  if {$count == 0} {
    set ::PR_SIGNOFF_CHECK_STATUS($name) pass
    puts "PR_SIGNOFF_CHECK name=$name status=pass count=0"
    return
  }
  if {[dict exists $::PR_SIGNOFF_WAIVERS $name]} {
    set ::PR_SIGNOFF_CHECK_STATUS($name) waived
    puts "PR_SIGNOFF_CHECK name=$name status=waived count=$count waiver=[dict get $::PR_SIGNOFF_WAIVERS $name]"
    return
  }
  error "Signoff $name has $count violation(s): $path"
}

proc ::pr_gate_clock_drv {path} {
  set text [::pr_read_report $path]
  if {[regexp -nocase {\|[^\n|]*\|[^\n|]*\|[^\n|]*\|\s*-[0-9.]+\s*\|} $text] || \
      [regexp -nocase {(^|\n)[^\n]*(max[_ ]?(fanout|transition|capacitance)|fanout|transition)[^\n]*\mVIOLATED\M} $text]} {
    error "Unresolved clock fanout/DRV violation: $path"
  }
  if {[regexp -nocase {(disconnected|unrouted)[^\n]*(clock|net)|(clock|net)[^\n]*(disconnected|unrouted)} $text]} {
    error "Disconnected or unrouted clock net: $path"
  }
  set ::PR_SIGNOFF_CHECK_STATUS(clock_drv) pass
  puts "PR_SIGNOFF_CHECK name=clock_drv status=pass"
}

proc ::pr_check_io_pin_placement {def_file report_file} {
  defOut $def_file
  set def_text [::pr_read_report $def_file]
  set report [open $report_file w]
  set unplaced_ports {}

  foreach_in_collection port [get_ports *] {
    set port_name [get_object_name $port]
    set record_start [string first "- $port_name " $def_text]
    if {$record_start < 0} {
      lappend unplaced_ports $port_name
      puts $report "port=$port_name status=missing"
      continue
    }
    set record_end [string first "\n;" $def_text $record_start]
    if {$record_end < 0} {
      set record_end [string length $def_text]
    }
    set record [string range $def_text $record_start $record_end]
    if {[regexp {\+ (?:PLACED|FIXED|COVER) \(} $record]} {
      puts $report "port=$port_name status=placed"
    } else {
      lappend unplaced_ports $port_name
      puts $report "port=$port_name status=unplaced"
    }
  }
  close $report

  if {[llength $unplaced_ports] != 0} {
    error "Unplaced I/O port(s): $unplaced_ports; see $report_file"
  }
  puts "PR_IO_PIN_PLACEMENT status=pass ports=[sizeof_collection [get_ports *]]"
}

proc ::pr_write_io_pin_placement_report {report_dir} {
  ::pr_check_io_pin_placement [file join $report_dir io_pin_placement.def] \
    [file join $report_dir io_pin_placement.rpt]
}

create_flow_step -name run_final_reports -owner design -exclude_time_metric {
  set report_dir $::PR_FINAL_REPORT_DIR
  file mkdir $report_dir

  timeDesign -expandedViews -reportOnly -outDir [file join $report_dir timing_debug]
  ::pr_write_grouped_timing_reports $report_dir setup
  ::pr_write_grouped_timing_reports $report_dir hold
  report_constraint -all_violators > [file join $report_dir clock.drv.rpt]
  report_clock_timing -type summary > [file join $report_dir clock.summary.rpt]
  report_clock_timing -type latency > [file join $report_dir clock.latency.rpt]
  report_clock_timing -type skew > [file join $report_dir clock.skew.rpt]
  report_area -out_file [file join $report_dir area.summary.rpt] -min_count 1000
  report_power -no_wrap -outfile [file join $report_dir power.rpt]
  verify_drc -report [file join $report_dir route.drc.rpt]
  verify_connectivity -report [file join $report_dir route.open.rpt]
  verifyProcessAntenna -report [file join $report_dir route.antenna.rpt]
  verifyMetalDensity -report [file join $report_dir route.metal_density.rpt]
  verifyCutDensity -report [file join $report_dir route.cut_density.rpt]
  checkDesign -all > [file join $report_dir design.check.rpt]
  ::pr_write_io_pin_placement_report $report_dir
}

create_flow_step -name gate_final_signoff -owner design -exclude_time_metric {
  set report_dir $::PR_FINAL_REPORT_DIR
  ::pr_read_report [file join $report_dir io_pin_placement.rpt]
  ::pr_gate_clock_drv [file join $report_dir clock.drv.rpt]
  ::pr_gate_signoff_report drc [file join $report_dir route.drc.rpt]
  ::pr_gate_signoff_report connectivity [file join $report_dir route.open.rpt]
  ::pr_gate_signoff_report antenna [file join $report_dir route.antenna.rpt]

  set design_check [::pr_read_report [file join $report_dir design.check.rpt]]
  if {[regexp -nocase {ERROR\s*:|(?:[1-9][0-9]*)\s+errors?\b|errors?\s*[:=]\s*[1-9]} $design_check]} {
    error "Final design/connectivity check reported ERROR; see [file join $report_dir design.check.rpt]"
  }
  set ::PR_FINAL_SIGNOFF_STATUS pass
  set ::PR_SIGNOFF_CHECK_STATUS(final) pass
  puts "PR_SIGNOFF_CHECK name=final status=pass"
}

create_flow_step -name write_outputs -owner design -write_db {
  if {![info exists ::PR_FINAL_SIGNOFF_STATUS] || $::PR_FINAL_SIGNOFF_STATUS ne "pass"} {
    error "Final outputs are blocked until all signoff checks pass"
  }
  set out_dir [file join $::PR_ROOT outputs]
  file mkdir $out_dir
  saveNetlist -topModuleFirst -topCell $::TOP_MODULE [file join $out_dir $::TOP_MODULE.v]
  defOut [file join $out_dir $::TOP_MODULE.def]
  # A restored Innovus database may not retain the active RC extraction
  # handle even when post-route parasitics were used for timing.  Rebuild it
  # before emitting corner-specific SPEF files.
  extractRC -noRouteCheck
  foreach rc_corner {rc_worst rc_best} {
    rcOut -spef [file join $out_dir $::TOP_MODULE.$rc_corner.spef] -rc_corner $rc_corner
  }

  set manifest [open [file join $out_dir manifest.txt] w]
  set tool_version unknown
  set version_text ""
  if {![catch {redirect -variable version_text {version}}]} {
    if {[regexp {Version:\s*([^,\s]+)} $version_text -> parsed_version]} {
      set tool_version $parsed_version
    }
  }
  if {$tool_version eq "unknown"} {
    set tool_version "Innovus-23.10-p003_1"
  }
  puts $manifest "generated_utc=[clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]"
  puts $manifest "tool_version=$tool_version"
  puts $manifest "top_module=$::TOP_MODULE"
  puts $manifest "input_netlist=$::NETLIST"
  puts $manifest "input_pr_sdc=$::SDC"
  puts $manifest "input_upstream_sdc=$::PR_UPSTREAM_SDC"
  foreach spec $::PR_MMMC_VIEW_SPECS {
    lassign $spec view library_set rc_corner check_type
    lassign [dict get $::PR_LIBRARY_PVT $library_set] voltage temperature
    set rc_temperature [dict get $::RC_CORNER_TEMPERATURES $rc_corner]
    puts $manifest "analysis_view=$view check=$check_type library=$library_set voltage=$voltage temperature=$temperature rc_corner=$rc_corner rc_temperature=${rc_temperature}C"
  }
  foreach rc_corner {rc_worst rc_best c_worst c_best rc_typical} {
    puts $manifest "qrc_$rc_corner=[dict get $::QRC_TECH_FILES $rc_corner]"
  }
  foreach check {clock_drv drc connectivity antenna final} {
    puts $manifest "check_$check=$::PR_SIGNOFF_CHECK_STATUS($check)"
  }
  puts $manifest "check_status=$::PR_FINAL_SIGNOFF_STATUS"
  close $manifest
}

edit_flow -after flow_step:run_opt_postroute -append flow_step:run_final_reports
edit_flow -after flow_step:run_final_reports -append flow_step:gate_final_signoff
edit_flow -after flow_step:gate_final_signoff -append flow_step:write_outputs

##############################################################################
# STEP report_late_paths
##############################################################################
create_flow_step -name report_late_paths -owner flow -exclude_time_metric {
  #- Reports that show detailed timing with Graph Based Analysis (GBA)
  if {[is_flow -quiet -inside flow:report_prects] || [is_flow -quiet -inside flow:report_postcts] || \
      [is_flow -quiet -inside flow:report_postroute] || [is_flow -quiet -inside flow:sta]} {
    report_timing -max_paths 5   -nworst 1 -path_type end_slack_only  > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.endpoint.rpt
    report_timing -max_paths 1   -nworst 1 -path_type full_clock -net > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.worst.rpt
    report_timing -max_paths 500 -nworst 1 -path_type full_clock      > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.gba.rpt
  }
}

##############################################################################
# STEP report_early_paths
##############################################################################
create_flow_step -name report_early_paths -owner flow -exclude_time_metric {
  #- Reports that show detailed early timing with Graph Based Analysis (GBA)
  report_timing -early -max_paths 5   -nworst 1 -path_type end_slack_only  > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.endpoint.rpt
  report_timing -early -max_paths 1   -nworst 1 -path_type full_clock -net > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.worst_max_path.rpt
  report_timing -early -max_paths 500 -nworst 1 -path_type full_clock      > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.gba.rpt

}
