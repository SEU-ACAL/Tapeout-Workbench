# Preliminary automatic SP018RP pad ring for implementation bring-up.
# A package-qualified pad order may replace this script through FLOORPLAN_DEF.
set pr_signal_pads {}
foreach pad_cell $::PR_SIGNAL_PAD_CELLS {
  foreach inst [dbGet -p2 top.insts.cell.name $pad_cell] {
    lappend pr_signal_pads [dbGet $inst.name]
  }
}
if {[llength $pr_signal_pads] != 28} {
  error "Expected 28 SP018RP signal pads, found [llength $pr_signal_pads]: $pr_signal_pads"
}

set pr_xll [dbGet top.fPlan.box_llx]
set pr_yll [dbGet top.fPlan.box_lly]
set pr_xur [dbGet top.fPlan.box_urx]
set pr_yur [dbGet top.fPlan.box_ury]
set pr_pad_pitch 60.0
set pr_pad_depth 121.87
set pr_side_specs [list \
  [list bottom R0   $pr_xll $pr_yll $pr_xur $pr_yll] \
  [list right  R90  [expr {$pr_xur - $pr_pad_depth}] $pr_yll [expr {$pr_xur - $pr_pad_depth}] $pr_yur] \
  [list top    R180 $pr_xur [expr {$pr_yur - $pr_pad_depth}] $pr_xll [expr {$pr_yur - $pr_pad_depth}]] \
  [list left   R270 $pr_xll $pr_yur $pr_xll $pr_yll]]

set pr_signal_index 0
set pr_supply_index 0
foreach side_spec $pr_side_specs {
  lassign $side_spec side orient x0 y0 x1 y1
  set pr_side_pads [lrange $pr_signal_pads $pr_signal_index [expr {$pr_signal_index + 6}]]
  incr pr_signal_index 7

  foreach power_cell $::PR_POWER_PAD_CELLS {
    set power_inst PR_${power_cell}_${side}
    addInst -cell $power_cell -inst $power_inst
    lappend pr_side_pads $power_inst
  }

  set pr_count [llength $pr_side_pads]
  for {set index 0} {$index < $pr_count} {incr index} {
    set inst [lindex $pr_side_pads $index]
    set fraction [expr {double($index + 1) / double($pr_count + 1)}]
    if {$side in {bottom top}} {
      set x [expr {$x0 + ($x1 - $x0) * $fraction}]
      set y $y0
    } else {
      set x $x0
      set y [expr {$y0 + ($y1 - $y0) * $fraction}]
    }
    placeInstance $inst $x $y $orient -fixed
  }
}
puts "PR_PAD_RING mode=automatic signal_pads=[llength $pr_signal_pads] power_pads=[expr {[llength $::PR_POWER_PAD_CELLS] * 4}]"
