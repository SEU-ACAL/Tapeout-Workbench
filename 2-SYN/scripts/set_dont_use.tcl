# Keep clock-optimized combinational cells out of ordinary data synthesis.
# CTS and explicit clock-gating cells remain available to the backend flow.
set_dont_use [get_lib_cells */CLK*]
