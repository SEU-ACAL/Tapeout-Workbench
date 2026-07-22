set SRAM_ROOT /data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722
set SRAM_CORNER ss_1.62_125
set TECH_CORNER ss_v1p08_125c
set SRAM_WRITE_ENABLE_PORT WEN
# The available standard-cell SS view is 1.08 V; S018SP's lowest SS view is
# 1.62 V. This is a worst-case timing estimate, not a voltage-consistent signoff corner.
set target_library [list \
    /data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.2v/scc018ug_uhd_rvt_ss_v1p08_125c_ccs.db]
set sram_link_library [list \
    $SRAM_ROOT/chipyard_sram_32x22/chipyard_sram_32x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x64/chipyard_sram_512x64_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x8/chipyard_sram_512x8_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x22/chipyard_sram_64x22_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_64x21/chipyard_sram_64x21_$SRAM_CORNER.db \
    $SRAM_ROOT/chipyard_sram_512x32/chipyard_sram_512x32_$SRAM_CORNER.db]
