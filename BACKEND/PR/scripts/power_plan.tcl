addNet VDD -power
addNet VSS -ground
foreach connection $::PR_POWER_PIN_MAP {
  lassign $connection net pin
  globalNetConnect $net -type pgpin -pin $pin -inst *
}
applyGlobalNets

addRing -type core_rings -nets {VDD VSS} \
  -layer [list top $::PR_PG_RING_HORIZONTAL bottom $::PR_PG_RING_HORIZONTAL \
               left $::PR_PG_RING_VERTICAL right $::PR_PG_RING_VERTICAL] \
  -width $::PR_PG_RING_WIDTH -spacing $::PR_PG_RING_SPACING -offset $::PR_PG_RING_OFFSET

if {$::PR_WELL_TAP_CELL ne ""} {
  addWellTap -cell $::PR_WELL_TAP_CELL -cellInterval $::PR_WELL_TAP_INTERVAL
}
addStripe -nets {VDD VSS} -layer $::PR_PG_RING_VERTICAL -direction vertical \
  -width $::PR_PG_STRIPE_WIDTH -spacing $::PR_PG_STRIPE_SPACING \
  -set_to_set_distance $::PR_PG_STRIPE_PITCH
sroute -connect corePin -nets {VDD VSS}
