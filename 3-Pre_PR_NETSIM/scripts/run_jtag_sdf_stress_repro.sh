#!/usr/bin/env bash
set -euo pipefail

# Deterministic end-to-end reproducer for the SDF JTAG/SBA stress failure.
# Invoke through Chipyard's default Nix shell. It supplies the VCS/Verdi
# W-2024.09 pair used to build simv-gls-sdf-framehistory:
#   nix develop --command \
#     /data1/GB/ic_workbench/3-Pre_PR_NETSIM/scripts/run_jtag_sdf_stress_repro.sh RUN_DIR
#
# One RSP client is used for the complete run.  The fixed seed and the history
# probe preserve both the failure symptom and the pin-level SerialTL evidence.
run_dir="${1:?usage: $0 RUN_DIR}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_root="${WORKBENCH_ROOT:-$(cd "${script_dir}/../.." && pwd)}"
config="${CONFIG:-chipyard.harness.TestHarness.TapeoutConfig}"
netlist_run="${NETLIST_RUN:-0812_0828}"
sim_dir="${SIM_DIR:-${workbench_root}/3-Pre_PR_NETSIM/gen/${config}/${netlist_run}}"
wrapper="${JTAG_WRAPPER:-${script_dir}/run_jtag_bypass_sim.sh}"
stress="${RSP_STRESS:-${script_dir}/jtag_rsp_stress_trace.py}"
chipyard_root="${CHIPYARD_ROOT:-${TAPE_ENV:-/data1/GB/chipyard}}"
elf="${JTAG_ELF:-${chipyard_root}/applications/tests/jtag/build/gdb-loop.elf}"
dram_ini="${DRAMSIM_INI_DIR:-${chipyard_root}/soc-generator/generator/testchipip/src/main/resources/dramsim2_ini}"
# The Nix shell supplies the OpenOCD version used by Chipyard's jtag-debug
# shell. Set OPENOCD explicitly when the shell exposes more than one version.
openocd_bin="${OPENOCD:-${OPENOCD_BIN:-$(command -v openocd 2>/dev/null || true)}}"
gdb_port="${GDB_PORT:-3465}"
steps="${STRESS_STEPS:-32}"
memory="${STRESS_MEMORY:-64}"
request_timeout="${STRESS_TIMEOUT:-600}"
openocd_command_timeout="${OPENOCD_COMMAND_TIMEOUT:-600}"
jtag_wave_window="${JTAG_WAVE_WINDOW:-1}"
openocd_debug="${OPENOCD_DEBUG:-0}"
sim_pid=''
openocd_pid=''

mkdir -p "$run_dir"
export SIM_DIR="$sim_dir"
export JTAG_SIMV_NAME="${JTAG_SIMV_NAME:-simv-gls-sdf-framehistory}"

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  [[ -n "$openocd_pid" ]] && kill "$openocd_pid" 2>/dev/null || true
  [[ -n "$sim_pid" ]] && kill "$sim_pid" 2>/dev/null || true
  [[ -n "$openocd_pid" ]] && wait "$openocd_pid" 2>/dev/null || true
  [[ -n "$sim_pid" ]] && wait "$sim_pid" 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT INT TERM

[[ -n "$openocd_bin" && -x "$openocd_bin" ]] || { echo "OpenOCD not found; set OPENOCD=/path/to/openocd" >&2; exit 2; }
[[ -x "$stress" && -r "$elf" && -d "$dram_ini" ]]

sim_args=(+permissive +dramsim "+dramsim_ini_dir=$dram_ini"
  +max-cycles=0 +notimingcheck +ntb_random_seed=1 +jtag_rbb_enable=1
  +keep_jtag_sim_alive +sba_correlate_trace +serial_tl_history_probe
  +dmi_protocol_ledger +debug_control_ledger
  "+fsdbfile=$run_dir/jtag_sdf_stress.fsdb" +permissive-off "$elf")
if [[ "$jtag_wave_window" == 1 ]]; then
  sim_args+=(+jtag_wave_window)
fi

"$wrapper" "${sim_args[@]}" \
  >"$run_dir/sim.log" 2>"$run_dir/sim.stderr" &
sim_pid=$!

rbb_port=''
for _ in $(seq 1 90); do
  rbb_port="$(sed -n 's/.*Listening on port \([0-9][0-9]*\).*/\1/p' "$run_dir/sim.stderr" | tail -n 1)"
  [[ -n "$rbb_port" ]] && break
  kill -0 "$sim_pid" 2>/dev/null
  sleep 1
done
[[ -n "$rbb_port" ]]

openocd_args=()
if [[ "$openocd_debug" != 0 ]]; then
  openocd_args=(-d3)
fi

"$openocd_bin" "${openocd_args[@]}" \
  -c 'adapter driver remote_bitbang' \
  -c 'remote_bitbang host 127.0.0.1' \
  -c "remote_bitbang port $rbb_port" \
  -c 'transport select jtag' \
  -c 'bindto 127.0.0.1' \
  -c "gdb_port $gdb_port" \
  -c 'telnet_port disabled' \
  -c 'tcl_port disabled' \
  -c 'jtag newtap riscv cpu -irlen 5' \
  -c 'target create riscv.cpu riscv -chain-position riscv.cpu' \
  -c 'reset_config none' \
  -c 'riscv set_mem_access sysbus' \
  -c 'riscv set_reset_timeout_sec 30' \
  -c "riscv set_command_timeout_sec $openocd_command_timeout" \
  -c init >"$run_dir/openocd.log" 2>&1 &
openocd_pid=$!

for _ in $(seq 1 120); do
  grep -q "Listening on port $gdb_port" "$run_dir/openocd.log" && break
  kill -0 "$openocd_pid" 2>/dev/null
  sleep 1
done
grep -q "Listening on port $gdb_port" "$run_dir/openocd.log"

python3 "$stress" --host 127.0.0.1 --port "$gdb_port" --elf "$elf" \
  --steps "$steps" --memory "$memory" --timeout "$request_timeout" \
  >"$run_dir/rsp.log" 2>&1

grep -q 'SBA_STRESS_START' "$run_dir/sim.log"
grep -q 'SERIAL_TL_HISTORY_START' "$run_dir/sim.log"
grep -q 'JTAG_RSP_TRACE_PASS' "$run_dir/rsp.log"
