# The default handoff directory is configured in project_config.tcl.  Its
# timing budget must be confirmed with the block interface owner.  Innovus
# ignores group_path while loading a constraint-mode SDC, so defer those
# commands until init_design applies them globally.
set pr_group_path_is_disabled false
if {[llength [info commands ::group_path]] > 0} {
  rename ::group_path ::pr_constraint_mode_group_path
  proc ::group_path {args} {}
  set pr_group_path_is_disabled true
}
set pr_source_status [catch {source $::PR_UPSTREAM_SDC} pr_source_result pr_source_options]
if {$pr_group_path_is_disabled} {
  rename ::group_path {}
  rename ::pr_constraint_mode_group_path ::group_path
}
if {$pr_source_status != 0} {
  return -options $pr_source_options $pr_source_result
}

reset_ideal_network [get_ports $::PR_CLOCK_PORT]

set_clock_uncertainty -setup 2.0 [get_clocks clock]
set_clock_uncertainty -hold 0.2 [get_clocks clock]
set_clock_transition -max 0.5 [get_clocks clock]
set_clock_transition -min 0.1 [get_clocks clock]
