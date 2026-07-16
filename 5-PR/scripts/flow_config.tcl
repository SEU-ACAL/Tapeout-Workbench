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

create_flow_step -name write_outputs -owner design -write_db {
  set out_dir [file join $::PR_ROOT outputs]
  file mkdir $out_dir
  saveNetlist -topModuleFirst -topCell $::TOP_MODULE [file join $out_dir $::TOP_MODULE.v]
  defOut [file join $out_dir $::TOP_MODULE.def]
  rcOut -spef [file join $out_dir $::TOP_MODULE.spef]
}

edit_flow -after flow_step:run_opt_postroute -append flow_step:write_outputs

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
