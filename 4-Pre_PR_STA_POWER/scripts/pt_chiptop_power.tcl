set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir chiptop_common.tcl]

set power_enable_analysis true
set power_analysis_mode averaged

set top_design [require_env TOP]
set netlist [require_env NETLIST]
set sdc_file [require_env SDC]
set fsdb_file [require_env FSDB]
set activity_strip_path [require_env ACTIVITY_STRIP_PATH]
set power_start_ns [require_env POWER_START_NS]
set power_out_dir [require_env POWER_OUT_DIR]
set stdcell_db [require_env STDCELL_DB]
set sram_root [require_env SRAM_ROOT]
set sram_corner [require_env SRAM_CORNER]
set sram_db_template [require_env SRAM_DB_TEMPLATE]
set technology [require_env TECH]
set technology_corner [require_env TECH_CORNER]

set sram_link_library [chiptop_sram_link_library $sram_root $sram_corner $sram_db_template]
require_files "power analysis" [concat [list $netlist $sdc_file $fsdb_file $stdcell_db] $sram_link_library]

set target_library $stdcell_db
set link_library [concat * $stdcell_db $sram_link_library]

load_chiptop_design $top_design $netlist $sdc_file
puts "Power technology: $technology, standard-cell corner: $technology_corner, SRAM corner: $sram_corner"

file mkdir $power_out_dir
redirect "$power_out_dir/check_timing.rpt" { check_timing -verbose }

read_fsdb -zero_delay -strip_path $activity_strip_path \
    -time [list $power_start_ns -1] $fsdb_file
update_power

redirect "$power_out_dir/check_power.rpt" { check_power }
redirect "$power_out_dir/power_total.rpt" { report_power }
redirect "$power_out_dir/power_hierarchy.rpt" { report_power -hierarchy -levels 3 }
redirect "$power_out_dir/power_verbose.rpt" { report_power -verbose }

puts "Wrote power reports to $power_out_dir"
quit
