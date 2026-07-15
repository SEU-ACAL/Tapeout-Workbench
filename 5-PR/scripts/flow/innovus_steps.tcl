# Flowkit v23.10-a001_1
#- innovus_steps.tcl : defines Innovus based flowsteps


#===========================================================================
# Flow: floorplan
#===========================================================================

##############################################################################
# STEP add_tracks
##############################################################################
create_flow_step -name add_tracks -owner cadence {
  #- generate tracks after creating floorplan
  add_tracks
}


#===========================================================================
# Flow: prects
#===========================================================================

##############################################################################
# STEP run_place_opt
##############################################################################
create_flow_step -name run_place_opt -owner cadence {
  #- perform global placement and ideal clock setup optimization
place_opt_design -out_dir debug -prefix [get_flowkit_db flow_report_name]
}


#===========================================================================
# Flow: cts
#===========================================================================

##############################################################################
# STEP add_clock_spec
##############################################################################
create_flow_step -name add_clock_spec -owner cadence {
  #- automatically create clock spec if one is not available
  if {[llength [get_ccopt_clock_tree_sinks  *]] == 0} {
    create_ccopt_clock_tree_spec
  } else {
    puts "INFO: reusing existing clock tree spec"
    puts "        to reload a new one use 'delete_clock_tree_spec' and 'read_ccopt_config"
  }
}

##############################################################################
# STEP add_clock_tree
##############################################################################
create_flow_step -name add_clock_tree -owner cadence {
  #- implement clock trees and propagated clock setup optimization
  if {[getOptMode -opt_enable_podv2_clock_opt_flow]} {
    clock_opt_design -out_dir debug -prefix [get_flowkit_db flow_report_name]
  } else {
    ccopt_design -outDir debug -prefix [get_flowkit_db flow_report_name]
  }
}

##############################################################################
# STEP add_tieoffs
##############################################################################
create_flow_step -name add_tieoffs -owner cadence {
  #- insert dedicated tieoff models
  if {[getTieHiLoMode -cell -quiet] ne "" } {
    addTieHiLo -matchingPDs true
  }
}


#===========================================================================
# Flow: postcts
#===========================================================================

##############################################################################
# STEP run_opt_postcts_hold
##############################################################################
create_flow_step -name run_opt_postcts_hold -owner cadence {
  #- perform postcts hold optimization
  optDesign -postCts -hold -outDir debug -prefix [get_flowkit_db flow_report_name]
}


#===========================================================================
# Flow: route
#===========================================================================

##############################################################################
# STEP add_fillers
##############################################################################
create_flow_step -name add_fillers -owner cadence {
  #- insert filler cells before final routing
  if {[getFillerMode -core -quiet] ne "" } {
    addFiller
  }
}

##############################################################################
# STEP run_route
##############################################################################
create_flow_step -name run_route -owner cadence {
  #- perform detail routing and DRC cleanup
  routeDesign
}


#===========================================================================
# Flow: postroute
#===========================================================================

##############################################################################
# STEP run_opt_postroute
##############################################################################
create_flow_step -name run_opt_postroute -owner cadence {
  #- perform postroute and SI based setup optimization
  optDesign -postRoute -setup -hold -outDir debug -prefix [get_flowkit_db flow_report_name]
}

#=============================================================================
# Flow: eco
#=============================================================================

##############################################################################
# STEP eco_start
##############################################################################
create_flow_step -name eco_start -owner cadence {
}

##############################################################################
# STEP run_place_eco
##############################################################################
create_flow_step -name run_place_eco -owner cadence {
  ecoPlace
}

##############################################################################
# STEP run_route_eco
##############################################################################
create_flow_step -name run_route_eco -owner cadence {
  ecoRoute
}

##############################################################################
# STEP eco_finish
##############################################################################
create_flow_step -name eco_finish -owner cadence -write_db {
}


#===========================================================================
# Flow: report_innovus
#===========================================================================

##############################################################################
# STEP schedule_report_floorplan
##############################################################################
create_flow_step -name schedule_report_floorplan -owner cadence -exclude_time_metric -skip_metric {
  schedule_flow \
    -flow report_floorplan  \
    -branch [get_flowkit_db flow_branch] \
    -no_sync \
    -include_in_metrics
}

##############################################################################
# STEP schedule_report_prects
##############################################################################
create_flow_step -name schedule_report_prects -owner cadence -exclude_time_metric -skip_metric {
  schedule_flow \
    -flow report_prects  \
    -branch [get_flowkit_db flow_branch] \
    -no_sync \
    -include_in_metrics
}

