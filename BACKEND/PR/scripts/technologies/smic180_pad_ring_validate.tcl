# Validate the generated SP018RP pad ring immediately after loadIoFile.
# PVDD1R/PVSS1R are electrically connected by power_plan.tcl; PVDD2R/PVSS2R
# are physical ring-continuity pads and intentionally have no global-net map.
set pr_pad_ring_errors {}
set pr_all_instance_names [dbGet top.insts.name]

foreach instance [concat $::PR_CORNER_INSTANCES $::PR_POWER_PAD_INSTANCES] {
  if {[lsearch -exact $pr_all_instance_names $instance] < 0} {
    lappend pr_pad_ring_errors "missing instance $instance"
    continue
  }
  set instance_handle [dbGet -p top.insts.name $instance]
  set status [dbGet $instance_handle.pStatus]
  if {$status ni {fixed placed cover}} {
    lappend pr_pad_ring_errors "unplaced instance $instance status=$status"
  }
}

set pr_signal_count 0
foreach pad_cell $::PR_SIGNAL_PAD_CELLS {
  foreach instance [dbGet -p2 top.insts.cell.name $pad_cell] {
    incr pr_signal_count
    set status [dbGet $instance.pStatus]
    if {$status ni {fixed placed cover}} {
      lappend pr_pad_ring_errors "unplaced signal pad [dbGet $instance.name] status=$status"
    }
  }
}
if {$pr_signal_count != $::PR_SIGNAL_PAD_EXPECTED_COUNT} {
  lappend pr_pad_ring_errors "expected $::PR_SIGNAL_PAD_EXPECTED_COUNT signal pads, found $pr_signal_count"
}

if {[llength $pr_pad_ring_errors] != 0} {
  error "Incomplete SMIC180 pad ring: $pr_pad_ring_errors"
}
puts "PR_PAD_RING status=pass signal_pads=$pr_signal_count power_pads=[llength $::PR_POWER_PAD_INSTANCES] corners=[llength $::PR_CORNER_INSTANCES]"
