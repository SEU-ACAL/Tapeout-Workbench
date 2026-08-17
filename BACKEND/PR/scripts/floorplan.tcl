if {$::FLOORPLAN_DEF ne ""} {
  defIn $::FLOORPLAN_DEF
} elseif {$::PR_IO_PLACEMENT_MODE eq "edit_pin"} {
  floorPlan -site $::CORE_SITE -r $::CORE_ASPECT_RATIO $::CORE_UTILIZATION \
    $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN

  set pr_input_ports [get_ports -quiet -filter {direction == in} *]
  set pr_output_ports [get_ports -quiet -filter {direction == out} *]
  if {$pr_input_ports eq "" || $pr_output_ports eq ""} {
    error "I/O pin planning requires at least one input and one output port"
  }
  set pr_input_pin_names [get_db $pr_input_ports .name]
  set pr_output_pin_names [get_db $pr_output_ports .name]
  editPin -pin $pr_input_pin_names -side $::IO_PIN_INPUT_SIDE \
    -layer $::IO_PIN_INPUT_LAYER -spreadType center -fixedPin
  editPin -pin $pr_output_pin_names -side $::IO_PIN_OUTPUT_SIDE \
    -layer $::IO_PIN_OUTPUT_LAYER -spreadType center -fixedPin
} elseif {$::PR_IO_PLACEMENT_MODE eq "pad_ring_def"} {
  error "Technology $::PR_TECHNOLOGY requires FLOORPLAN_DEF with fixed SP018RP pad-ring and PVDD1R/PVSS1R placement"
} elseif {$::PR_IO_PLACEMENT_MODE eq "pad_ring_auto"} {
  floorPlan -site $::CORE_SITE -r $::CORE_ASPECT_RATIO $::CORE_UTILIZATION \
    $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN
  if {![file isfile $::PR_PAD_RING_SCRIPT]} {
    error "Missing automatic pad-ring script: $::PR_PAD_RING_SCRIPT"
  }
  source $::PR_PAD_RING_SCRIPT
} elseif {$::PR_IO_PLACEMENT_MODE eq "pad_ring_iofile"} {
  if {![info exists ::PR_IO_FILE] || ![file isfile $::PR_IO_FILE]} {
    error "Missing IO placement file: [expr {[info exists ::PR_IO_FILE] ? $::PR_IO_FILE : \"<unset>\"}]"
  }
  if {![info exists ::PR_CORNER_CELL] || ![info exists ::PR_CORNER_INSTANCES]} {
    error "SMIC180 IO floorplan requires a corner cell and four corner instances"
  }

  floorPlan -site $::CORE_SITE -r $::CORE_ASPECT_RATIO $::CORE_UTILIZATION \
    $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN $::CORE_MARGIN

  set pr_existing_inst_names [dbGet top.insts.name]
  foreach pr_corner_inst $::PR_CORNER_INSTANCES {
    if {[lsearch -exact $pr_existing_inst_names $pr_corner_inst] >= 0} {
      error "Corner instance already exists: $pr_corner_inst"
    }
    addInst -cell $::PR_CORNER_CELL -inst $pr_corner_inst
  }

  # The IO file owns pad and corner placement; keep the floorplan die fixed.
  loadIoFile $::PR_IO_FILE -noAdjustDieSize -specifiedIosOnly
} else {
  error "Unsupported PR_IO_PLACEMENT_MODE '$::PR_IO_PLACEMENT_MODE'"
}
