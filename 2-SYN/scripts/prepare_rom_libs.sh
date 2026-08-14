#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare_rom_libs.sh --out-dir <directory> <rom.lib> [<rom.lib> ...]

       prepare_rom_libs.sh --smic180-rom-cache [directory]

Converts generated ROM Liberty timing views to Synopsys .db files and writes
<directory>/rom-libs.db.f containing their absolute paths. Run this script
inside the EDA container, where Library Compiler is available locally.
The shared-cache form defaults to /data2/smic180/rom-ip, reads the BootROM and
Debug ROM SS Liberty views there, and writes <cache>/dc-libdb/rom-libs.db.f.
EOF
}

shared_cache=0
if [[ "${1:-}" == "--smic180-rom-cache" ]]; then
  shared_cache=1
  cache_dir=${SMIC180_ROM_CACHE_DIR:-/data2/smic180/rom-ip}
  if [[ $# -ge 2 && "${2:-}" != --* ]]; then
    cache_dir=$2
    shift 2
  else
    shift
  fi
  rom_corner=${SMIC180_ROM_LIB_CORNER:-ss_1.62_125}
  out_dir=$cache_dir/dc-libdb
  set -- \
    "$cache_dir/bootrom/S018VM_X512Y16D64_PM_$rom_corner.lib" \
    "$cache_dir/debugrom/S018VM_X8Y16D64_PM_$rom_corner.lib"
elif [[ "${1:-}" == "--out-dir" && $# -ge 3 ]]; then
  out_dir=$2
  shift 2
else
  usage >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lc_shell="${LC_SHELL:-/data2/tools/lc/R-2020.09-SP5/bin/lc_shell}"
converter_tcl="$script_dir/lib-to-db.tcl"

lib_name_from_file() {
  awk '/^[[:space:]]*library[[:space:]]*\(/ {
    line = $0
    sub(/^[[:space:]]*library[[:space:]]*\([[:space:]]*/, "", line)
    sub(/^"/, "", line)
    sub(/".*/, "", line)
    sub(/\).*/, "", line)
    sub(/[[:space:]].*/, "", line)
    print line
    exit
  }' "$1"
}

if [[ $shared_cache -eq 1 ]]; then
  umask 000
fi
mkdir -p "$out_dir"
if [[ $shared_cache -eq 1 ]]; then
  cache_dir=$(dirname "$out_dir")
  cache_mode=$(stat -c '%a' "$cache_dir")
  out_mode=$(stat -c '%a' "$out_dir")
  [[ $cache_mode == 1777 ]] || chmod 1777 "$cache_dir"
  [[ $out_mode == 777 ]] || chmod 0777 "$out_dir"
fi
out_dir="$(cd "$out_dir" && pwd)"
db_filelist="$out_dir/rom-libs.db.f"
lock_file="$out_dir/.rom-libs.lock"
exec 9>>"$lock_file"
if [[ $shared_cache -eq 1 ]]; then
  [[ $(stat -c '%a' "$lock_file") == 666 ]] || chmod 0666 "$lock_file"
fi

# A shared cache may be prepared concurrently by several users. Hold the lock
# through the validation and any required conversion so readers never see a
# partially updated file list or database. Append-mode opening preserves the
# lock inode and its timestamp when the ROM cache is already current.
flock 9

[[ -f "$converter_tcl" ]] || { echo "Missing Library Compiler Tcl script: $converter_tcl" >&2; exit 3; }
converter_sha256=$(sha256sum "$converter_tcl" | awk '{ print $1 }')

lib_files=()
lib_names=()
db_files=()
db_stamps=()
db_stamp_contents=()
db_needs_conversion=()
all_databases_current=1

for lib_file in "$@"; do
  [[ -f "$lib_file" ]] || { echo "Missing ROM Liberty file: $lib_file" >&2; exit 2; }
  lib_name="$(lib_name_from_file "$lib_file")"
  [[ -n "$lib_name" ]] || { echo "Could not determine Liberty library name: $lib_file" >&2; exit 3; }

  out_file="$out_dir/$(basename "${lib_file%.lib}").db"
  stamp_file="$out_file.input"
  lib_sha256=$(sha256sum "$lib_file" | awk '{ print $1 }')
  stamp_content=$(printf '%s\n' \
    'format=1' \
    "library_file=$(realpath "$lib_file")" \
    "library_name=$lib_name" \
    "library_sha256=$lib_sha256" \
    "converter_sha256=$converter_sha256")

  lib_files+=("$lib_file")
  lib_names+=("$lib_name")
  db_files+=("$out_file")
  db_stamps+=("$stamp_file")
  db_stamp_contents+=("$stamp_content")
  if [[ -s "$out_file" && -f "$stamp_file" ]] && \
    cmp -s <(printf '%s\n' "$stamp_content") "$stamp_file"; then
    db_needs_conversion+=(0)
  else
    db_needs_conversion+=(1)
    all_databases_current=0
  fi
done

if [[ $all_databases_current -eq 1 && -f "$db_filelist" ]] && \
  cmp -s <(printf '%s\n' "${db_files[@]}") "$db_filelist"; then
  echo "ROM timing libraries already current: $db_filelist"
  exit 0
fi

for index in "${!db_files[@]}"; do
  if [[ ${db_needs_conversion[$index]} -eq 0 ]]; then
    continue
  fi

  [[ -x "$lc_shell" ]] || { echo "Missing Library Compiler: $lc_shell" >&2; exit 3; }
  out_file=${db_files[$index]}
  tmp_out_file="$out_file.tmp.$$"
  rm -f "$tmp_out_file"
  LIB_FILE="${lib_files[$index]}" OUT_DB="$tmp_out_file" LIB_NAME="${lib_names[$index]}" \
    "$lc_shell" -64 -f "$converter_tcl"
  [[ -s "$tmp_out_file" ]] || { echo "Library conversion did not produce: $out_file" >&2; exit 4; }
  mv -f "$tmp_out_file" "$out_file"

  stamp_file=${db_stamps[$index]}
  tmp_stamp_file="$stamp_file.tmp.$$"
  printf '%s\n' "${db_stamp_contents[$index]}" > "$tmp_stamp_file"
  mv -f "$tmp_stamp_file" "$stamp_file"
  if [[ $shared_cache -eq 1 ]]; then
    chmod a+rw "$out_file" "$stamp_file"
  fi
done

if [[ ! -f "$db_filelist" ]] || ! cmp -s <(printf '%s\n' "${db_files[@]}") "$db_filelist"; then
  tmp_filelist="$out_dir/.rom-libs.db.f.tmp.$$"
  printf '%s\n' "${db_files[@]}" > "$tmp_filelist"
  mv -f "$tmp_filelist" "$db_filelist"
  if [[ $shared_cache -eq 1 ]]; then
    chmod a+rw "$db_filelist"
  fi
fi

echo "Prepared ROM timing libraries: $db_filelist"
