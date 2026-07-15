define_design_lib work -path ./elab
history keep 500
set enable_page_mode false
set sh_enable_page_mode false
set compile_seqmap_identify_shift_registers false
set compile_seqmap_identify_shift_registers_with_synchronous_logic false
set timing_enable_multiple_clocks_per_reg true



set search_path [list /home/gb123/EDA_DOCKER/ic_workbench/0-RTL/CPU/1]
# 使用12t ss corner
set target_library   "/home/gb123/.ciel/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_n40C_1v76.lib"

# set target_library   " scc28nhkcp_hdc35p140_rvt_ffg_v0p99_0c_ccs.db \
# 					"

                     

#set synthetic_library ""
set synthetic_library "/data2/tools/syn/R-2020.09-SP5/libraries/syn/dw_foundation.sldb \
                        /data2/tools/syn/R-2020.09-SP5/libraries/syn/standard.sldb"
set link_library      " * \
	           	$target_library \
                $synthetic_library"

