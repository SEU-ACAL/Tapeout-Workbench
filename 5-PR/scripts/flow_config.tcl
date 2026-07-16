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
  if {[regexp -nocase {(^|\n)[^\n]*(max[_ ]?(fanout|transition|capacitance)|fanout|transition)[^\n]*\mVIOLATED\M} $text]} {
    error "Unresolved clock fanout/DRV violation: $path"
  }
  if {[regexp -nocase {(disconnected|unrouted)[^\n]*(clock|net)|(clock|net)[^\n]*(disconnected|unrouted)} $text]} {
    error "Disconnected or unrouted clock net: $path"
  }
  set ::PR_SIGNOFF_CHECK_STATUS(clock_drv) pass
  puts "PR_SIGNOFF_CHECK name=clock_drv status=pass"
}

create_flow_step -name run_final_reports -owner design -exclude_time_metric {
  set report_dir $::PR_FINAL_REPORT_DIR
  file mkdir $report_dir

  timeDesign -expandedViews -reportOnly -outDir [file join $report_dir timing_debug]
  report_analysis_summary -late -merged_groups -merged_views > [file join $report_dir setup.summary.rpt]
  report_analysis_summary -early -merged_groups -merged_views > [file join $report_dir hold.summary.rpt]
  report_timing -max_paths 1 -nworst 1 -path_type full_clock -net > [file join $report_dir setup.worst.rpt]
  report_timing -early -max_paths 1 -nworst 1 -path_type full_clock -net > [file join $report_dir hold.worst.rpt]
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
}

create_flow_step -name gate_final_signoff -owner design -exclude_time_metric {
  set report_dir $::PR_FINAL_REPORT_DIR
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
  puts $manifest "setup_view=view_setup library=lib_ss voltage=0.81V temperature=125C rc_corner=rc_worst"
  puts $manifest "hold_view=view_hold library=lib_ff voltage=1.05V temperature=-40C rc_corner=rc_best"
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
