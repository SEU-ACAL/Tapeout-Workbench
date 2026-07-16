source /data1/GB/ic_workbench/2-SYN/outputs/0715_0544/multiplier_pipe3.sdc

set_clock_uncertainty -setup 2.0 [get_clocks clock]
set_clock_uncertainty -hold 0.2 [get_clocks clock]
set_clock_transition -max 0.5 [get_clocks clock]
set_clock_transition -min 0.1 [get_clocks clock]
