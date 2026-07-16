# Flowkit v23.10-a001_1

# Copyright (C) 2014 Cadence Design Systems, Inc.
# All Rights Reserved.
# CCRNI-0013
#
# This work is protected by copyright laws and contains Cadence proprietary
# and confidential information.  No part of this file may be reproduced,
# modified, re-published, used, disclosed or distributed in any way, in any
# medium, whether in whole or in part, without prior written permission from
# Cadence Design Systems, Inc.
#
#===========================================================================
#- run_flow.tcl: source this file to define required flow objects and consume
#                all customizations

################################################################################
# Flow Setup
################################################################################

#- Setup canonical flow path
define_flowkit_db flow_report_name \
  -data_type string \
  -default "" \
  -help_string "Name to use during report generation"

################################################################################
# Define Flow Features
################################################################################

# +--------------------------+-------------------------------------------------------------------+----------+
# | Feature                  | Description                                                       | Value    |
# +--------------------------+-------------------------------------------------------------------+----------+
# | clock_design             | Run discrete clock expansion                                      | disabled |
# --- the following features are mutually exclusive (flow_style group)
# | flow_express             | Enable express synthesis and implementation flow                  | disabled |
# ---
# | opt_early_cts            | Implement early clock tree for use during prects optimization     | disabled |
# | opt_eco                  | Run opt_design during eco flow                                    | disabled |
# | opt_postcts_hold_disable | Disable postcts hold fixing                                       | disabled |
# | opt_postcts_split        | Run postcts opt_design for setup and hold as separate steps       | disabled |
# | opt_postroute_split      | Run postroute opt_design for setup and hold as separate steps     | disabled |
# | opt_signoff              | Run opt_signoff during implementation flow                        | disabled |
# | report_clp               | Add CLP dofile generation and checks to the flow                  | disabled |
# | report_inline            | Run report generation as part of parent flow versus schedule_flow | disabled |
# | report_lec               | Add LEC dofile generation and checks to the flow                  | disabled |
# | route_secondary_nets     | Route secondary PG nets before route_design                       | disabled |
# | route_track_opt          | Adds track based optimization to route_design                     | disabled |
# | use_common_db            | Enable using common DB format for synth and implementation flows  | disabled |
# +--------------------------+-------------------------------------------------------------------+----------+

set_flowkit_db flow_template_type {block}
set_flowkit_db flow_template_version {1}
set_flowkit_db flow_template_tools {innovus}
set_flowkit_db flow_template_feature_definition {flow_express 0 report_inline 0 report_lec 0 report_clp 0 use_common_db 0 opt_early_cts 0 clock_design 0 opt_postcts_hold_disable 0 opt_postcts_split 0 route_track_opt 0 route_secondary_nets 0 opt_postroute_split 0 opt_signoff 0 opt_eco 0}

################################################################################
# Load Flow Files
################################################################################

source [file join [file dirname [info script]] flow common_steps.tcl]
source [file join [file dirname [info script]] flow innovus_steps.tcl]
source [file join [file dirname [info script]] project_config.tcl]
source [file join [file dirname [info script]] design_config.tcl]

##############################################################################
# Define Implementation Subflows
##############################################################################

create_flow -name floorplan -owner cadence -tool innovus -tool_options -disable_user_startup {block_start init_design init_floorplan add_tracks block_finish schedule_report_floorplan}

create_flow -name prects -owner cadence -tool innovus -tool_options -disable_user_startup {block_start run_place_opt block_finish schedule_report_prects}

create_flow -name cts -owner cadence -tool innovus -tool_options -disable_user_startup {block_start add_clock_spec add_clock_tree add_tieoffs block_finish schedule_report_postcts}

create_flow -name postcts -owner cadence -tool innovus -tool_options -disable_user_startup {block_start run_opt_postcts_hold block_finish schedule_report_postcts}

create_flow -name route -owner cadence -tool innovus -tool_options -disable_user_startup {block_start add_fillers run_route block_finish schedule_report_postroute}

create_flow -name postroute -owner cadence -tool innovus -tool_options -disable_user_startup {block_start run_opt_postroute block_finish schedule_report_postroute}

create_flow -name eco -owner cadence -tool innovus -tool_options -disable_user_startup {eco_start init_eco run_place_eco run_route_eco eco_finish schedule_report_postroute}

##############################################################################
# Define Reporting Subflows
##############################################################################

create_flow -name report_floorplan -owner cadence -tool innovus -tool_options -disable_user_startup {report_start report_area_innovus report_route_drc report_finish}

create_flow -name report_prects -owner cadence -tool innovus -tool_options -disable_user_startup {report_start report_area_innovus report_timing_late_innovus report_late_paths report_power_innovus report_finish}

create_flow -name report_postcts -owner cadence -tool innovus -tool_options -disable_user_startup {report_start report_area_innovus report_timing_early_innovus report_early_paths report_timing_late_innovus report_late_paths report_clock_timing report_power_innovus report_finish}

create_flow -name report_postroute -owner cadence -tool innovus -tool_options -disable_user_startup {report_start report_area_innovus report_timing_early_innovus report_early_paths report_timing_late_innovus report_late_paths report_clock_timing report_power_innovus report_route_drc report_route_density report_finish}


################################################################################
# Define Block Flow
################################################################################

create_flow -name block -owner cadence -skip_metric {floorplan prects cts postcts route postroute}

set_flowkit_db flow_top flow:block

################################################################################
# Load Flow & Tool Customizations
################################################################################

source [file join [file dirname [info script]] flow_config.tcl]

#- Apply tool settings needed before a DB is loaded
if {([get_flowkit_db program_short_name] ne {}) && ([get_flowkit_db program_short_name] ne "flowtool")} {

  if [file exists [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl]] {
    #- Validate PLACEHOLDER content in config files
    set FH [open [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl]]
    set lines [read $FH]
    close $FH
    foreach line [split $lines "\n"] {
      if {[regexp {^\s*\#} $line]} {continue}
      if {[regexp {PLACEHOLDER} $line]} {
        error "Found PLACEHOLDER content in [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl]\n\t$line"
      }
    }

    source [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl]
  } else {
    error "Tool config [file join [get_flowkit_db init_flow_directory] [get_flowkit_db program_short_name]_config.tcl] file not found."
  }
}
