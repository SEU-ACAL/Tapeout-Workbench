#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
    printf 'Usage: %s <top_cell> <gds_file> <gate_level_verilog> <stdcell_spi> [run_dir]\n' "$0" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
verification_root=$(cd -- "$script_dir/.." && pwd)
top_cell=$1
gds_file=$2
verilog_file=$3
stdcell_spi=$4
run_dir=${5:-"$verification_root/runs/$top_cell"}
pdk_deck=/data2/TSMC28/PDK/Calibre/online/lvs_online/1P10M_5X2Y2Z/calibre.lvs

for required_file in "$gds_file" "$pdk_deck"; do
    if [[ ! -r "$required_file" ]]; then
        printf 'Missing required file: %s\n' "$required_file" >&2
        exit 1
    fi
done
if ! command -v calibre >/dev/null 2>&1; then
    printf 'Missing required command in the container PATH: calibre\n' >&2
    exit 1
fi

"$script_dir/generate_lvs_source.sh" "$top_cell" "$verilog_file" "$stdcell_spi" "$run_dir"

run_dir=$(readlink -f -- "$run_dir")
gds_file=$(readlink -f -- "$gds_file")
source_cdl="$run_dir/$top_cell.cdl"
deck_file="$run_dir/$top_cell.lvs"
mkdir -p "$run_dir/svdb"

cp "$pdk_deck" "$deck_file"
sed -i \
    -e "s|LAYOUT PRIMARY \"lvs_top\"|LAYOUT PRIMARY \"$top_cell\"|" \
    -e "s|LAYOUT PATH \"lvs_top.gds\"|LAYOUT PATH \"$gds_file\"|" \
    -e "s|SOURCE PRIMARY \"lvs_top\"|SOURCE PRIMARY \"$top_cell\"|" \
    -e "s|SOURCE PATH \"lvs_top.cdl\"|SOURCE PATH \"$source_cdl\"|" \
    -e "s|DRC RESULTS DATABASE \"calibre_drc.db\" ASCII|DRC RESULTS DATABASE \"$run_dir/$top_cell.lvs.drc.results\" ASCII|" \
    -e "s|DRC SUMMARY REPORT \"calibre_drc.sum\"|DRC SUMMARY REPORT \"$run_dir/$top_cell.lvs.drc.summary\"|" \
    -e "s|ERC RESULTS DATABASE \"calibre_erc.db\" ASCII|ERC RESULTS DATABASE \"$run_dir/$top_cell.lvs.erc.results\" ASCII|" \
    -e "s|ERC SUMMARY REPORT \"calibre_erc.sum\"|ERC SUMMARY REPORT \"$run_dir/$top_cell.lvs.erc.summary\"|" \
    -e "s|LVS REPORT \"lvs.rep\"|LVS REPORT \"$run_dir/$top_cell.lvs.report\"|" \
    -e "s|MASK SVDB DIRECTORY \"svdb\" QUERY|MASK SVDB DIRECTORY \"$run_dir/svdb\" QUERY|" \
    "$deck_file"

ulimit -n 16384 2>/dev/null || true
cd "$run_dir"
calibre -lvs -hier -turbo "${CALIBRE_TURBO:-8}" "$deck_file" |& tee "$top_cell.calibre_lvs.log"
