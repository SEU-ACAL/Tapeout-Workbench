define_design_lib work -path ./elab
history keep 500
set enable_page_mode false
set sh_enable_page_mode false
set compile_seqmap_identify_shift_registers false
set compile_seqmap_identify_shift_registers_with_synchronous_logic false
set timing_enable_multiple_clocks_per_reg true
set SOURCE_CODE_HOME /data1/GB/chipyard/soc-generator/sims/vcs/generated-src/chipyard.harness.TestHarness.TapeoutConfig


set SRAM_ROOT /data2/TSMC28/Memory/SRAM
set SRAM_CORNER ssg0p81v125c
set SRAM_WRAPPER_FILE $SOURCE_CODE_HOME/gen-collateral/chipyard.harness.TestHarness.TapeoutConfig.top.mems.v

set search_path [list $SOURCE_CODE_HOME]
# 使用7t ss corner
set target_library   "/data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db"

# set target_library   " scc28nhkcp_hdc35p140_rvt_ffg_v0p99_0c_ccs.db \
# 					"

                     

#set synthetic_library ""
set synthetic_library "/data2/tools/syn/R-2020.09-SP5/libraries/syn/dw_foundation.sldb \
                        /data2/tools/syn/R-2020.09-SP5/libraries/syn/standard.sldb"
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/NLDM/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/NLDM/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/NLDM/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/NLDM/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/NLDM/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/NLDM/chipyard_sram_512x32_$SRAM_CORNER.db]

foreach sram_db $sram_link_library {
    if {![file exists $sram_db]} {
        error "Missing SRAM timing library: $sram_db"
    }
}

set link_library      " * \
                        $target_library \
                        $sram_link_library \
                        $synthetic_library"
