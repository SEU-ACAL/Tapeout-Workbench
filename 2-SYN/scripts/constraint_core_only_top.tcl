set     CLK_SOURCE_LATENCY  	 1
set     CLK_NETWORK_LATENCY 	 1
set     OUT_LOAD                 2

set     MAX_FANOUT               32
set     MAX_CAP                  1
set     MAX_TRAN                 2
##### 时钟周期参数定义 ###########################################################
set PAD_clk_FPGA_w_period           2
set PAD_clk_FPGA_cim_period         4
set PAD_top_clk_FPGA_test_period    3
set clk_pll_w_period                1
set clk_pll_cim_period              2
set PAD_cpu_clock_period            40
set clk_pll_cpu_period              2

# set clk_jtag_cpu_period             100
# set clk_serdess_cpu_period          20


##### Source Clock Definition ###########################################################

#set clk_ports		 [get_ports {PAD_clk_FPGA_w PAD_clk_FPGA_cim PAD_top_clk_FPGA_test PAD_osc_in PAD_cpu_clock PAD_npu_rstn_FPGA}]
set clk_ports		 [get_ports {PAD_clk_FPGA_w PAD_clk_FPGA_cim PAD_top_clk_FPGA_test PAD_osc_in}]
set data_inputs 	 [remove_from_collection [all_inputs]  $clk_ports]
set data_outputs	 [remove_from_collection [all_outputs] $clk_ports]

create_clock [get_ports PAD_clk_FPGA_w] 								-period $PAD_clk_FPGA_w_period 			-waveform [list 0 [expr $PAD_clk_FPGA_w_period/2.0]] 			-name PAD_clk_FPGA_w
create_clock [get_ports PAD_clk_FPGA_cim] 								-period $PAD_clk_FPGA_cim_period 		-waveform [list 0 [expr $PAD_clk_FPGA_cim_period/2.0]] 			-name PAD_clk_FPGA_cim 
create_clock [get_ports PAD_top_clk_FPGA_test] 							-period $PAD_top_clk_FPGA_test_period 	-waveform [list 0 [expr $PAD_top_clk_FPGA_test_period/2.0]] 	-name PAD_top_clk_FPGA_test 

create_clock [get_pins  {PLL6GS28_inst/O_PLL_CLKDIV}] 					-period $clk_pll_w_period 				-waveform [list 0 [expr $clk_pll_w_period/2.0]] 	-name clk_pll_w
create_clock [get_pins  {PLL6GS28_inst/O_PLL_CLK_QP}] 					-period $clk_pll_cim_period 			-waveform [list 0 [expr $clk_pll_cim_period/2.0]] 	-name clk_pll_cim

# create_clock [get_ports PAD_cpu_jtag_TCK]             -period $clk_jtag_cpu_period 			-waveform [list 0 [expr $clk_jtag_cpu_period/2.0]] -name PAD_cpu_jtag_TCK
# create_clock [get_ports PAD_cpu_serial_tl_0_clock_in] -period $clk_serdess_cpu_period   -waveform [list 0 [expr $clk_serdess_cpu_period/2.0]] -name PAD_cpu_serial_tl_0_clock_in


# create_clock [get_ports PAD_cpu_clock] 									-period $PAD_cpu_clock_period 			-waveform [list 0 [expr $PAD_cpu_clock_period/2.0]] -name PAD_cpu_clock
# create_clock [get_pins  {ChipTop_inst/fake_pll/PLL6GS28/O_PLL_CLKDIV}] 	-period $clk_pll_cpu_period 			-waveform [list 0 [expr $clk_pll_cpu_period/2.0]] 	-name clk_pll_cpu

# CPU
# create_generated_clock 	-name cpu_clk_o_1 \
#                         -source [get_ports PAD_cpu_clock] \
#                         [get_pins {ChipTop_inst/system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/io_clockOut}] \
#                         -master_clock [get_clocks PAD_cpu_clock] -divide_by 1 -add

