create_flow_step -name init_design -owner design -write_db {
  set ::init_mmmc_file        [get_flowkit_db init_flow_directory]/mmmc_config.tcl
  set ::init_lef_file         [list $::TECH_LEF $::SITE_LEF $::CELL_LEF]
  set ::init_verilog          $::NETLIST
  set ::init_top_cell         $::TOP_MODULE
  init_design
  uplevel #0 source [get_flowkit_db init_flow_directory]/innovus_config.tcl
}

create_flow_step -name init_floorplan -owner design {
  uplevel #0 source [get_flowkit_db init_flow_directory]/floorplan.tcl
  uplevel #0 source [get_flowkit_db init_flow_directory]/power_plan.tcl
}
