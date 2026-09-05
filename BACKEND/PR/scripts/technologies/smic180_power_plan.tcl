# SMIC180-specific power plan.  The technology uses M5 horizontal and M6
# vertical preferred directions; compiler macro VDD/VSS rails are vertical M4.

addNet VDD -power
addNet VSS -ground
foreach connection $::PR_POWER_PIN_MAP {
  lassign $connection net pin
  globalNetConnect $net -type pgpin -pin $pin -inst *
}
applyGlobalNets

addRing -type core_rings -nets {VDD VSS} \
  -layer [list top METAL5 bottom METAL5 left METAL6 right METAL6] \
  -width $::PR_PG_RING_WIDTH -spacing $::PR_PG_RING_SPACING -offset $::PR_PG_RING_OFFSET

# M6 uses one globally phased vertical grid and only macro-free Y segments.
# The macro rails attach to the continuous M5 mesh below.
set pr_m6_macro_boxes {}
if {[info exists ::PR_PG_MACRO_INSTANCES]} {
  foreach pr_macro_inst $::PR_PG_MACRO_INSTANCES {
    set pr_macro_obj $pr_macro_inst
    if {![string match "inst:*" $pr_macro_inst]} {
      set pr_macro_obj [get_db insts $pr_macro_inst]
    }
    if {$pr_macro_obj eq ""} {
      error "SMIC180 PG macro instance is absent: $pr_macro_inst"
    }
    set pr_bbox [lindex [get_db $pr_macro_obj .bbox] 0]
    lassign $pr_bbox pr_x1 pr_y1 pr_x2 pr_y2
    if {$pr_x1 eq "" || $pr_y1 eq "" || $pr_x2 eq "" || $pr_y2 eq ""} {
      error "SMIC180 PG macro bbox is invalid: inst=$pr_macro_inst bbox='$pr_bbox'"
    }
    set pr_keepout 5.0
    lappend pr_m6_macro_boxes [list \
      [expr {$pr_x1 - $pr_keepout}] [expr {$pr_y1 - $pr_keepout}] \
      [expr {$pr_x2 + $pr_keepout}] [expr {$pr_y2 + $pr_keepout}]]
  }
}

if {[llength $pr_m6_macro_boxes] == 0} {
  addStripe -nets {VDD VSS} -layer METAL6 -direction vertical \
    -width $::PR_PG_STRIPE_WIDTH_M6 -spacing $::PR_PG_STRIPE_SPACING_M6 \
    -set_to_set_distance $::PR_PG_STRIPE_PITCH
} else {
  lassign [lindex [get_db current_design .core_bbox] 0] pr_cx1 pr_cy1 pr_cx2 pr_cy2
  # Align the first stripe to the LEF M6 offset and continue with a single
  # 100.8um period.  A narrow area per X position prevents addStripe from
  # restarting a new grid in every macro channel.
  set pr_m6_grid_origin 0.45
  set pr_x_first [expr {ceil(($pr_cx1 - $pr_m6_grid_origin) / $::PR_PG_STRIPE_PITCH) * $::PR_PG_STRIPE_PITCH + $pr_m6_grid_origin}]
  set pr_m6_pair_span [expr {2.0 * $::PR_PG_STRIPE_WIDTH_M6 + $::PR_PG_STRIPE_SPACING_M6}]
  set pr_m6_grid_count [expr {max(0, int(floor(($pr_cx2 - $pr_x_first) / $::PR_PG_STRIPE_PITCH)) + 1)}]
  puts "PR_SMIC180_M6_GLOBAL_GRID x_first=$pr_x_first pitch=$::PR_PG_STRIPE_PITCH positions=$pr_m6_grid_count"
  set pr_m6_segment_count 0
  for {set pr_x $pr_x_first} {$pr_x <= $pr_cx2} {set pr_x [expr {$pr_x + $::PR_PG_STRIPE_PITCH}]} {
    set pr_y_intervals {}
    foreach pr_box $pr_m6_macro_boxes {
      lassign $pr_box pr_bx1 pr_by1 pr_bx2 pr_by2
      if {$pr_bx1 <= $pr_x && $pr_bx2 >= $pr_x} {
        lappend pr_y_intervals [list \
          [expr {max($pr_cy1, $pr_by1)}] [expr {min($pr_cy2, $pr_by2)}]]
      }
    }
    set pr_y_intervals [lsort -real -index 0 $pr_y_intervals]
    set pr_y_cursor $pr_cy1
    foreach pr_interval $pr_y_intervals {
      lassign $pr_interval pr_y1 pr_y2
      if {$pr_y1 > $pr_y_cursor} {
        addStripe -nets {VDD VSS} -layer METAL6 -direction vertical \
          -width $::PR_PG_STRIPE_WIDTH_M6 -spacing $::PR_PG_STRIPE_SPACING_M6 \
          -set_to_set_distance $::PR_PG_STRIPE_PITCH \
          -start_offset 0 \
          -area [list $pr_x $pr_y_cursor [expr {$pr_x + $pr_m6_pair_span}] $pr_y1]
        incr pr_m6_segment_count
      }
      set pr_y_cursor [expr {max($pr_y_cursor, $pr_y2)}]
    }
    if {$pr_y_cursor < $pr_cy2} {
      addStripe -nets {VDD VSS} -layer METAL6 -direction vertical \
        -width $::PR_PG_STRIPE_WIDTH_M6 -spacing $::PR_PG_STRIPE_SPACING_M6 \
        -set_to_set_distance $::PR_PG_STRIPE_PITCH \
        -start_offset 0 \
        -area [list $pr_x $pr_y_cursor [expr {$pr_x + $pr_m6_pair_span}] $pr_cy2]
      incr pr_m6_segment_count
    }
  }
  puts "PR_SMIC180_M6_CHANNEL_SEGMENTS count=$pr_m6_segment_count"
}

addStripe -nets {VDD VSS} -layer METAL5 -direction horizontal \
  -width $::PR_PG_STRIPE_WIDTH_M5 -spacing $::PR_PG_STRIPE_SPACING_M5 \
  -set_to_set_distance $::PR_PG_STRIPE_PITCH

# No block rings: macro M4 rails terminate on M5 with only VIA45.
sroute -connect {blockPin} -nets {VDD VSS} \
  -layerChangeRange {METAL4 METAL5} \
  -blockPinLayerRange {METAL4 METAL4} \
  -blockPinTarget {stripe}
sroute -connect {padPin corePin} -nets {VDD VSS} \
  -layerChangeRange {METAL1 METAL6} \
  -corePinTarget {stripe}
