#!/usr/bin/env bash
# Run a PR flow command after removing only root-level tool session artifacts.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <flow command> [arguments...]" >&2
  exit 2
fi

pr_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
find "$pr_root" -maxdepth 1 -type f \
  \( -name 'innovus.log*' -o -name 'innovus.cmd*' -o -name 'flowtool.log*' \) \
  -print -delete

exec "$@"
