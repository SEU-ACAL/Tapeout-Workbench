set SRAM_ROOT /data2/TSMC28/Memory/SRAM
set SRAM_CORNER ssg0p81v125c
set TECH_CORNER ssg0p81v125c
set SRAM_WRITE_ENABLE_PORT WEB
set target_library [list \
    /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140lvt_180a/tcbn28hpcplusbwp7t40p140lvtssg0p81v125c_ccs.db]
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/NLDM/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/NLDM/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/NLDM/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/NLDM/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/NLDM/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/NLDM/chipyard_sram_512x32_$SRAM_CORNER.db]
