set     CLK_SOURCE_LATENCY  	 1
set     CLK_NETWORK_LATENCY 	 1
set     OUT_LOAD                 2

set     MAX_FANOUT               32
set     MAX_CAP                  1
set     MAX_TRAN                 2
##### 时钟周期参数定义 ###########################################################
set PAD_clk_FPGA_w_period           5
set PAD_clk_FPGA_cim_period         10
set PAD_top_clk_FPGA_test_period    5
set clk_pll_w_period                1.5
set clk_pll_cim_period              3
set PAD_cpu_clock_period            40
set PAD_cpu_serial_clock_period     20
set PAD_cpu_jtag_clock_period       100
set clk_pll_cpu_period              5

##### Source Clock Definition ###########################################################

set clk_ports		 [get_ports {clock serial_tl_0_clock_in jtag_TCK}]
set data_inputs 	 [remove_from_collection [all_inputs]  $clk_ports]
set data_outputs	 [remove_from_collection [all_outputs] $clk_ports]
set cpu_jtag_inputs		   [get_ports {jtag_TMS jtag_TDI}]
set cpu_jtag_outputs		 [get_ports {jtag_TDO}]
set cpu_serdess_inputs	 [get_ports {serial_tl_0_in_valid serial_tl_0_in_bits_phit serial_tl_0_out_ready}]
set cpu_serdess_outputs	 [get_ports {serial_tl_0_in_ready serial_tl_0_out_valid serial_tl_0_out_bits_phit}]
# create_clock [get_ports PAD_clk_FPGA_w] 								-period $PAD_clk_FPGA_w_period 			-waveform [list 0 [expr $PAD_clk_FPGA_w_period/2.0]] 			-name PAD_clk_FPGA_w
# create_clock [get_ports PAD_clk_FPGA_cim] 								-period $PAD_clk_FPGA_cim_period 		-waveform [list 0 [expr $PAD_clk_FPGA_cim_period/2.0]] 			-name PAD_clk_FPGA_cim 
# create_clock [get_ports PAD_top_clk_FPGA_test] 							-period $PAD_top_clk_FPGA_test_period 	-waveform [list 0 [expr $PAD_top_clk_FPGA_test_period/2.0]] 	-name PAD_top_clk_FPGA_test 

# create_clock [get_pins  {PLL6GS28_inst/O_PLL_CLKDIV}] 					-period $clk_pll_w_period 				-waveform [list 0 [expr $clk_pll_w_period/2.0]] 	-name clk_pll_w
# create_clock [get_pins  {PLL6GS28_inst/O_PLL_CLK_QP}] 					-period $clk_pll_cim_period 			-waveform [list 0 [expr $clk_pll_cim_period/2.0]] 	-name clk_pll_cim

create_clock [get_ports clock] 									-period $PAD_cpu_clock_period 			-waveform [list 0 [expr $PAD_cpu_clock_period/2.0]] -name clock
create_clock [get_ports jtag_TCK] 									-period $PAD_cpu_jtag_clock_period 			-waveform [list 0 [expr $PAD_cpu_jtag_clock_period/2.0]] -name jtag_TCK
create_clock [get_ports serial_tl_0_clock_in] 									-period $PAD_cpu_serial_clock_period 			-waveform [list 0 [expr $PAD_cpu_serial_clock_period/2.0]] -name serial_tl_0_clock_in
create_clock [get_pins  {fake_pll/PLL6GS28/O_PLL_CLKDIV}] 	-period $clk_pll_cpu_period 			-waveform [list 0 [expr $clk_pll_cpu_period/2.0]] 	-name clk_pll_cpu

# CPU
create_generated_clock 	-name cpu_clk_o_1 \
                        -source [get_ports clock] \
                        [get_pins {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/u_clock_or2/Z}] \
                        -master_clock [get_clocks clock] -divide_by 1 -add

create_generated_clock 	-name cpu_clk_o_2 \
                        -source [get_pins  {fake_pll/PLL6GS28/O_PLL_CLKDIV}] \
                        [get_pins {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/u_clock_or2/Z}] \
                         -master_clock [get_clocks clk_pll_cpu] -divide_by 1 -add





##### 时钟约束设置 - 使用参数 ###########################################################

# Uncertainty设置 (period的30%)
# set_clock_uncertainty [expr $PAD_clk_FPGA_w_period * 0.3]       [get_clocks PAD_clk_FPGA_w]             
# set_clock_uncertainty [expr $PAD_clk_FPGA_cim_period * 0.3]     [get_clocks PAD_clk_FPGA_cim]           
# set_clock_uncertainty [expr $PAD_top_clk_FPGA_test_period * 0.3] [get_clocks PAD_top_clk_FPGA_test]      
# set_clock_uncertainty [expr $clk_pll_w_period * 0.3]            [get_clocks clk_pll_w]                  
# set_clock_uncertainty [expr $clk_pll_cim_period * 0.3]          [get_clocks clk_pll_cim]
set_clock_uncertainty [expr $PAD_cpu_clock_period * 0.3]        [get_clocks clock]
set_clock_uncertainty [expr $PAD_cpu_serial_clock_period * 0.3]        [get_clocks serial_tl_0_clock_in]
set_clock_uncertainty [expr $PAD_cpu_jtag_clock_period * 0.3]        [get_clocks jtag_TCK]
set_clock_uncertainty [expr $clk_pll_cpu_period * 0.3]          [get_clocks clk_pll_cpu]