# create_generated_clock 	-name cpu_clk_o_2 \
#                         -source [get_pins  {ChipTop_inst/fake_pll/PLL6GS28/O_PLL_CLKDIV}] \
#                         [get_pins {ChipTop_inst/system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/io_clockOut}] \
#                          -master_clock [get_clocks clk_pll_cpu] -divide_by 1 -add




# NPU
# create_generated_clock 	-name npu_clk_csr_1 \
#                         -source [get_ports PAD_clk_FPGA_w] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_CSR}] \
#                         -master_clock [get_clocks PAD_clk_FPGA_w] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_csr_2 \
#                         -source [get_ports PAD_cpu_clock] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_CSR}] \
#                         -master_clock [get_clocks PAD_cpu_clock] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_csr_3 \
#                         -source [get_pins  {ChipTop_inst/fake_pll/PLL6GS28/O_PLL_CLKDIV}] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_CSR}] \
#                          -master_clock [get_clocks clk_pll_cpu] -divide_by 1 -add



# create_generated_clock 	-name npu_clk_w_1 \
#                         -source [get_pins  {PLL6GS28_inst/O_PLL_CLKDIV}] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_w}] \
#                         -master_clock [get_clocks clk_pll_w] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_w_2 \
#                         -source [get_ports PAD_clk_FPGA_w] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_w}] \
#                         -master_clock [get_clocks PAD_clk_FPGA_w] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_w_3 \
#                         -source [get_ports PAD_cpu_clock] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_w}] \
#                         -master_clock [get_clocks PAD_cpu_clock] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_w_4 \
#                         -source [get_pins  {ChipTop_inst/fake_pll/PLL6GS28/O_PLL_CLKDIV}] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_w}] \
#                          -master_clock [get_clocks clk_pll_cpu] -divide_by 1 -add



# create_generated_clock 	-name npu_clk_cim_1 \
#                         -source [get_ports PAD_clk_FPGA_cim] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_cim}] \
#                         -master_clock [get_clocks PAD_clk_FPGA_cim] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_cim_2 \
#                         -source [get_pins  {PLL6GS28_inst/O_PLL_CLK_QP}] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_cim}] \
#                         -master_clock [get_clocks clk_pll_cim] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_cim_3 \
#                         -source [get_ports PAD_clk_FPGA_w] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_cim}] \
#                         -master_clock [get_clocks PAD_clk_FPGA_w] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_cim_4 \
#                         -source [get_ports PAD_cpu_clock] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_cim}] \
#                         -master_clock [get_clocks PAD_cpu_clock] -divide_by 1 -add

# create_generated_clock 	-name npu_clk_cim_5 \
#                         -source [get_pins  {ChipTop_inst/fake_pll/PLL6GS28/O_PLL_CLKDIV}] \
#                         [get_pins {ChipTop_inst/system/device/npuBlackBox/u_TEST_MODE_bridge/u_clk_selector/clk_cim}] \
#                          -master_clock [get_clocks clk_pll_cpu] -divide_by 1 -add



# TOP
create_generated_clock 	-name top_clk_1 \
                          -source [get_ports PAD_clk_FPGA_w] \
                          [get_pins {CLKMUX2V12_inst/Z}] \
                        -master_clock [get_clocks PAD_clk_FPGA_w] -divide_by 1 -add

create_generated_clock 	-name top_clk_2 \
                          -source [get_pins {PLL6GS28_inst/O_PLL_CLKDIV}] \
                          [get_pins {CLKMUX2V12_inst/Z}] \
                          -master_clock [get_clocks clk_pll_w] -divide_by 1 -add

##### 时钟约束设置 - 使用参数 ###########################################################

