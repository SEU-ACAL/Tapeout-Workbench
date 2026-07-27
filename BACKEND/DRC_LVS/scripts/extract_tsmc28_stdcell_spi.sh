#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
verification_root=$(cd -- "$script_dir/.." && pwd)
destination_dir=${1:-"$verification_root/libraries"}
archive=/data2/TSMC28/logic/tcbn28hpcplusbwp7t40p140lvt_180b/AN61001_20180509/tcbn28hpcplusbwp7t40p140lvt_110a_spi.tar.gz
member=TSMCHOME/digital/Back_End/spice/tcbn28hpcplusbwp7t40p140lvt_110a/tcbn28hpcplusbwp7t40p140lvt_110a.spi

if [[ ! -r "$archive" ]]; then
    printf 'Missing standard-cell SPICE archive: %s\n' "$archive" >&2
    exit 1
fi

mkdir -p "$destination_dir"
destination_dir=$(readlink -f -- "$destination_dir")
tar -xzf "$archive" -C "$destination_dir" --strip-components=5 "$member"
printf '%s\n' "$destination_dir/tcbn28hpcplusbwp7t40p140lvt_110a.spi"
