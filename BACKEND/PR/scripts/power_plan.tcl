addNet VDD -power
addNet VSS -ground
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
applyGlobalNets

addRing -type core_rings -nets {VDD VSS} \
  -layer [list top $::PG_RING_HORIZONTAL bottom $::PG_RING_HORIZONTAL \
               left $::PG_RING_VERTICAL right $::PG_RING_VERTICAL] \
  -width 2 -spacing 1 -offset 1

addWellTap -cell TAPCELLBWP7T40P140 -cellInterval 30
addStripe -nets {VDD VSS} -layer $::PG_RING_VERTICAL -direction vertical \
  -width 1 -spacing 1 -set_to_set_distance 40
sroute -connect corePin -nets {VDD VSS}
