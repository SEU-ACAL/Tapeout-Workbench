if {![info exists CORNER]} { set CORNER ss }
switch -- $CORNER {
    ss {
        set SRAM_CORNER ss_1.62_125
        set TECH_CORNER ss_v1p62_125c
        set TECH_STD_CELL_DB /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ss_v1p62_125c_ccs.db
        set TECH_IO_DB /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_max.db
        set TECH_ROM_CORNER ss_1.62_125
    }
    tt {
        set SRAM_CORNER tt_1.8_25
        set TECH_CORNER tt_v1p8_25c
        set TECH_STD_CELL_DB /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_tt_v1p8_25c_ccs.db
        set TECH_IO_DB /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_typ.db
        set TECH_ROM_CORNER tt_1.8_25
    }
    ff {
        set SRAM_CORNER ff_1.98_-40
        set TECH_CORNER ff_v1p98_-40c
        set TECH_STD_CELL_DB /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v/scc018ug_uhd_rvt_ff_v1p98_-40c_ccs.db
        set TECH_IO_DB /data2/smic180/SP018RP_V1p0b/syn/1p8v/SP018RP_V1p0_min.db
        set TECH_ROM_CORNER ff_1.98_-40
    }
    default { error "Unsupported SMIC180 corner '$CORNER'; use ss, tt, or ff" }
}
set SRAM_ROOT /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
set SRAM_WRITE_ENABLE_PORT WEN
set ROM_ROOT /data2/smic180/rom-ip
set rom_link_library [list \
    $ROM_ROOT/bootrom/S018VM_X64Y16D64_PM_${TECH_ROM_CORNER}.db \
    $ROM_ROOT/debugrom/S018VM_X8Y16D64_PM_${TECH_ROM_CORNER}.db]
set target_library [list $TECH_STD_CELL_DB]
# SP018RP max corresponds to the 1.62 V, 125 C core signoff corner.  Keep it
# link-only so regular logic is never mapped into pad cells.
set io_link_library [list \
    $TECH_IO_DB]
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_32x128/chipyard_sram_32x128_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_1024x8/chipyard_sram_1024x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x128/chipyard_sram_64x128_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/chipyard_sram_512x32_$SRAM_CORNER.db]
