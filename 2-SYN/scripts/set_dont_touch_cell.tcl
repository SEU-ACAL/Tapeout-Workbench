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

# Preserve foundry IO wrappers through synthesis.  Without this protection
# DC can constant-propagate the input-enable mux and collapse a PIR-backed
# input cell into `assign io_i = io_pad`, leaving no physical IO cell for P&R.
foreach io_wrapper {
    SMIC180DigitalInIOCell*
    SMIC180DigitalOutIOCell*
    SMIC180DigitalGPIOCell*
} {
    set io_cells [get_cells -hierarchical -filter "ref_name =~ $io_wrapper"]
    if {[sizeof_collection $io_cells] > 0} {
        set_dont_touch $io_cells
    }
}
