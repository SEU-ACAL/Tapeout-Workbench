#------------------------------------------
# fm_shell -f this.tcl
#------------------------------------------
set work_dir [pwd]
set verification_auto_session on
set top_design shift_reg
set dc_date 0215_1436
# user special setting in guide mode
guide

# guide_reg_merging -design top \
#     -from u_a/u_b/c_reg \
#     -to u_a/u_b/c1_reg

# enter setup mode
setup

# set svf from syn
set_svf -append { ../2-SYN/default.svf}

source -e -v ./scripts/fm_setup.tcl
# supress error to warn, for example:
set_mismatch_message_filter -warn FMR_VLOG-091
set_mismatch_message_filter -warn FMR_ELAB-147

read_db /data2/TSMC28/logic/tcbn28hpcplusbwp12t40p140lvt_180a/AN61001_20180514/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp12t40p140lvt_180a/tcbn28hpcplusbwp12t40p140lvtssg0p81v125c.db
# read rtl as reference, and set top design
read_verilog -r ../0-RTL/CPU/shift.v

set_top r:/WORK/${top_design}

# read netlist from syn as implement, and set top design
read_verilog -i "../2-SYN/outputs/${dc_date}/${top_design}.v"
set_top i:/WORK/${top_design}

# set clock gating
set verification_clock_gate_edge_analysis true

# bypass dft, such as scan chain
# set_constant -type port r:/WORK/top/test_mode 0
# set_constant -type port i:/WORK/top/test_mode 0
# set_constant -type port r:/WORK/top/scan_en 0
# set_constant -type port i:/WORK/top/scan_en 0
# set_dont_verify_points -type port r:/WORK/top/scan_out[3]
# set_dont_verify_points -type port r:/WORK/top/scan_out[2]
# set_dont_verify_points -type port r:/WORK/top/scan_out[1]
# set_dont_verify_points -type port r:/WORK/top/scan_out[0]
# set_dont_verify_points -type port i:/WORK/top/scan_out[3]
# set_dont_verify_points -type port i:/WORK/top/scan_out[2]
# set_dont_verify_points -type port i:/WORK/top/scan_out[1]
# set_dont_verify_points -type port i:/WORK/top/scan_out[0]

# # low power setting
# load_upf -r top.upf
# load_upf -i top_mapped.upf

# match and verify
match
verify
report_failing_points

# start_gui
# exit