# Uncertainty设置 (period的30%)
set_clock_uncertainty [expr $PAD_clk_FPGA_w_period * 0.3]       [get_clocks PAD_clk_FPGA_w]             
set_clock_uncertainty [expr $PAD_clk_FPGA_cim_period * 0.3]     [get_clocks PAD_clk_FPGA_cim]           
set_clock_uncertainty [expr $PAD_top_clk_FPGA_test_period * 0.3] [get_clocks PAD_top_clk_FPGA_test]      
set_clock_uncertainty [expr $clk_pll_w_period * 0.3]            [get_clocks clk_pll_w]                  
set_clock_uncertainty [expr $clk_pll_cim_period * 0.3]          [get_clocks clk_pll_cim]
# set_clock_uncertainty [expr $PAD_cpu_clock_period * 0.3]        [get_clocks PAD_cpu_clock]
# set_clock_uncertainty [expr $clk_pll_cpu_period * 0.3]          [get_clocks clk_pll_cpu]

# Transition设置 (period的10%)
set_clock_transition  [expr $PAD_clk_FPGA_w_period * 0.1]       [get_clocks PAD_clk_FPGA_w]            
set_clock_transition  [expr $PAD_clk_FPGA_cim_period * 0.1]     [get_clocks PAD_clk_FPGA_cim]          
set_clock_transition  [expr $PAD_top_clk_FPGA_test_period * 0.1] [get_clocks PAD_top_clk_FPGA_test]     
set_clock_transition  [expr $clk_pll_w_period * 0.1]            [get_clocks clk_pll_w]                 
set_clock_transition  [expr $clk_pll_cim_period * 0.1]          [get_clocks clk_pll_cim]
# set_clock_transition  [expr $PAD_cpu_clock_period * 0.1]        [get_clocks PAD_cpu_clock]
# set_clock_transition  [expr $clk_pll_cpu_period * 0.1]          [get_clocks clk_pll_cpu]

# Input/Output Delay设置 (period的70%)
set_input_delay  -max [expr $PAD_clk_FPGA_w_period * 0.7]       -clock [get_clocks PAD_clk_FPGA_w] $data_inputs         
set_output_delay -max [expr $PAD_clk_FPGA_w_period * 0.7]       -clock [get_clocks PAD_clk_FPGA_w] $data_outputs        

set_input_delay  -max [expr $PAD_clk_FPGA_cim_period * 0.7]     -clock [get_clocks PAD_clk_FPGA_cim] $data_inputs       
set_output_delay -max [expr $PAD_clk_FPGA_cim_period * 0.7]     -clock [get_clocks PAD_clk_FPGA_cim] $data_outputs      

set_input_delay  -max [expr $PAD_top_clk_FPGA_test_period * 0.7] -clock [get_clocks PAD_top_clk_FPGA_test] $data_inputs  
set_output_delay -max [expr $PAD_top_clk_FPGA_test_period * 0.7] -clock [get_clocks PAD_top_clk_FPGA_test] $data_outputs 

set_input_delay  -max [expr $clk_pll_w_period * 0.7]            -clock [get_clocks clk_pll_w] $data_inputs              
set_output_delay -max [expr $clk_pll_w_period * 0.7]            -clock [get_clocks clk_pll_w] $data_outputs             

set_input_delay  -max [expr $clk_pll_cim_period * 0.7]          -clock [get_clocks clk_pll_cim] $data_inputs            
set_output_delay -max [expr $clk_pll_cim_period * 0.7]          -clock [get_clocks clk_pll_cim] $data_outputs

# set_input_delay  -max [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks PAD_cpu_clock] $data_inputs            
# set_output_delay -max [expr $PAD_cpu_clock_period * 0.7]        -clock [get_clocks PAD_cpu_clock] $data_outputs

# set_input_delay  -max [expr $clk_pll_cpu_period * 0.7]          -clock [get_clocks clk_pll_cpu] $data_inputs            
# set_output_delay -max [expr $clk_pll_cpu_period * 0.7]          -clock [get_clocks clk_pll_cpu] $data_outputs

