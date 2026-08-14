set SRAM_ROOT /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
set SRAM_CORNER ss_1.62_125
set TECH_CORNER ss_v1p62_125c
set SRAM_WRITE_ENABLE_PORT WEN
set target_library [list \
    /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c_ccs.db]
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/chipyard_sram_512x32_$SRAM_CORNER.db]

# TapeoutConfig DC runs always link the SMIC ROM hard macros. Keep the complete
# cache filelist here, like SRAM, so DC resolves whichever S018VM macro the RTL
# instantiates without requiring a command-line selection.
set ROM_IP_ROOT /data2/smic180/rom-ip
set ROM_LIBRARY_FILELIST [file join $ROM_IP_ROOT dc-libdb rom-libs.db.f]
if {![file exists $ROM_LIBRARY_FILELIST]} {
    error "Missing SMIC180 ROM timing filelist: $ROM_LIBRARY_FILELIST; run ./scripts/prepare_rom_libs.sh --smic180-rom-cache first"
}
set rom_link_library [list]
set rom_filelist_handle [open $ROM_LIBRARY_FILELIST r]
while {[gets $rom_filelist_handle rom_db] >= 0} {
    set rom_db [string trim $rom_db]
    if {$rom_db ne "" && ![string match "#*" $rom_db]} {
        lappend rom_link_library $rom_db
    }
}
close $rom_filelist_handle
if {[llength $rom_link_library] == 0} {
    error "SMIC180 ROM timing filelist is empty: $ROM_LIBRARY_FILELIST"
}
