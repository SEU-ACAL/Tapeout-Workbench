if {![info exists CORNER]} { set CORNER ss }
switch -- $CORNER {
    ss {
        set SRAM_CORNER ssg0p81v125c
        set TECH_CORNER ssg0p81v125c
        set TECH_STD_CELL_DB /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db
    }
    tt {
        set SRAM_CORNER tt0p8v0p9v85c
        set TECH_CORNER tt0p8v0p9v85c
        set TECH_STD_CELL_DB /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvttt0p8v0p9v85c_ccs.db
    }
    ff {
        set SRAM_CORNER ffg1p05v0p99vm40c
        set TECH_CORNER ffg1p05v0p99vm40c
        set TECH_STD_CELL_DB /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtffg1p05v0p99vm40c_ccs.db
    }
    default { error "Unsupported TSMC28 corner '$CORNER'; use ss, tt, or ff" }
}
set SRAM_ROOT /data2/TSMC28/Memory/SRAM
set SRAM_WRITE_ENABLE_PORT WEB
set target_library [list $TECH_STD_CELL_DB]
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/NLDM/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/NLDM/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/NLDM/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/NLDM/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/NLDM/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/NLDM/chipyard_sram_512x32_$SRAM_CORNER.db]
