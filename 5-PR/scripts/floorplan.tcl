if {$::FLOORPLAN_DEF ne ""} {
  defIn $::FLOORPLAN_DEF
} else {
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
}