# Transition设置 (period的10%)
# set_clock_transition  [expr $PAD_clk_FPGA_w_period * 0.1]       [get_clocks PAD_clk_FPGA_w]            
# set_clock_transition  [expr $PAD_clk_FPGA_cim_period * 0.1]     [get_clocks PAD_clk_FPGA_cim]          
# set_clock_transition  [expr $PAD_top_clk_FPGA_test_period * 0.1] [get_clocks PAD_top_clk_FPGA_test]     
# set_clock_transition  [expr $clk_pll_w_period * 0.1]            [get_clocks clk_pll_w]                 
# set_clock_transition  [expr $clk_pll_cim_period * 0.1]          [get_clocks clk_pll_cim]
set_clock_transition  [expr $PAD_cpu_clock_period * 0.1]        [get_clocks clock]
set_clock_transition [expr $PAD_cpu_serial_clock_period * 0.1]        [get_clocks serial_tl_0_clock_in]
set_clock_transition [expr $PAD_cpu_jtag_clock_period * 0.1]        [get_clocks jtag_TCK]
set_clock_transition  [expr $clk_pll_cpu_period * 0.1]          [get_clocks clk_pll_cpu]

# Input/Output Delay设置 (period的70%)
# set_input_delay   [expr $PAD_clk_FPGA_w_period * 0.7]       -clock [get_clocks PAD_clk_FPGA_w] $data_inputs         
# set_output_delay  [expr $PAD_clk_FPGA_w_period * 0.7]       -clock [get_clocks PAD_clk_FPGA_w] $data_outputs        

# set_input_delay   [expr $PAD_clk_FPGA_cim_period * 0.7]     -clock [get_clocks PAD_clk_FPGA_cim] $data_inputs       
# set_output_delay  [expr $PAD_clk_FPGA_cim_period * 0.7]     -clock [get_clocks PAD_clk_FPGA_cim] $data_outputs      

# set_input_delay   [expr $PAD_top_clk_FPGA_test_period * 0.7] -clock [get_clocks PAD_top_clk_FPGA_test] $data_inputs  
# set_output_delay  [expr $PAD_top_clk_FPGA_test_period * 0.7] -clock [get_clocks PAD_top_clk_FPGA_test] $data_outputs 

# set_input_delay   [expr $clk_pll_w_period * 0.7]            -clock [get_clocks clk_pll_w] $data_inputs              
# set_output_delay  [expr $clk_pll_w_period * 0.7]            -clock [get_clocks clk_pll_w] $data_outputs             

# set_input_delay   [expr $clk_pll_cim_period * 0.7]          -clock [get_clocks clk_pll_cim] $data_inputs            
# set_output_delay  [expr $clk_pll_cim_period * 0.7]          -clock [get_clocks clk_pll_cim] $data_outputs

set_input_delay   [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks clock] $data_inputs            
set_output_delay  [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks clock] $data_outputs

set_input_delay   [expr $PAD_cpu_serial_clock_period * 0.7]        -clock [get_clocks serial_tl_0_clock_in] $cpu_serdess_inputs            
set_output_delay  [expr $PAD_cpu_serial_clock_period * 0.7]        -clock [get_clocks serial_tl_0_clock_in] $cpu_serdess_outputs

set_input_delay   [expr $PAD_cpu_jtag_clock_period * 0.7]        -clock [get_clocks jtag_TCK] $cpu_jtag_inputs            
set_output_delay  [expr $PAD_cpu_jtag_clock_period * 0.7]        -clock [get_clocks jtag_TCK] $cpu_jtag_outputs

set_input_delay   [expr $clk_pll_cpu_period * 0.7]          -clock [get_clocks clk_pll_cpu] $data_inputs            
set_output_delay  [expr $clk_pll_cpu_period * 0.7]          -clock [get_clocks clk_pll_cpu] $data_outputs


set_clock_groups -name cpu_clk_o_pe -physically_exclusive \
	-group [get_clocks cpu_clk_o_1] \
	-group [get_clocks cpu_clk_o_2]

set_clock_groups -name cpu_clk_aa -asynchronous \
	-group [get_clocks clock] \
	-group [get_clocks "clk_pll_cpu cpu_clk_o_2"]

set_clock_groups -name top_clk_asyn_aa -asynchronous \
    -group [get_clocks "cpu_clk_o_1 cpu_clk_o_2"] \
    -group [get_clocks "jtag_TCK"] \
	-group [get_clocks "serial_tl_0_clock_in"]

set_fix_multiple_port_nets -all -buffer_constants

set ALL_EX_OUT          [remove_from_collection [current_design] [all_outputs]]
set ALL_EX_OUT_IN       [remove_from_collection $ALL_EX_OUT [all_inputs]]
set_max_transition      $MAX_TRAN               $ALL_EX_OUT_IN 
set_max_fanout          $MAX_FANOUT             $ALL_EX_OUT_IN
#set_max_capacitance     $MAX_CAP                $ALL_EX_OUT_IN

# set_ideal_network  [all_clocks]
#   [all_clocks]
set_ideal_network [get_ports clock] 							
set_ideal_network [get_ports jtag_TCK] 						
set_ideal_network [get_ports serial_tl_0_clock_in] 			
set_ideal_network [get_pins  {fake_pll/PLL6GS28/O_PLL_CLKDIV}]
set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/u_clock_or2/Z}]
# set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/ClockOr2/clockOut}]
# # set_ideal_network [get_pins  {system/chipyard_prcictrl_domain/clockSelector/auto_clock_out_member_allClocks_uncore_clock}]
# set_optimize_registers [get_designs FPU] true
# set_optimize_registers [get_designs BranchPredictor] true
# set_optimize_registers [get_designs PipelinedMulUnit] true

# set_optimize_registers [get_designs MulDiv_1] true
# set_optimize_registers [get_designs MulDiv_3] true