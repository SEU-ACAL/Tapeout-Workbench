set     CLK_SOURCE_LATENCY  	 1
set     CLK_NETWORK_LATENCY 	 1
set     OUT_LOAD                 2

set     MAX_FANOUT               32
set     MAX_CAP                  1
set     MAX_TRAN                 2
##### 时钟周期参数定义 ###########################################################

if {![info exists CLOCK_PERIOD]} {
    set CLOCK_PERIOD 10.0
}
if {![string is double -strict $CLOCK_PERIOD] || ![expr {$CLOCK_PERIOD > 0.0}]} {
    error "CLOCK_PERIOD must be a positive number in nanoseconds, got '$CLOCK_PERIOD'"
}
set PAD_cpu_clock_period $CLOCK_PERIOD

if {![info exists JTAG_CLOCK_PERIOD]} {
    set JTAG_CLOCK_PERIOD 100.0
}
if {![info exists SERIAL_TL_CLOCK_PERIOD]} {
    set SERIAL_TL_CLOCK_PERIOD $CLOCK_PERIOD
}
foreach {clock_name clock_period} [list \
    JTAG_CLOCK_PERIOD $JTAG_CLOCK_PERIOD \
    SERIAL_TL_CLOCK_PERIOD $SERIAL_TL_CLOCK_PERIOD] {
    if {![string is double -strict $clock_period] || ![expr {$clock_period > 0.0}]} {
        error "$clock_name must be a positive number in nanoseconds, got '$clock_period'"
    }
}
set PAD_cpu_jtag_clock_period $JTAG_CLOCK_PERIOD
set PAD_cpu_serial_clock_period $SERIAL_TL_CLOCK_PERIOD

# set clk_pll_cpu_period              5

##### Source Clock Definition ###########################################################

set core_clk_port       [get_ports clock]
set jtag_clk_port       [get_ports jtag_TCK]
set serial_tl_clk_port  [get_ports serial_tl_0_clock_in]
set clk_ports           [get_ports {clock jtag_TCK serial_tl_0_clock_in}]
# These are asynchronous control inputs, not clock-synchronous data inputs.
set reset_ports     [get_ports {reset jtag_reset}]
set jtag_input_ports [get_ports {jtag_TMS jtag_TDI}]
set jtag_output_ports [get_ports jtag_TDO]
set serial_tl_input_ports [get_ports {
    serial_tl_0_in_valid
    serial_tl_0_in_bits_phit*
    serial_tl_0_out_ready
}]
set serial_tl_output_ports [get_ports {
    serial_tl_0_in_ready
    serial_tl_0_out_valid
    serial_tl_0_out_bits_phit*
}]
set data_inputs 	 [remove_from_collection [all_inputs]  $clk_ports]
set data_inputs     [remove_from_collection $data_inputs $reset_ports]
set data_inputs     [remove_from_collection $data_inputs $jtag_input_ports]
set data_inputs     [remove_from_collection $data_inputs $serial_tl_input_ports]
set data_outputs	 [remove_from_collection [all_outputs] $clk_ports]
set data_outputs    [remove_from_collection $data_outputs $jtag_output_ports]
set data_outputs    [remove_from_collection $data_outputs $serial_tl_output_ports]
create_clock $core_clk_port -period $PAD_cpu_clock_period \
    -waveform [list 0 [expr $PAD_cpu_clock_period / 2.0]] -name clock
create_clock $jtag_clk_port -period $PAD_cpu_jtag_clock_period \
    -waveform [list 0 [expr $PAD_cpu_jtag_clock_period / 2.0]] -name jtag_tck
create_clock $serial_tl_clk_port -period $PAD_cpu_serial_clock_period \
    -waveform [list 0 [expr $PAD_cpu_serial_clock_period / 2.0]] -name serial_tl_clk

set core_regs   [all_registers -clock [get_clocks clock]]
set jtag_regs   [all_registers -clock [get_clocks jtag_tck]]
set serial_regs [all_registers -clock [get_clocks serial_tl_clk]]

# The JTAG and Serial-TL clocks are independent of the SoC clock and of
# each other. CDC structures in RTL handle transfers between these domains.
set_clock_groups -asynchronous \
    -group [get_clocks clock] \
    -group [get_clocks jtag_tck] \
    -group [get_clocks serial_tl_clk]





##### 时钟约束设置 - 使用参数 ###########################################################

