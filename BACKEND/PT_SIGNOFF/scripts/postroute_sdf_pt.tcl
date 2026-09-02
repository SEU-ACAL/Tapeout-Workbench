foreach name {PR_TOP PR_POSTROUTE_NETLIST PR_POSTROUTE_SDC PR_SPEF PR_LIBS PR_TRIPLET PR_DELAY_TYPE PR_SDF PR_REPORT} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "Missing required environment variable: $name"
  }
}
set libs [split $::env(PR_LIBS)]
foreach file [concat [list $::env(PR_POSTROUTE_NETLIST) $::env(PR_POSTROUTE_SDC) $::env(PR_SPEF)] $libs] {
  if {![file isfile $file]} { error "Required PT input is missing: $file" }
}
set_app_var search_path [list [file dirname $::env(PR_POSTROUTE_NETLIST)]]
set_app_var target_library $libs
set_app_var link_path [concat [list "*"] $libs]
read_verilog $::env(PR_POSTROUTE_NETLIST)
current_design $::env(PR_TOP)
link
read_sdc $::env(PR_POSTROUTE_SDC)
read_parasitics -format SPEF -triplet_type $::env(PR_TRIPLET) $::env(PR_SPEF)
update_timing
file mkdir [file dirname $::env(PR_REPORT)]
redirect -file $::env(PR_REPORT) {
  puts "PR_PT_TIMING top=$::env(PR_TOP) triplet=$::env(PR_TRIPLET) delay_type=$::env(PR_DELAY_TYPE)"
  report_analysis_summary
  report_constraint -all_violators
  report_timing -delay_type $::env(PR_DELAY_TYPE) -max_paths 200 -nworst 1 -path_type full_clock -net
}
file mkdir [file dirname $::env(PR_SDF)]
write_sdf -version 3.0 -significant_digits 3 -context verilog $::env(PR_SDF)
if {![file isfile $::env(PR_SDF)] || [file size $::env(PR_SDF)] == 0} {
  error "SDF export did not create $::env(PR_SDF)"
}
puts "PR_PT_SDF status=pass sdf=$::env(PR_SDF) report=$::env(PR_REPORT)"
