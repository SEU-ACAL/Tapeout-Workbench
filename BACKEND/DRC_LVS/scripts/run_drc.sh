#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    printf 'Usage: %s <top_cell> <gds_file> [run_dir]\n' "$0" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
verification_root=$(cd -- "$script_dir/.." && pwd)
top_cell=$1
gds_file=$2
run_dir=${3:-"$verification_root/runs/$top_cell"}
pdk_deck=/data2/TSMC28/PDK/Calibre/online/drc_online/1P10M_5X2Y2Z/calibre.drc

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

mkdir -p "$run_dir"
run_dir=$(readlink -f -- "$run_dir")
gds_file=$(readlink -f -- "$gds_file")
deck_file="$run_dir/$top_cell.drc"

cp "$pdk_deck" "$deck_file"
sed -i \
    -e "s|LAYOUT PATH \"GDSFILENAME\"|LAYOUT PATH \"$gds_file\"|" \
    -e "s|LAYOUT PRIMARY \"TOPCELLNAME\"|LAYOUT PRIMARY \"$top_cell\"|" \
    -e "s|DRC RESULTS DATABASE \"DRC_RES.db\"|DRC RESULTS DATABASE \"$run_dir/$top_cell.drc.results\" ASCII|" \
    -e "s|DRC SUMMARY REPORT \"DRC.rep\"|DRC SUMMARY REPORT \"$run_dir/$top_cell.drc.summary\"|" \
    "$deck_file"

ulimit -n 16384 2>/dev/null || true
cd "$run_dir"
calibre -drc -hier -turbo "${CALIBRE_TURBO:-8}" "$deck_file" |& tee "$top_cell.calibre_drc.log"
