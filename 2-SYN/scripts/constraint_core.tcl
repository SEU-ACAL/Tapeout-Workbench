set     CLK_SOURCE_LATENCY  	 1
set     CLK_NETWORK_LATENCY 	 1
set     OUT_LOAD                 2

set     MAX_FANOUT               32
set     MAX_CAP                  1
set     MAX_TRAN                 2
##### 时钟周期参数定义 ###########################################################

set PAD_cpu_clock_period            40
# set PAD_cpu_serial_clock_period     20
# set PAD_cpu_jtag_clock_period       100
# set clk_pll_cpu_period              5

##### Source Clock Definition ###########################################################

set clk_ports		 [get_ports {clock}]
set data_inputs 	 [remove_from_collection [all_inputs]  $clk_ports]
set data_outputs	 [remove_from_collection [all_outputs] $clk_ports]
set timing_regs [all_registers]

create_clock [get_ports clock] 									-period $PAD_cpu_clock_period 			-waveform [list 0 [expr $PAD_cpu_clock_period/2.0]] -name clock





##### 时钟约束设置 - 使用参数 ###########################################################

# Uncertainty设置 (period的30%)
set_clock_uncertainty [expr $PAD_cpu_clock_period * 0.3]        [get_clocks clock]

# Transition设置 (period的10%)

set_clock_transition  [expr $PAD_cpu_clock_period * 0.1]        [get_clocks clock]


# Input/Output Delay设置 (period的70%)

set_input_delay   [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks clock] $data_inputs            
set_output_delay  [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks clock] $data_outputs




# Input -> Register
group_path -name I2R \
    -from $data_inputs \
    -to   $timing_regs

# Register -> Register
group_path -name R2R \
    -from $timing_regs \
    -to   $timing_regs

# Register -> Output
group_path -name R2O \
    -from $timing_regs \
    -to   $data_outputs

# Input -> Output
group_path -name I2O \
    -from $data_inputs \
    -to   $data_outputs

set ALL_EX_OUT          [remove_from_collection [current_design] [all_outputs]]
set ALL_EX_OUT_IN       [remove_from_collection $ALL_EX_OUT [all_inputs]]
set_max_transition      $MAX_TRAN               $ALL_EX_OUT_IN 
set_max_fanout          $MAX_FANOUT             $ALL_EX_OUT_IN
#set_max_capacitance     $MAX_CAP                $ALL_EX_OUT_IN

# set_ideal_network  [all_clocks]
#   [all_clocks]
set_ideal_network [get_ports clock] 							

# set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/clockOut}]
# # set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/auto_clock_out_member_allClocks_uncore_clock}]
# set_optimize_registers [get_designs FPU] true
# set_optimize_registers [get_designs BranchPredictor] true
# set_optimize_registers [get_designs PipelinedMulUnit] true

# set_optimize_registers [get_designs MulDiv_1] true
# set_optimize_registers [get_designs MulDiv_3] true