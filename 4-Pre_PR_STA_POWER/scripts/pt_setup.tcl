set lib_path "/data2/TSMC28/logic/tcbn28hpcplusbwp12t40p140lvt_180a/AN61001_20180514/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp12t40p140lvt_180a   \
              /data2/tools/syn/R-2020.09-SP5/libraries/syn"


                     
set search_path       ". $lib_path"
set target_library   "/data2/TSMC28/logic/tcbn28hpcplusbwp12t40p140lvt_180a/AN61001_20180514/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp12t40p140lvt_180a/tcbn28hpcplusbwp12t40p140lvtssg0p81v125c.db"


                      

set synthetic_library "/data2/tools/syn/R-2020.09-SP5/libraries/syn/dw_foundation.sldb /data2/tools/syn/R-2020.09-SP5/libraries/syn/standard.sldb"
#
set link_library      "* $target_library $synthetic_library"

puts "=== Library Configuration ==="
puts "Target Library: $target_library"
puts "Synthetic Library: $synthetic_library"
puts "Link Library: $link_library"
puts "=============================="
# # set target_library   " scc28nhkcp_hdc35p140_rvt_ffg_v0p99_0c_ccs.db \
# # 					"

                     

# #set synthetic_library ""

# set link_library      " * \
# 	           	$target_library \
#                 $synthetic_library"