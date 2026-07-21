proc require_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "Missing required environment variable: $name"
    }
    return $::env($name)
}

proc chiptop_sram_link_library {sram_root sram_corner} {
    set sram_names [list \
        chipyard_sram_32x22 \
        chipyard_sram_512x64 \
        chipyard_sram_512x8 \
        chipyard_sram_64x22 \
        chipyard_sram_64x21 \
        chipyard_sram_512x32]
    set libraries [list]
    foreach sram_name $sram_names {
        lappend libraries "$sram_root/$sram_name/NLDM/${sram_name}_${sram_corner}.db"
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
