proc require_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "Missing required environment variable: $name"
    }
    return $::env($name)
}

proc chiptop_sram_link_library {sram_root sram_corner sram_db_template sram_names} {
    set libraries [list]
    foreach sram_name $sram_names {
        set relative_db [format $sram_db_template $sram_name $sram_corner]
        lappend libraries [file join $sram_root $sram_name $relative_db]
    }
    return $libraries
}

proc chiptop_rom_link_library {rom_root rom_corner rom_db_template} {
    if {$rom_root eq "" || $rom_db_template eq ""} {
        return [list]
    }
    set rom_names [list \
        S018VM_X64Y16D64_PM \
        S018VM_X8Y16D64_PM]
    set libraries [list]
    foreach rom_name $rom_names {
        set relative_db [format $rom_db_template $rom_name $rom_corner]
        set subdir debugrom
        if {[string match *X64* $rom_name]} { set subdir bootrom }
        set candidate [file join $rom_root $subdir $relative_db]
        if {![file exists $candidate]} { set candidate [file join $rom_root $relative_db] }
        lappend libraries $candidate
    }
    return $libraries
}

proc require_files {label files} {
    foreach input_file $files {
        if {![file exists $input_file]} {
            error "Missing $label input: $input_file"
        }
    }
}

proc load_chiptop_design {top_design netlist sdc_file} {
    read_verilog $netlist
    current_design $top_design
    link
    source $sdc_file
    set_propagated_clock [all_clocks]
}
