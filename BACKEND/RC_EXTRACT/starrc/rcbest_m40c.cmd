* StarRC standalone LEF/DEF extraction for the active hold RC/PVT corner.
BLOCK: multiplier_pipe3
LEF_FILE: /data2/TSMC28/TF/N28_PRTF_Cad_v1d5a/PR_tech/Cadence/LefHeader/HVH/tsmcn28_10lm5X2Y2ZUTRDL.tlef
LEF_FILE: /data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140lvt_110a/lef/tcbn28hpcplusbwp7t40p140lvt.lef
TOP_DEF_FILE: /data1/GB/ic_workbench/BACKEND/PR/reports/final/io_pin_placement.def
* Cadence LEF/DEF layer-name adapter derived from the PDK mapping above.
MAPPING_FILE: tech/tsmc28_5x2y2z_innovus.mapping
TCAD_GRD_FILE: /data2/TSMC28/TF/RC_Star-RCXT_cln28hpc+_1p10m+ut-alrdl_5x2y2z_rcbest/cln28hpc+_1p10m+ut-alrdl_5x2y2z_rcbest.nxtgrd
OPERATING_TEMPERATURE: -40

EXTRACTION: RC
NETLIST_FORMAT: SPEF
NETLIST_FILE: outputs/multiplier_pipe3.rcbest_m40c.starrc.spef
STAR_DIRECTORY: work/rcbest_m40c
COUPLE_TO_GROUND: NO
COUPLING_ABS_THRESHOLD: 1e-16
COUPLING_REL_THRESHOLD: 0.03
EXTRACT_VIA_CAPS: YES
LEF_USE_OBS: YES
TRANSLATE_DEF_BLOCKAGE: YES
REMOVE_FLOATING_NETS: YES
REMOVE_DANGLING_NETS: YES
NETLIST_NODE_SECTION: YES
REDUCTION_MAX_DELAY_ERROR: 0.1PS
