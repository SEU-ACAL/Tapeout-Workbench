# Initial SMIC180 macro floorplan for the current ChipTop netlist.
# Coordinates are in microns and assume the 3317.23 x 3311.63 um die used by
# the 0830_1319 handoff.  This is an intentionally conservative seed; use
# congestion/timing reports to refine it before signoff.

proc pr_macro_group {name box insts} {
  if {[llength [get_db insts $insts]] != [llength $insts]} {
    error "Macro group $name contains an instance that is absent from the netlist"
  }
  createInstGroup $name -fence $box
  foreach inst $insts {
    addInstToInstGroup $name $inst
  }
}

set pr_l2_dir {}
for {set i 0} {$i < 8} {incr i} {
  lappend pr_l2_dir "system/coh_wrapper/l2/inclusive_cache_bank_sched/directory/cc_dir/cc_dir_ext/mem_0_$i"
}
set pr_l2_data {}
for {set i 0} {$i < 4} {incr i} {
  lappend pr_l2_data "system/coh_wrapper/l2/inclusive_cache_bank_sched/bankedStore/cc_banks_$i/cc_banks_0_ext/mem_0_0"
}
set pr_dc_data {}
for {set i 0} {$i < 8} {incr i} {
  lappend pr_dc_data "system/tile_prci_domain/element_reset_domain_rockettile/dcache/data/rockettile_dcache_data_arrays_0/rockettile_dcache_data_arrays_0_ext/mem_0_$i"
}
set pr_dc_tag {system/tile_prci_domain/element_reset_domain_rockettile/dcache/rockettile_dcache_tag_array_0/rockettile_dcache_tag_array_0_ext/mem_0_0}
set pr_ic_tag {system/tile_prci_domain/element_reset_domain_rockettile/frontend/icache/rockettile_icache_tag_array_0/rockettile_icache_tag_array_0_ext/mem_0_0}
set pr_ic_data {
  system/tile_prci_domain/element_reset_domain_rockettile/frontend/icache/rockettile_icache_data_arrays_0_0/rockettile_icache_data_arrays_0_0_ext/mem_0_0
  system/tile_prci_domain/element_reset_domain_rockettile/frontend/icache/rockettile_icache_data_arrays_1_0/rockettile_icache_data_arrays_0_0_ext/mem_0_0
}

# power_plan.tcl uses this exact macro set to keep vertical M6 straps out of
# macro interiors.  The macros expose long vertical M4 PG rails; M6 crossing
# those rails produces an illegal parallel overlap in this PDK.
set ::PR_PG_MACRO_INSTANCES [concat \
  $pr_l2_dir $pr_l2_data $pr_dc_data $pr_dc_tag $pr_ic_tag $pr_ic_data]

# Fence regions keep the controller/mux logic close to its memories.  The
# groups are guides for place_opt; macro locations below are hard-fixed seeds.
# Keep the directory, L2 data, and DCache fences disjoint.  Overlapping fences
# make the shared area unplaceable and were reported by checkDesign in the
# previous 10 mm run.
pr_macro_group PR_REG_L2_DIRECTORY {960 250 2050 650} $pr_l2_dir
pr_macro_group PR_REG_L2_DATA      {250 250 950 2450} $pr_l2_data
pr_macro_group PR_REG_DCACHE       {1600 700 2900 1850} [concat $pr_dc_data [list $pr_dc_tag]]
pr_macro_group PR_REG_ICACHE       {1500 2050 2900 3000} [concat $pr_ic_data [list $pr_ic_tag]]

# L2 BankedStore: vertical stack, with a channel on the right for scheduler
# and directory traffic.
set pr_l2_xy {{300 350} {300 850} {300 1350} {300 1850}}
for {set i 0} {$i < 4} {incr i} {
  lassign [lindex $pr_l2_xy $i] x y
  placeInstance [lindex $pr_l2_data $i] $x $y R0 -fixed
}

# Directory is eight 32x22 slices; keep slices in two rows and preserve bus
# ordering left-to-right within each row.
for {set i 0} {$i < 8} {incr i} {
  set row [expr {$i / 4}]
  set col [expr {$i % 4}]
  placeInstance [lindex $pr_l2_dir $i] [expr {980 + 245*$col}] [expr {280 + 190*$row}] R0 -fixed
}

# DCache data slices: 4x2 array.  R0 keeps the 512x8 macros vertical, which
# matches the tall bit-column geometry of the compiler macro.
for {set i 0} {$i < 8} {incr i} {
  set row [expr {$i / 4}]
  set col [expr {$i % 4}]
  placeInstance [lindex $pr_dc_data $i] [expr {1650 + 190*$col}] [expr {750 + 600*$row}] R0 -fixed
}
placeInstance $pr_dc_tag 2500 800 R0 -fixed

# ICache data/tag sit above the core-facing frontend logic.
placeInstance [lindex $pr_ic_data 0] 1650 2200 R0 -fixed
placeInstance [lindex $pr_ic_data 1] 2050 2200 R0 -fixed
placeInstance $pr_ic_tag 2500 2200 R0 -fixed

# ROMs are compiler macros rather than SRAM classes.  Keep the debug ROM near
# the debug/control side and the boot ROM near the system-bus side.
set pr_debug_rom [get_db insts -if {.base_cell.name == S018VM_X8Y16D64_PM}]
set pr_boot_rom [get_db insts -if {.base_cell.name == S018VM_X64Y16D64_PM}]
if {[llength $pr_debug_rom] != 1 || [llength $pr_boot_rom] != 1} {
  error "Expected one debug ROM and one boot ROM (got [llength $pr_debug_rom], [llength $pr_boot_rom])"
}
placeInstance [lindex $pr_debug_rom 0] 2650 1800 R0 -fixed
# Keep the 898 x 160 um boot ROM within the 3400 um core.  x=2800 placed its
# right edge beyond the core boundary, where it overlapped the vertical M6
# core ring and generated PG/obstruction conflicts.  x=2600 retains a 73 um
# channel to the core edge while remaining above the ICache macros.
placeInstance [lindex $pr_boot_rom 0] 2600 3000 R0 -fixed
lappend ::PR_PG_MACRO_INSTANCES [lindex $pr_debug_rom 0] [lindex $pr_boot_rom 0]

# Macro interiors cannot retain standard-cell rows.  Besides preventing later
# placement overlap, this keeps followpin special routing out of macro PG and
# signal obstructions.  This is a placement cut, not a block power ring.
foreach pr_macro_inst $::PR_PG_MACRO_INSTANCES {
  if {[string match "inst:*" $pr_macro_inst]} {
    set pr_macro_obj $pr_macro_inst
  } else {
    set pr_macro_obj [get_db insts $pr_macro_inst]
  }
  cutRow -object [get_db $pr_macro_obj .name] -halo 5
}

puts "PR_MACRO_FLOORPLAN status=pass groups=4 sram_macros=24 rom_macros=2"
