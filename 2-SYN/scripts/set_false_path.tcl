###########################################################################
# Asynchronous reset inputs are handled by ResetCatchAndSync in RTL.  Do
# not analyze them as clock-synchronous data paths.
###########################################################################

set reset_ports [get_ports {reset jtag_reset}]
set_false_path -from $reset_ports