# set_clock_groups -name cpu_clk_o_pe -physically_exclusive \
# 	-group [get_clocks cpu_clk_o_1] \
# 	-group [get_clocks cpu_clk_o_2]

# set_clock_groups -name npu_clk_csr_pe -physically_exclusive \
# 	-group [get_clocks npu_clk_csr_1] \
# 	-group [get_clocks npu_clk_csr_2] \
# 	-group [get_clocks npu_clk_csr_3]

# set_clock_groups -name npu_clk_w_pe -physically_exclusive \
# 	-group [get_clocks npu_clk_w_1] \
# 	-group [get_clocks npu_clk_w_2] \
# 	-group [get_clocks npu_clk_w_3] \
# 	-group [get_clocks npu_clk_w_4]

# set_clock_groups -name npu_clk_cim_pe -physically_exclusive \
# 	-group [get_clocks npu_clk_cim_1] \
# 	-group [get_clocks npu_clk_cim_2] \
# 	-group [get_clocks npu_clk_cim_3] \
# 	-group [get_clocks npu_clk_cim_4] \
# 	-group [get_clocks npu_clk_cim_5]

set_clock_groups -name top_clk_pe -physically_exclusive \
	-group [get_clocks top_clk_1] \
	-group [get_clocks top_clk_2]


# set_clock_groups -name npu_clk_asyn -asynchronous \
#     -group [get_clocks "npu_clk_csr_1 npu_clk_csr_2 npu_clk_csr_3"] \
#     -group [get_clocks "npu_clk_w_1   npu_clk_w_2   npu_clk_w_3   npu_clk_w_4"] \
#     -group [get_clocks "npu_clk_cim_1 npu_clk_cim_2 npu_clk_cim_3 npu_clk_cim_4 npu_clk_cim_5"]

# set_clock_groups -name top_clk_asyn -asynchronous \
#     -group [get_clocks "top_clk_1 top_clk_2"] \
#     -group [get_clocks "PAD_top_clk_FPGA_test"]


# set cpu_jtag_inputs		   [get_ports {PAD_cpu_jtag_TMS PAD_cpu_jtag_TDI}]
# set cpu_jtag_outputs		 [get_ports {PAD_cpu_jtag_TDO}]
# set cpu_serdess_inputs	 [get_ports {PAD_cpu_serial_tl_0_in_valid PAD_cpu_serial_tl_0_in_bits_phit PAD_cpu_serial_tl_0_out_ready}]
# set cpu_serdess_outputs	 [get_ports {PAD_cpu_serial_tl_0_in_ready PAD_cpu_serial_tl_0_out_valid PAD_cpu_serial_tl_0_out_bits_phit}]


# set_input_delay  [expr $clk_jtag_cpu_period * 0.7]     -clock [get_clocks PAD_cpu_jtag_TCK] $cpu_jtag_inputs            
# set_output_delay [expr $clk_jtag_cpu_period * 0.7]     -clock [get_clocks PAD_cpu_jtag_TCK] $cpu_jtag_outputs
# set_input_delay  [expr $clk_serdess_cpu_period * 0.7]  -clock [get_clocks PAD_cpu_serial_tl_0_clock_in] $cpu_serdess_inputs            
# set_output_delay [expr $clk_serdess_cpu_period * 0.7]  -clock [get_clocks PAD_cpu_serial_tl_0_clock_in] $cpu_serdess_outputs



set_fix_multiple_port_nets -all -buffer_constants

set ALL_EX_OUT          [remove_from_collection [current_design] [all_outputs]]
set ALL_EX_OUT_IN       [remove_from_collection $ALL_EX_OUT [all_inputs]]
set_max_transition      $MAX_TRAN               $ALL_EX_OUT_IN 
set_max_fanout          $MAX_FANOUT             $ALL_EX_OUT_IN
#set_max_capacitance     $MAX_CAP                $ALL_EX_OUT_IN

set_ideal_network -no_propagate [all_clocks]
