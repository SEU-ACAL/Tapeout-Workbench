set TOP_MODULE  multiplier_pipe3

set_host_options -max_cores 16
set compile_enable_register_merging    true
set compile_seqmap_propagate_constants true
set verilogout_no_tri   "true"
set verilogout_equation "false"
set mv_default_level_shifter_voltage_range_infinity true
source -e -v ./scripts/dc_setup.tcl
#set_level_shifter_cell  LVLLH  -cell_type LH -std_cell_main_rail_pg_pin VDDI
# set_level_shifter_cell  LVLLH -cell_type LH -output_signal_level VDD  -input_signal_level VDDI -std_cell_main_rail_pg_pin VDDI
set change_names_dont_change_bus_members      true
set compile_disable_hierarchical_inverter_opt true
set auto_insert_level_shifters_on_clocks      all
set auto_insert_level_shifters true
# set hdlin_verilog_defines [list "SYNTHESIS"]
# set file_handle [open "/home/gb123/EDA_DOCKER/ic_workbench/0-RTL/CPU/1/filelist.f" r]

# set MY_HDL_FILES [split [read $file_handle] "\n"]

# close $file_handle

set ALL_HDL_FILES  /data1/GB/ic_workbench/0-RTL/multi.v

set hdlin_verilog_defines [list "SYNTHESIS"]

analyze -format sverilog $ALL_HDL_FILES  -define DC_SYN
elaborate       $TOP_MODULE
current_design  $TOP_MODULE
link

###
source -e -v ./scripts/constraint_core.tcl

# set my_net [get_nets -of_objects [get_pins {system/chipyard_prcictrl_domain/clockSelector/allClocks_uncore_clkmux/io_clockOut}]]
# if { $my_net != "" } {
#     set_ideal_network $my_net
# }
# puts "Found  net: $my_net"
report_clocks 
check_design > ./rpt/check_deisgn.rpt
check_timing  > ./rpt/check_timing.rpt

# set_clock_gating_style \
#                      -setup 0.3 \
#                      -hold 0 \
#                      -pos integrated \
#                      -neg integrated \
#                      -max_fanout 32 \
#                      -control_point before \
#                      -control_signal scan_enable

# insert_clock_gating



source -e -v ./scripts/set_dont_touch_cell.tcl
source -e -v ./scripts/set_false_path.tcl
source -e -v ./scripts/set_dont_use.tcl


check_timing
###set_max_area 0
#
source -e -v ./scripts/operation_conditions.tcl
#set upf_create_implicit_supply_sets false
#load_upf      ./scripts/KWS_20190426.upf
#set_voltage -object_list {VDD_top_net  } 0.9
#set_voltage -object_list {VDD_core_net  } 0.5
#set_voltage -object_list VSS_top_net 0

compile_ultra -area_high_effort_script -no_autoungroup  -no_boundary_optimization  
##compile_ultra -timing_high_effort_script -no_autoungroup  -no_boundary_optimization -incremental

set_fix_multiple_port_nets -all -buffer_constants
set_fix_multiple_port_nets -all -buffer_constants [all_designs]

set verilogout_no_tri   "true"
set verilogout_equation "false"


#define_name_rules  myrule -type net -allowed "0-9" -first_restricted "_ 0-9 N" -replacement_char "0-9" -prefix "n"
#change_names -rules myrule -verbose



change_names -hier -rules verilog


write_sdc                                ./outputs/$data/${TOP_MODULE}.sdc
write -format ddc     -hierarchy -output ./outputs/$data/${TOP_MODULE}.ddc
write -format verilog -hierarchy -output ./outputs/$data/${TOP_MODULE}.v
#save_upf                                 ./outputs/$data/${TOP_MODULE}.upf

#save_upf                                               ./outputs/$data/${TOP_MODULE}.upf
write_link_library -out                               ./outputs/$data/link_library.txt
# report_power_domain [get_power_domains * -hierarchical] > ./rpt/$data/${TOP_MODULE}_final_power_domain.rpt
# report_supply_net [get_supply_nets *]                     > ./rpt/$data/${TOP_MODULE}_final_supple_net.rpt
# report_level_shifter -domain [get_power_domains * -hierarchical] > ./rpt/$data/${TOP_MODULE}_final_level_shifter.rpt
# report_pst                                                   > ./rpt/$data/${TOP_MODULE}_final_pst.rpt
#########################################################



#############################################################################333333333
report_constraint -all_vio > ./rpt/$data/constrant.rpt
report_area   -hier        > ./rpt/$data/area.rpt
report_constraint  -all_violators                         > ./rpt/$data/${TOP_MODULE}_constraint_all_violators.rpt
check_timing                                              > ./rpt/$data/${TOP_MODULE}_check_timing_final.rpt
report_timing_requirements                                > ./rpt/$data/${TOP_MODULE}_report_timing_requirements.rpt
report_timing -transition_time -nets -attributes -nosplit > ./rpt/$data/${TOP_MODULE}_mapped_timing.rpt
report_area -physical -nosplit -hierarchy                 > ./rpt/$data/${TOP_MODULE}_mapped_area.rpt
report_power -hierarchy                                   > ./rpt/$data/${TOP_MODULE}_power.rpt
report_cell                                               > ./rpt/$data/${TOP_MODULE}_cell.rpt
foreach path_group {I2R R2R R2O I2O} {
    report_timing \
        -group $path_group \
        -delay max \
        -path_type full \
        -max_paths 1000 \
        -transition_time \
        -nets \
        -attributes \
        -nosplit \
        > ./rpt/$data/${TOP_MODULE}_${path_group}_setup.rpt
}

report_qor -significant_digits 4 \
      > ./rpt/$data/${TOP_MODULE}_qor.rpt
foreach path_group {I2R R2R R2O I2O} {
    report_logic_levels \
        -group $path_group \
        -max_paths 10000 \
        -max_paths_to_report 500 \
        -num_bins 20 \
        -nosplit \
        > ./rpt/$data/${TOP_MODULE}_${path_group}_logic_levels.rpt
}

report_reference                                          > ./rpt/$data/${TOP_MODULE}_ref.rpt
