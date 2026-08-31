#!/usr/bin/env bash
set -euo pipefail

# Deterministic SDF GLS reproducer for one 64-bit system-bus access.  Keeping
# the access inside OpenOCD removes GDB/RSP negotiation and its DMI polling.
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
sim_pid=''

mkdir -p "$run_dir"
export JTAG_SIMV_NAME="${JTAG_SIMV_NAME:-simv-gls-sdf-framehistory}"

cleanup() {
  [[ -n "$sim_pid" ]] && kill "$sim_pid" 2>/dev/null || true
  [[ -n "$sim_pid" ]] && wait "$sim_pid" 2>/dev/null || true
}
trap cleanup EXIT

"$wrapper" +permissive +dramsim +dramsim_ini_dir="$dram_ini" \
  +max-cycles=0 +notimingcheck +ntb_random_seed=1 +jtag_rbb_enable=1 \
  +keep_jtag_sim_alive +sba_correlate_trace +serial_tl_packet_probe \
  +sba_path_trace +serial_tl_stall_probe +serial_tl_history_probe \
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

# A 64-bit write creates the exact SBA transaction used in the prior failing
# RSP run, but there is no GDB state query or packet acknowledgement traffic.
timeout 150 "$openocd" \
  -c 'adapter driver remote_bitbang' \
  -c 'remote_bitbang host 127.0.0.1' \
  -c "remote_bitbang port $rbb_port" \
  -c 'transport select jtag' \
  -c 'gdb_port disabled' \
  -c 'telnet_port disabled' \
  -c 'tcl_port disabled' \
  -c 'jtag newtap riscv cpu -irlen 5' \
  -c 'target create riscv.cpu riscv -chain-position riscv.cpu' \
  -c 'reset_config none' \
  -c 'riscv set_mem_access sysbus' \
  -c 'riscv set_reset_timeout_sec 30' \
  -c 'riscv set_command_timeout_sec 90' \
  -c init \
  -c halt \
  -c 'echo SBA64_DIRECT_BEGIN' \
  -c 'write_memory 0x80000000 64 {0x1122334455667788}' \
  -c 'echo SBA64_DIRECT_DONE' \
  -c shutdown >"$run_dir/openocd.log" 2>&1 || true

sleep 2
