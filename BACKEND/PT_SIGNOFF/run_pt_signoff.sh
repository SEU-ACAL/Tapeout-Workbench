#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PR_ROOT="$ROOT/PR"
OUT_DIR="${OUT_DIR:-$ROOT/PT_SIGNOFF/outputs/smic180}"
REPORT_DIR="${REPORT_DIR:-$ROOT/PT_SIGNOFF/reports/smic180}"
NETLIST="${NETLIST:-$PR_ROOT/outputs/smic180/ChipTop.v}"
SDC="${SDC:-$ROOT/../2-SYN/outputs/0830_1319/ChipTop.sdc}"
SPEF_MAX="${SPEF_MAX:-$PR_ROOT/outputs/smic180/ChipTop.rc_setup.spef}"
SPEF_MIN="${SPEF_MIN:-$PR_ROOT/outputs/smic180/ChipTop.rc_hold.spef}"
PT="${PT:-/data2/tools/prime/R-2020.09-SP5-5/bin/pt_shell}"
STD="${SMIC180_LIB_ROOT:-/data2/smic180/SCC018UG_UHD_RVT_V0.4a/SCC018UG_UHD_RVT_V0p4a/liberty/1.8v}"
IO="${SMIC180_IO_LIB_ROOT:-/data2/smic180/SP018RP_V1p0b/syn/1p8v}"
SR="${SMIC180_SRAM_ROOT:-/data2/smic180/SRAM/S018SP_v0p1pc_CDK/SMIC180_S018SP_v0p1c_20260722}"
ROM="${SMIC180_ROM_ROOT:-/data2/smic180/rom-ip}"

[[ -x "$PT" ]] || { echo "Missing pt_shell: $PT" >&2; exit 2; }
for f in "$NETLIST" "$SDC" "$SPEF_MAX" "$SPEF_MIN"; do
  [[ -f "$f" ]] || { echo "Missing PT input: $f" >&2; exit 2; }
done

ss=("$STD/scc018ug_uhd_rvt_ss_v1p62_125c_ccs.db" "$IO/SP018RP_V1p0_max.db")
ff=("$STD/scc018ug_uhd_rvt_ff_v1p98_-40c_ccs.db" "$IO/SP018RP_V1p0_min.db")
for m in chipyard_sram_32x22 chipyard_sram_32x128 chipyard_sram_1024x8 chipyard_sram_512x64 chipyard_sram_512x8 chipyard_sram_64x22 chipyard_sram_64x21 chipyard_sram_512x32; do
  ss+=("$SR/$m/${m}_ss_1.62_125.db")
  ff+=("$SR/$m/${m}_ff_1.98_-40.db")
done
ss+=("$ROM/debugrom/S018VM_X8Y16D64_PM_ss_1.62_125.db" "$ROM/bootrom/S018VM_X64Y16D64_PM_ss_1.62_125.db")
ff+=("$ROM/debugrom/S018VM_X8Y16D64_PM_ff_1.98_-40.db" "$ROM/bootrom/S018VM_X64Y16D64_PM_ff_1.98_-40.db")
for f in "${ss[@]}" "${ff[@]}"; do
  [[ -f "$f" ]] || { echo "Missing Liberty DB: $f" >&2; exit 2; }
done

mkdir -p "$OUT_DIR" "$REPORT_DIR"
export PR_TOP=ChipTop PR_POSTROUTE_NETLIST="$NETLIST" PR_POSTROUTE_SDC="$SDC"
export PR_LIBS="${ss[*]}" PR_SPEF="$SPEF_MAX" PR_TRIPLET=max PR_DELAY_TYPE=max
export PR_SDF="$OUT_DIR/ChipTop.setup.sdf" PR_REPORT="$REPORT_DIR/pt_setup.rpt"
"$PT" -f "$ROOT/PT_SIGNOFF/scripts/postroute_sdf_pt.tcl" -output_log_file "$REPORT_DIR/pt_setup.log"

export PR_LIBS="${ff[*]}" PR_SPEF="$SPEF_MIN" PR_TRIPLET=min PR_DELAY_TYPE=min
export PR_SDF="$OUT_DIR/ChipTop.hold.sdf" PR_REPORT="$REPORT_DIR/pt_hold.rpt"
"$PT" -f "$ROOT/PT_SIGNOFF/scripts/postroute_sdf_pt.tcl" -output_log_file "$REPORT_DIR/pt_hold.log"

echo "PT_SIGNOFF status=pass setup_sdf=$OUT_DIR/ChipTop.setup.sdf hold_sdf=$OUT_DIR/ChipTop.hold.sdf"
