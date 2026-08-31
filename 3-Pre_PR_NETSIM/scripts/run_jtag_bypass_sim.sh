#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_root="${WORKBENCH_ROOT:-$(cd "${script_dir}/../.." && pwd)}"
config="${CONFIG:-chipyard.harness.TestHarness.TapeoutConfig}"
netlist_run="${NETLIST_RUN:-0812_0828}"
sim_dir="${SIM_DIR:-${workbench_root}/3-Pre_PR_NETSIM/gen/${config}/${netlist_run}}"
sim_name="${JTAG_SIMV_NAME:-simv-gls-sdf-sbawave}"
# Keep the VCS/Verdi runtime libraries visible when this wrapper is launched
# from Chipyard's Nix shell. The daidir path is needed for simulator objects,
# while libnovas.so also depends on VCS's liberrindex.so.
vcs_lib="${VCS_HOME:-/data0/tools/Synopsys/vcs/vcs/W-2024.09-SP1}/linux64/lib"
# The instrumented simulator was linked against Verdi W-2024.09.  Loading the
# older R-2020.12 PLI selects an incompatible libnovas.so at runtime.
verdi_home="${VERDI_HOME:-/data0/tools/Synopsys/verdi/verdi/W-2024.09-SP1}"
verdi_pli="${verdi_home}/share/PLI/VCS/linux64"
export VERDI_HOME="$verdi_home"
[[ -x "${sim_dir}/${sim_name}" ]] || { echo "Missing JTAG simulator: ${sim_dir}/${sim_name}" >&2; exit 2; }
export LD_LIBRARY_PATH="${sim_dir}/${sim_name}.daidir:${vcs_lib}:${verdi_pli}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

args=()
for arg in "$@"; do
  args+=("$arg")
  if [[ "$arg" == "+permissive" ]]; then
    # The bypass is the experiment under test.  Full SBA logging is opt-in:
    # per-event display traffic otherwise changes Remote Bitbang wall time.
    args+=(+bypass_debug_clock_gate)
  fi
done
if [[ "${JTAG_SBA_TRACE:-0}" == 1 ]]; then
  args+=(+jtag_wave_window +serial_tl_packet_probe +sba_path_trace +sba_probe_trace +jtag_probe_trace +fsdbfile="${JTAG_TRACE_FSDB:-${sim_dir}/jtag_sba_sdf_${netlist_run}.fsdb}")
fi
if [[ "${JTAG_SBA_CORRELATE:-0}" == 1 ]]; then
  args+=(+jtag_wave_window +serial_tl_packet_probe +sba_correlate_trace +fsdbfile="${JTAG_CORRELATE_FSDB:-${sim_dir}/jtag_sba_correlate_sdf_${netlist_run}.fsdb}")
fi
if [[ "${JTAG_KEEP_ALIVE:-0}" == 1 ]]; then
  args+=(+keep_jtag_sim_alive)
fi
if [[ "${JTAG_SBA_PACKET_TRACE:-0}" == 1 ]]; then
  args+=(+serial_tl_packet_probe +sba_correlate_trace +sba_beat_trace +sba_path_trace +serial_tl_stall_probe)
fi
if [[ "${JTAG_L2_SBA_TRACE:-0}" == 1 ]]; then
  args+=(+sba_correlate_trace +l2_sba_trace)
fi
exec "${sim_dir}/${sim_name}" "${args[@]}"
