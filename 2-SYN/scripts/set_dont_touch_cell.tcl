# set_dont_use  [get_lib_cells "\
# 			*/CKAN* \
# 			*/CKB* \
# 			*/CKMUX* \
# 			*/CKN* \
# 			*/CKXOR* \
#             */CKLHQD1BWP* \
#             */CKLHQD2BWP* \
#             */*CKLHQD* \
#             */CKLHQD*  \
# 			*/*4D*   \
#             */TIEH* \
#             */TIEL* \
# 			*/G* \
# 			*/*D0* \
# 			*/BHD* \
# 			*/BOUNDARY* \
# 			*/TAPCELL* \
# 			*/DCAP* \
# 			*/FILL* \
# 			*/ANTENNA* \
# 			*/DCCK* \
# 			*/DEL* \
# 			"    
# ]

# set_dont_use [get_lib_cell \
# 	" */DEL* \
# 		*/*FILL* \
# 		*/F_DIODE* \
# 		*/PULL* \
# 		*/CLK* \
# 		*/*V20_140P7T* \
# 		*/*V24_140P7T* \
# 		*/*V32_140P7T* \
# 		*/*V40_140P7T* \
# 		*/*V48_140P7T* \
# 		*/INV1_140P7T* \
# 		*/INV1P5_140P7T* \
# 		*/INV2_140P7T* \
# 		*/AOI22V1_* \
# 		*/OAI32V2_*  \
# 		*/TBUF* \
# " ]

# Preserve the foundry pad primitives, but leave the wrapper's core-side
# enable/readback logic available for technology mapping.  Protecting the
# complete wrapper leaves DC GTECH_NOT/GTECH_AND2 cells in the netlist, which
# cannot be compiled by GLS and are not physical SMIC180 cells.
foreach io_ref {PIR POT8R PB8R} {
    set io_cells [get_cells -hierarchical -filter "ref_name == $io_ref"]
    if {[sizeof_collection $io_cells] > 0} {
        set_dont_touch $io_cells
    }
}
