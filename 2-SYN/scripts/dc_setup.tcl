define_design_lib work -path ./elab
history keep 500
set enable_page_mode false
set sh_enable_page_mode false
set compile_seqmap_identify_shift_registers false
set compile_seqmap_identify_shift_registers_with_synchronous_logic false
set timing_enable_multiple_clocks_per_reg true
if {![info exists SOURCE_CODE_HOME]} {
    if {![info exists CONFIG]} {
        set CONFIG chipyard.harness.TestHarness.TapeoutConfig
    }
    if {![info exists CHIPYARD_GENERATED_SRC]} {
        set CHIPYARD_GENERATED_SRC /data1/GB/chipyard/soc-generator/sims/vcs/generated-src
    }
    set SOURCE_CODE_HOME [file join $CHIPYARD_GENERATED_SRC $CONFIG]
}
if {![info exists CONFIG]} {
    set CONFIG [file tail [file normalize $SOURCE_CODE_HOME]]
}


if {![info exists TECH_CONFIG]} {
    set TECH_CONFIG tsmc28
}
set tech_setup [file join [file dirname [info script]] tech ${TECH_CONFIG}.tcl]
if {![file exists $tech_setup]} {
    error "Missing technology configuration: $tech_setup"
}
source $tech_setup
puts "Synthesis technology: $TECH_CONFIG, standard-cell corner: $TECH_CORNER, SRAM corner: $SRAM_CORNER"
if {![info exists SRAM_WRAPPER_FILE]} {
    set default_sram_wrapper [file join $SOURCE_CODE_HOME gen-collateral ${CONFIG}.top.mems.v]
    if {[file exists $default_sram_wrapper]} {
        set SRAM_WRAPPER_FILE $default_sram_wrapper
    }
}
if {[info exists SRAM_WRAPPER_FILE] && $SRAM_WRAPPER_FILE ne ""} {
    set wrapper_handle [open $SRAM_WRAPPER_FILE r]
    set wrapper_contents [read $wrapper_handle]
    close $wrapper_handle
    if {![regexp "\\.${SRAM_WRITE_ENABLE_PORT}\\(" $wrapper_contents]} {
        error "SRAM wrapper $SRAM_WRAPPER_FILE does not match technology $TECH_CONFIG; expected .${SRAM_WRITE_ENABLE_PORT}(...) ports"
    }
}

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

# Apply the selected technology after the legacy defaults above so the default
# TSMC28 flow remains unchanged while alternative technologies can override it.
source $tech_setup

if {![info exists io_link_library]} {
    set io_link_library [list]
}
if {![info exists rom_link_library]} {
    set rom_link_library [list]
}

foreach memory_db [concat $sram_link_library $rom_link_library] {
    if {![file exists $memory_db]} {
        error "Missing memory timing library: $memory_db"
    }
}

set link_library      " * \
                        $target_library \
                        $io_link_library \
                        $sram_link_library \
                        $rom_link_library \
                        $synthetic_library"