##############################################################################
# STEP schedule_report_postcts
##############################################################################
create_flow_step -name schedule_report_postcts -owner cadence -exclude_time_metric -skip_metric {
  schedule_flow \
    -flow report_postcts  \
    -branch [get_flowkit_db flow_branch] \
    -no_sync \
    -include_in_metrics
}

##############################################################################
# STEP schedule_report_postroute
##############################################################################
create_flow_step -name schedule_report_postroute -owner cadence -exclude_time_metric -skip_metric {
  schedule_flow \
    -flow report_postroute  \
    -branch [get_flowkit_db flow_branch] \
    -no_sync \
    -include_in_metrics
}

##############################################################################
# STEP report_area_innovus
##############################################################################
create_flow_step -name report_area_innovus -owner cadence -exclude_time_metric -categories {flow design} {
  summaryReport -noHtml -outdir debug -outfile [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/qor.rpt
  report_area -out_file [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/area.summary.rpt -min_count 1000
}

##############################################################################
# STEP report_timing_late_innovus
##############################################################################
create_flow_step -name report_timing_late_innovus -owner cadence -exclude_time_metric -categories setup {
  #- Update the timer for setup and write reports
  timeDesign -expandedViews -reportOnly -outDir debug

  #- Reports that describe timing health
  report_analysis_summary -late                               > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.analysis_summary.rpt
  report_analysis_summary -late -merged_groups                > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.group_summary.rpt
  report_analysis_summary -late -merged_groups -merged_views  > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.view_summary.rpt
  report_constraint       -late -all_violators                > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/setup.all_violators.rpt
  set_metric -name timing.drv.report_file -value                [get_flowkit_db flow_report_name]/setup.all_violators.rpt
}

##############################################################################
# STEP report_timing_early_innovus
##############################################################################
create_flow_step -name report_timing_early_innovus -owner cadence -exclude_time_metric -categories hold {
  #- Update the timer for hold and write reports
  timeDesign -expandedViews -hold -reportOnly -outDir debug

  #- Reports that describe timing health
  report_analysis_summary -early                               > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.analysis_summary.rpt
  report_analysis_summary -early -merged_groups                > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.group_summary.rpt
  report_analysis_summary -early -merged_groups -merged_views  > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.view_summary.rpt
  report_constraint       -early -all_violators                > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/hold.all_violators.rpt
}

##############################################################################
# STEP report_clock_timing
##############################################################################
create_flow_step -name report_clock_timing -owner cadence -exclude_time_metric -categories clock {
  #- Reports that check clock implementation
  report_clock_timing -type summary > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/clock.summary.rpt
  report_clock_timing -type latency > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/clock.latency.rpt
  report_clock_timing -type skew    > [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/clock.skew.rpt
}

##############################################################################
# STEP report_power_innovus
##############################################################################
create_flow_step -name report_power_innovus -owner cadence -exclude_time_metric -categories power {
  #- Ensure leakge power view is active when specified
  if {([get_power_analysis_mode -quiet -leakage_power_view] ne "{}") && \
      ([lsearch -exact [lsort -unique [concat [all_setup_analysis_views] [all_hold_analysis_views]]] [get_power_analysis_mode -quiet -leakage_power_view]] == -1)} {
    set_analysis_view \
      -setup [lsort -unique [concat [get_power_analysis_mode -quiet -leakage_power_view] [all_setup_analysis_views]]] \
      -hold [all_hold_analysis_views]
  }

  report_power -no_wrap -outfile [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/power.all.rpt
}

##############################################################################
# STEP report_route_process
##############################################################################
create_flow_step -name report_route_process -owner cadence -exclude_time_metric {
  #- Reports that process rules
  verifyProcessAntenna -report [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.antenna.rpt
  checkFiller -file [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.filler.rpt
}

##############################################################################
# STEP report_route_drc
##############################################################################
create_flow_step -name report_route_drc -owner cadence -exclude_time_metric -categories route {
  #- Reports that check signal routing
  verify_drc -report [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.drc.report
  verify_connectivity -report [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.open.report
}

##############################################################################
# STEP report_route_density
##############################################################################
create_flow_step -name report_route_density -owner cadence -exclude_time_metric {
  verifyMetalDensity -report [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.metal_density.rpt
  verifyCutDensity -report [get_flowkit_db flow_report_directory]/[get_flowkit_db flow_report_name]/route.cut_density.rpt
}
