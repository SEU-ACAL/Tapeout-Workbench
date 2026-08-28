# Reuse the synthesis technology configuration so FM and DC select the same libraries.
set repo_dir [expr {[info exists ::env(FM_REPO_DIR)] ? $::env(FM_REPO_DIR) : [file normalize [file join [pwd] ..]]}]
set tech [expr {[info exists ::env(FM_TECH)] ? $::env(FM_TECH) : ""}]
set tech_file [file join $repo_dir 2-SYN scripts tech "${tech}.tcl"]
if {$tech eq "" || ![file exists $tech_file]} {
    error "Unknown or missing technology configuration: $tech_file"
}
source -e -v $tech_file

if {[info exists ::env(FM_TARGET_LIBRARY)] && $::env(FM_TARGET_LIBRARY) ne ""} {
    set target_library [list $::env(FM_TARGET_LIBRARY)]
}

foreach var {target_library io_link_library sram_link_library rom_link_library} {
    if {![info exists $var]} { set $var [list] }
}
set all_link_libraries [concat $target_library $io_link_library $sram_link_library $rom_link_library]
set link_library "* [join $all_link_libraries { }]"
set search_path [list .]
foreach lib $all_link_libraries { lappend search_path [file dirname $lib] }
puts "Technology: $tech"
puts "Target library: $target_library"
puts "Link library: $link_library"
foreach lib $all_link_libraries {
    if {![file exists $lib]} { error "Missing technology library: $lib" }
    if {$lib ne ""} { read_db $lib }
}
