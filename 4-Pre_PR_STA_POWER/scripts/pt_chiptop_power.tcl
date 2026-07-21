set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir chiptop_common.tcl]

set power_enable_analysis true
set power_analysis_mode averaged

set top_design [require_env TOP]
set netlist [require_env NETLIST]
set sdc_file [require_env SDC]
set activity_format [string tolower [require_env ACTIVITY_FORMAT]]
set activity_file [require_env ACTIVITY_FILE]
set activity_strip_path [require_env ACTIVITY_STRIP_PATH]
set power_out_dir [require_env POWER_OUT_DIR]
set stdcell_db [require_env STDCELL_DB]
set sram_root [require_env SRAM_ROOT]
set sram_corner [require_env SRAM_CORNER]

if {$activity_format ni {saif fsdb}} {
    error "ACTIVITY_FORMAT must be saif or fsdb"
}

set sram_link_library [chiptop_sram_link_library $sram_root $sram_corner]
require_files "power analysis" [concat [list $netlist $sdc_file $activity_file $stdcell_db] $sram_link_library]

set target_library $stdcell_db
set link_library [concat * $stdcell_db $sram_link_library]

load_chiptop_design $top_design $netlist $sdc_file

file mkdir $power_out_dir
redirect "$power_out_dir/check_timing.rpt" { check_timing -verbose }

if {$activity_format eq "saif"} {
    read_saif $activity_file -strip_path $activity_strip_path \
        -report_inconsistent_annotation "$power_out_dir/activity_inconsistent.rpt"
} else {
    set power_start_ns [require_env POWER_START_NS]
    read_fsdb -zero_delay -strip_path $activity_strip_path \
        -time [list $power_start_ns -1] $activity_file
}
update_power

redirect "$power_out_dir/check_power.rpt" { check_power }
redirect "$power_out_dir/power_total.rpt" { report_power }
redirect "$power_out_dir/power_hierarchy.rpt" { report_power -hierarchy -levels 3 }
redirect "$power_out_dir/power_verbose.rpt" { report_power -verbose }

puts "Wrote power reports to $power_out_dir"
quit