# Use independent setup and hold uncertainty budgets.
set_clock_uncertainty -setup [expr $PAD_cpu_clock_period * 0.3] [get_clocks clock]
set_clock_uncertainty -hold  0 [get_clocks clock]
set_clock_uncertainty -setup [expr $PAD_cpu_jtag_clock_period * 0.3] [get_clocks jtag_tck]
set_clock_uncertainty -hold  0 [get_clocks jtag_tck]
set_clock_uncertainty -setup [expr $PAD_cpu_serial_clock_period * 0.3] [get_clocks serial_tl_clk]
set_clock_uncertainty -hold  0 [get_clocks serial_tl_clk]

# Transition设置 (period的10%)

set_clock_transition  [expr $PAD_cpu_clock_period * 0.1]        [get_clocks clock]
set_clock_transition  [expr $PAD_cpu_jtag_clock_period * 0.1]   [get_clocks jtag_tck]
set_clock_transition  [expr $PAD_cpu_serial_clock_period * 0.1] [get_clocks serial_tl_clk]


# Input/Output Delay设置 (period的50%)

set_input_delay   [expr $PAD_cpu_clock_period * 0.5]        -clock [get_clocks clock] $data_inputs
set_output_delay  [expr $PAD_cpu_clock_period * 0.5]        -clock [get_clocks clock] $data_outputs

# Interface delays are relative to their own source clocks, not the SoC clock.
set_input_delay   [expr $PAD_cpu_jtag_clock_period * 0.5]   -clock [get_clocks jtag_tck] $jtag_input_ports
# TDO changes on the falling edge of TCK.  Use zero board delay until a
# package/board timing budget is available, while keeping the endpoint
# explicitly constrained for check_timing.
set_output_delay -max 0 -clock [get_clocks jtag_tck] $jtag_output_ports
set_output_delay -min 0 -clock [get_clocks jtag_tck] $jtag_output_ports
set_input_delay   [expr $PAD_cpu_serial_clock_period * 0.5] -clock [get_clocks serial_tl_clk] $serial_tl_input_ports
set_output_delay  [expr $PAD_cpu_serial_clock_period * 0.5] -clock [get_clocks serial_tl_clk] $serial_tl_output_ports




# Keep timing reports separate for each clock domain.  The asynchronous clock
# groups above remove inter-domain paths; these groups classify the remaining
# intra-domain paths.
group_path -name core_I2R \
    -from $data_inputs \
    -to   $core_regs
group_path -name core_R2R \
    -from $core_regs \
    -to   $core_regs
group_path -name core_R2O \
    -from $core_regs \
    -to   $data_outputs
group_path -name core_I2O \
    -from $data_inputs \
    -to   $data_outputs

group_path -name jtag_I2R \
    -from $jtag_input_ports \
    -to   $jtag_regs
group_path -name jtag_R2R \
    -from $jtag_regs \
    -to   $jtag_regs
group_path -name jtag_R2O \
    -from $jtag_regs \
    -to   $jtag_output_ports
group_path -name jtag_I2O \
    -from $jtag_input_ports \
    -to   $jtag_output_ports

group_path -name serial_I2R \
    -from $serial_tl_input_ports \
    -to   $serial_regs
group_path -name serial_R2R \
    -from $serial_regs \
    -to   $serial_regs
group_path -name serial_R2O \
    -from $serial_regs \
    -to   $serial_tl_output_ports
group_path -name serial_I2O \
    -from $serial_tl_input_ports \
    -to   $serial_tl_output_ports

set ALL_EX_OUT          [remove_from_collection [current_design] [all_outputs]]
set ALL_EX_OUT_IN       [remove_from_collection $ALL_EX_OUT [all_inputs]]
set_max_transition      $MAX_TRAN               $ALL_EX_OUT_IN 
set_max_fanout          $MAX_FANOUT             $ALL_EX_OUT_IN
#set_max_capacitance     $MAX_CAP                $ALL_EX_OUT_IN

# set_ideal_network  [all_clocks]
#   [all_clocks]
set_ideal_network $clk_ports

# set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/clockOut}]
# # set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/auto_clock_out_member_allClocks_uncore_clock}]
# Restrict sequential optimization/retiming to the double-precision FMA pipe.
set_optimize_registers true -designs [get_designs FPUFMAPipe_l4_f64]
set_optimize_registers true -designs [get_designs FPUFMAPipe_l4_f32]
# set_optimize_registers [get_designs FPU] true
# set_optimize_registers [get_designs BranchPredictor] true
# set_optimize_registers [get_designs PipelinedMulUnit] true

# set_optimize_registers [get_designs MulDiv_1] true
# set_optimize_registers [get_designs MulDiv_3] true
