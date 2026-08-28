proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}
proc require_file {path label} {
    if {$path eq "" || ![file exists $path]} { error "Missing $label: $path" }
}
set top_design [env_or FM_TOP multiplier_pipe3]
set rtl_file [env_or FM_RTL ""]
set rtl_filelist [env_or FM_RTL_FILELIST ""]
set netlist_file [env_or FM_NETLIST ""]
set svf_file [env_or FM_SVF ""]
set fail_limit [env_or FM_FAIL_LIMIT 20]
set timeout_limit [env_or FM_TIMEOUT_LIMIT 36:0:0]
set report_dir [env_or FM_REPORT_DIR [file join [pwd] rpt]]
file mkdir $report_dir
require_file $netlist_file "implemented netlist"
if {$rtl_filelist ne ""} { require_file $rtl_filelist "RTL filelist" }
if {$rtl_filelist eq ""} { require_file $rtl_file "reference RTL" }
if {$svf_file ne ""} { require_file $svf_file SVF }
set verification_auto_session on
set verification_clock_gate_edge_analysis true
set verification_failing_point_limit $fail_limit
set verification_timeout_limit $timeout_limit
guide
setup
if {$svf_file ne ""} { set_svf -append $svf_file }
source -e -v [file join [file dirname [info script]] fm_setup.tcl]
set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_VLOG-091
read_db $target_library
if {$rtl_filelist ne ""} {
    set fh [open $rtl_filelist r]
    set rtl_files {}
    while {[gets $fh line] >= 0} {
        set line [string trim $line]
        if {$line ne "" && ![string match "#*" $line]} { lappend rtl_files $line }
    }
    close $fh
    if {$rtl_file ne ""} { lappend rtl_files $rtl_file }
    if {[llength $rtl_files] == 0} { error "RTL filelist is empty: $rtl_filelist" }
    foreach f $rtl_files {
        require_file $f "RTL source"
        if {[string match "*.sv" $f] || [string match "*.svh" $f]} {
            read_sverilog -r $f
        } else {
            read_verilog -r $f
        }
    }
} else {
    read_verilog -r $rtl_file
}
if {[set_top r:/WORK/$top_design] != 1} { error "Failed to set reference top: $top_design" }
read_verilog -i $netlist_file
if {[set_top i:/WORK/$top_design] != 1} { error "Failed to set implementation top: $top_design" }
if {[catch {redirect -file [file join $report_dir match.rpt] { match }} message]} {
    error "Formality match failed: $message"
}
if {[catch {redirect -file [file join $report_dir verify.rpt] { verify }} message]} {
    error "Formality verify failed: $message"
}
set verify_fh [open [file join $report_dir verify.rpt] r]
set verify_text [read $verify_fh]
close $verify_fh
if {[regexp {Verification (FAILED|INCONCLUSIVE)} $verify_text matched status]} {
    error "Formality verification $status"
}
redirect -file [file join $report_dir failing_points.rpt] { report_failing_points }

# Keep post-match diagnostics for points omitted from the equivalence summary.
foreach diagnostic {
    {potentially_constant_registers.rpt {report_potentially_constant_registers}}
    {init_toggle_objects.rpt {report_init_toggle_objects}}
    {unmatched_points.rpt {report_unmatched_points -point_type all}}
} {
    lassign $diagnostic report_name command
    if {[catch {redirect -file [file join $report_dir $report_name] $command} message]} {
        set warning_fh [open [file join $report_dir $report_name] w]
        puts $warning_fh "WARNING: $message"
        close $warning_fh
        puts "WARNING: diagnostic '$command' failed: $message"
    }
}
puts "Formality verification completed for $top_design"
exit 0
