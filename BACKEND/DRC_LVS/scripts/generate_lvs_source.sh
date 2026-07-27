#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    printf 'Usage: %s <top_cell> <gate_level_verilog> <stdcell_spi> [run_dir]\n' "$0" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
verification_root=$(cd -- "$script_dir/.." && pwd)
top_cell=$1
verilog_file=$2
stdcell_spi=$3
run_dir=${4:-"$verification_root/runs/$top_cell"}

for required_file in "$verilog_file" "$stdcell_spi"; do
    if [[ ! -r "$required_file" ]]; then
        printf 'Missing required file: %s\n' "$required_file" >&2
        exit 1
    fi
done
if ! command -v v2lvs >/dev/null 2>&1; then
    printf 'Missing required command in the container PATH: v2lvs\n' >&2
    exit 1
fi

mkdir -p "$run_dir"
run_dir=$(readlink -f -- "$run_dir")
stdcell_spi=$(readlink -f -- "$stdcell_spi")

v2lvs \
    -v "$verilog_file" \
    -lsp "$stdcell_spi" \
    -s "$stdcell_spi" \
    -o "$run_dir/$top_cell.cdl" \
    -log "$run_dir/$top_cell.v2lvs.log" \
    -s0 VSS \
    -s1 VDD
