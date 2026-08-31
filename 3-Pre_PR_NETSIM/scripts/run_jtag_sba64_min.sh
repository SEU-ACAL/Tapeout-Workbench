#!/usr/bin/env bash
set -euo pipefail

# Minimal, single-connection reproduction of a 64-bit SBA write in SDF GLS.
# Do not probe the GDB or Remote Bitbang ports: both reject transient clients.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_root="${WORKBENCH_ROOT:-$(cd "${script_dir}/../.." && pwd)}"
config="${CONFIG:-chipyard.harness.TestHarness.TapeoutConfig}"
netlist_run="${NETLIST_RUN:-0812_0828}"
sim_dir="${SIM_DIR:-${workbench_root}/3-Pre_PR_NETSIM/gen/${config}/${netlist_run}}"
run_dir="${1:?usage: $0 RUN_DIR}"
wrapper="${JTAG_WRAPPER:-${script_dir}/run_jtag_bypass_sim.sh}"
chipyard_root="${CHIPYARD_ROOT:-${TAPE_ENV:-/data1/GB/chipyard}}"
elf="${JTAG_ELF:-${chipyard_root}/applications/tests/jtag/build/gdb-loop.elf}"
dram_ini="${DRAMSIM_INI_DIR:-${chipyard_root}/soc-generator/generator/testchipip/src/main/resources/dramsim2_ini}"
openocd="${OPENOCD:-${OPENOCD_BIN:-$(command -v openocd 2>/dev/null || true)}}"
[[ -x "$openocd" ]] || { echo "OpenOCD not found; set OPENOCD=/path/to/openocd" >&2; exit 2; }
export SIM_DIR="$sim_dir"
gdb_port=3461
openocd_command_timeout="${OPENOCD_COMMAND_TIMEOUT:-600}"
sim_pid=''
openocd_pid=''

mkdir -p "$run_dir"

# This binary is built with jtag_state_probe and FSDB visibility.  The fixed
# seed plus one RSP system-bus write makes the SerialTL framing failure
# reproducible without invoking a full GDB/ELF load sequence.
export JTAG_SIMV_NAME="${JTAG_SIMV_NAME:-simv-gls-sdf-framehistory}"

cleanup() {
  [[ -n "$openocd_pid" ]] && kill "$openocd_pid" 2>/dev/null || true
  [[ -n "$sim_pid" ]] && kill "$sim_pid" 2>/dev/null || true
  [[ -n "$openocd_pid" ]] && wait "$openocd_pid" 2>/dev/null || true
  [[ -n "$sim_pid" ]] && wait "$sim_pid" 2>/dev/null || true
}
trap cleanup EXIT

"$wrapper" +permissive +dramsim +dramsim_ini_dir="$dram_ini" \
  +max-cycles=0 +notimingcheck +ntb_random_seed=1 +jtag_rbb_enable=1 \
  +keep_jtag_sim_alive +sba_correlate_trace +serial_tl_packet_probe \
  +sba_path_trace +serial_tl_stall_probe +serial_tl_history_probe \
  +debug_control_ledger +dmi_protocol_ledger \
  +jtag_wave_window +fsdbfile="$run_dir/frame_misalignment.fsdb" \
  +permissive-off "$elf" >"$run_dir/sim.log" 2>"$run_dir/sim.stderr" &
sim_pid=$!

rbb_port=''
for _ in $(seq 1 90); do
  rbb_port="$(sed -n 's/.*Listening on port \([0-9][0-9]*\).*/\1/p' "$run_dir/sim.stderr" | tail -n 1)"
  [[ -n "$rbb_port" ]] && break
  kill -0 "$sim_pid"
  sleep 1
done
[[ -n "$rbb_port" ]]

"$openocd" \
  -d3 \
  -c 'adapter driver remote_bitbang' \
  -c "remote_bitbang host 127.0.0.1" \
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
  kill -0 "$openocd_pid"
  sleep 1
done
grep -q "Listening on port $gdb_port" "$run_dir/openocd.log"

rsp_client="${RSP_CLIENT:-${script_dir}/jtag_rsp_sba64_once.py}"
if [[ "$rsp_client" == */jtag-rsp-stress.py ]]; then
  python3 "$rsp_client" --port "$gdb_port" --elf "$elf" \
    --steps "${RSP_STEPS:-8}" --memory "${RSP_MEMORY:-8}" \
    --timeout "${RSP_TIMEOUT:-600}" \
    >"$run_dir/rsp.log" 2>&1
else
  python3 "$rsp_client" "$gdb_port" >"$run_dir/rsp.log" 2>&1
fi

sleep 2
