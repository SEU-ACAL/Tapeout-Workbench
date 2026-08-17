# SMIC180 implementation constraint wrapper.
# The synthesis SDC remains the source of interface timing budgets.  This
# wrapper adds the physical clocking intent used by Innovus CTS.

set pr_group_path_is_disabled false
if {[llength [info commands ::group_path]] > 0} {
  rename ::group_path ::pr_impl_saved_group_path
  proc ::group_path {args} {}
  set pr_group_path_is_disabled true
}
set pr_source_status [catch {source $::PR_UPSTREAM_SDC} pr_source_result pr_source_options]
if {$pr_group_path_is_disabled} {
  rename ::group_path {}
  rename ::pr_impl_saved_group_path ::group_path
}
if {$pr_source_status != 0} {
  return -options $pr_source_options $pr_source_result
}

# These clocks are implemented by CTS in the physical flow.  The upstream
# synthesis SDC marks them ideal for pre-CTS synthesis, which must not survive
# into implementation.
reset_ideal_network [get_ports {clock jtag_TCK serial_tl_0_clock_in}]

# Backend clock uncertainty budget: 10% for setup and 5% for hold.
# Derive the values from each clock period so the constraint remains scalable.
set pr_clock_period [lindex [get_property [get_clocks clock] period] 0]
set_clock_uncertainty -setup [expr {0.10 * $pr_clock_period}] [get_clocks clock]
set_clock_uncertainty -hold [expr {0.05 * $pr_clock_period}] [get_clocks clock]

set pr_jtag_period [lindex [get_property [get_clocks jtag_tck] period] 0]
set_clock_uncertainty -setup [expr {0.10 * $pr_jtag_period}] [get_clocks jtag_tck]
set_clock_uncertainty -hold [expr {0.05 * $pr_jtag_period}] [get_clocks jtag_tck]

set pr_serial_period [lindex [get_property [get_clocks serial_tl_clk] period] 0]
set_clock_uncertainty -setup [expr {0.10 * $pr_serial_period}] [get_clocks serial_tl_clk]
set_clock_uncertainty -hold [expr {0.05 * $pr_serial_period}] [get_clocks serial_tl_clk]

# The SP018RP POT8R pad used for clock_tap characterizes its PAD pin to
# 10 ns. The inherited 2 ns design-wide limit is for core cells and would
# incorrectly report this IO macro as a physical transition violation.
set_max_transition 10 [get_ports clock_tap]

# Keep the clock definitions and uncertainty from the upstream SDC.  CTS uses
# the technology-specific targets configured in innovus_config.tcl.
