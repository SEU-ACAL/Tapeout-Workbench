set work_dir [pwd]
#############################################
#             Pre Layout STA                #
#############################################
# 删除 crte 文件
foreach file [glob -nocomplain "${work_dir}/crte_*.txt"] {
    if {[catch {file delete $file} result]} {
        puts "Warning: Cannot delete $file - $result"
    } else {
        puts "Deleted: $file"
    }
}

# 删除 Synopsys .adi 文件
foreach file [glob -nocomplain "${work_dir}/Synopsys_*.adi"] {
    if {[catch {file delete $file} result]} {
        puts "Warning: Cannot delete $file - $result"
    } else {
        puts "Deleted: $file"
    }
}

# 删除 Synopsys stack trace 文件
foreach file [glob -nocomplain "${work_dir}/Synopsys_stack_trace_*.txt"] {
    if {[catch {file delete $file} result]} {
        puts "Warning: Cannot delete $file - $result"
    } else {
        puts "Deleted: $file"
    }
}
puts "=== Cleanup complete ==="
set is_si_enabled true


source -e -v ./scripts/pt_setup.tcl
file copy -force ./scripts/pt_setup.tcl ./rpt/${run_date}

set top_design shift_reg
set dc_date 0215_1436

source -e -v "../2-SYN/outputs/${dc_date}/link_library.txt"
read_verilog "../2-SYN/outputs/${dc_date}/${top_design}.v"
file copy -force ../2-SYN/outputs/${dc_date}/${top_design}.v  ./rpt/${run_date}

current_design $top_design
link

source -e -v "../2-SYN/scripts/set_dont_use.tcl"
source -e -v "../2-SYN/outputs/${dc_date}/${top_design}.sdc"

source -e -v ./scripts/operation_conditions.tcl



set_propagated_clock [all_clocks]


set timing_disable_clock_gating_checks false
set timing_report_unconstrained_paths true


group_path -name REGOUT -to [all_outputs]
group_path -name REGIN -from [all_inputs]
group_path -name FEEDTHROUGH -from [all_inputs] -to [all_outputs]


update_timing -full
check_timing -verbose > ./rpt/${run_date}/check_timing.report

write_sdf -version 3.0 -context verilog \
          -no_edge -input_port_nets -output_port_nets \
          -include {SETUPHOLD RECREM} -exclude {checkpins no_condelse} \
           ./outputs/${run_date}/${top_design}_no_hold.sdf


report_timing -delay max -max_paths 10000 -path_type full_clock_expanded -nosplit -slack_lesser_than 400 -voltage -sort_by slack -significant_digits 4    > ./rpt/${run_date}/timing_max_path.rpt
report_timing -delay min -max_paths 10000 -path_type full_clock_expanded -nosplit -slack_lesser_than 400 -voltage -sort_by slack -significant_digits 4    > ./rpt/${run_date}/timing_min_path.rpt

report_constraint -all_vio -significant_digits 4 -nosplit > ./rpt/${run_date}/all_vio.rpt


#############################################
#     set the power analysis mode           #
#############################################
#set timing_report_unconstrained_paths true
set power_enable_analysis TRUE
set power_analysis_mode time_based
set power_model_preference nlpm
set auto_wire_load_selection false
set power_clock_network_include_register_clock_pin_power false

read_verilog "../2-SYN/outputs/${dc_date}/${top_design}.v"
current_design $top_design
link

set_wire_load_mode top
#set_wire_load_model      -name zero [current_design]
set auto_wire_load_selection true

# load_upf $UPF
source -e -v "../2-SYN/outputs/${dc_date}/${top_design}.sdc"
# all nn
read_vcd -time {0 70} "../3-Pre_PR_NETSIM/${top_design}.fsdb"  -strip_path "tb_shift_reg/dut"


################################################
#    analyze   power                           #
################################################
check_power
set_power_analysis_options  -waveform_interval 1 -waveform_format fsdb -waveform_output ./rpt/${run_date}/${top_design} -include top 
update_power
report_power -hierarchy -levels 3 > ./rpt/${run_date}/${top_design}_hie.rpt
report_power -verbose > ./rpt/${run_date}/${top_design}_total.rpt

report_power -hierarchy -levels 2 -sort_by total_power  > ./rpt/${run_date}/${top_design}_hie_level2_sort.rpt
report_power -hierarchy -levels 3 -sort_by total_power  > ./rpt/${run_date}/${top_design}_hie_level3_sort.rpt
report_power -hierarchy -levels 4 -sort_by total_power  > ./rpt/${run_date}/${top_design}_hie_level4_sort.rpt
report_power -hierarchy -levels 5 -sort_by total_power  > ./rpt/${run_date}/${top_design}_hie_level5_sort.rpt

report_clock_gate_savings -hierarchical -sequential > ./rpt/${run_date}/${top_design}_clock_gate_savings.rpt

#file copy -force mlc_${run_date}.out newPower.out
file copy -force ./rpt/${run_date}/${top_design}_hie.rpt new_hie_power.rpt
file copy -force ./rpt/${run_date}/${top_design}_total.rpt new_total_power.rpt