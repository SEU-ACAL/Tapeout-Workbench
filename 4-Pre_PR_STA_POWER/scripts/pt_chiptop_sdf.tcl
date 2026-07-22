set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir chiptop_common.tcl]

set top_design [require_env TOP]
set netlist [require_env NETLIST]
set sdc_file [require_env SDC]
set sdf_out [require_env SDF_OUT]

set stdcell_db [require_env STDCELL_DB]
set sram_root [require_env SRAM_ROOT]
set sram_corner [require_env SRAM_CORNER]
set sram_db_template [require_env SRAM_DB_TEMPLATE]
set technology [require_env TECH]
set technology_corner [require_env TECH_CORNER]

set sram_link_library [chiptop_sram_link_library $sram_root $sram_corner $sram_db_template]
require_files "SDF export" [concat [list $netlist $sdc_file $stdcell_db] $sram_link_library]

set target_library $stdcell_db
set link_library [concat * $stdcell_db $sram_link_library]

load_chiptop_design $top_design $netlist $sdc_file
puts "SDF technology: $technology, standard-cell corner: $technology_corner, SRAM corner: $sram_corner"
update_timing -full
check_timing -verbose

file mkdir [file dirname $sdf_out]
write_sdf -version 3.0 -context verilog \
    -no_edge -input_port_nets -output_port_nets \
    -include {SETUPHOLD RECREM} -exclude {checkpins no_condelse} \
    $sdf_out

puts "Wrote SDF: $sdf_out"
quit
