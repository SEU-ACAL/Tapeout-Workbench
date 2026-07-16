# The default handoff directory is configured in project_config.tcl.  Its
# timing budget must be confirmed with the block interface owner.
source $::PR_UPSTREAM_SDC

set_clock_uncertainty -setup 2.0 [get_clocks clock]
set_clock_uncertainty -hold 0.2 [get_clocks clock]
set_clock_transition -max 0.5 [get_clocks clock]
set_clock_transition -min 0.1 [get_clocks clock]
