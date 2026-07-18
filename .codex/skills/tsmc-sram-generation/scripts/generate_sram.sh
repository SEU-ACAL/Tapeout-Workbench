#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate_sram.sh --specs <physical_specs.txt> --output <staging_dir>

Specification rows: <macro_name> <depth> <width> <mux> <uhd|d127>
Comments and blank lines are ignored.
EOF
}

specs_file=""
output_dir=""
while (($#)); do
  case "$1" in
    --specs) specs_file="$2"; shift 2 ;;
    --output) output_dir="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

[[ -n "$specs_file" && -f "$specs_file" && -n "$output_dir" ]] || { usage >&2; exit 2; }
[[ ! -e "$output_dir" ]] || { echo "Output path already exists: $output_dir" >&2; exit 2; }

mc2_bin=/data2/TSMC28/Memory/1/tsmc_n28hpcpmc_20120200_110a/AN61001_20180125/TSMCHOME/sram/Compiler/tsmc_n28hpcpmc_20120200_110a/MC2_2012.02.00.d/bin
license_file=/data2/tools/license/license.dat
uhd_home=/data2/TSMC28/Memory/tsn28hpcpuhdspsram_20120200_170a/AN61001_20180125/TSMCHOME/sram/Compiler/tsn28hpcpuhdspsram_20120200_170a
d127_home=/data2/TSMC28/Memory/tsn28hpcpd127spsram_20120200_180a/AN61001_20180416/TSMCHOME/sram/Compiler/tsn28hpcpd127spsram_20120200_180a

for required_path in "$mc2_bin" "$license_file" "$uhd_home" "$d127_home"; do
  [[ -e "$required_path" ]] || { echo "Missing PDK resource: $required_path" >&2; exit 1; }
done

mkdir -p "$output_dir/uhd" "$output_dir/d127"
declare -A seen_names
while read -r macro_name depth width mux compiler ignored; do
  [[ -z "${macro_name:-}" || "$macro_name" == \#* ]] && continue
  [[ -z "${depth:-}" || -z "${width:-}" || -z "${mux:-}" || -z "${compiler:-}" || -n "${ignored:-}" ]] && {
    echo "Invalid specification row for $macro_name" >&2; exit 2;
  }
  [[ "$macro_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && "$depth" =~ ^[0-9]+$ && "$width" =~ ^[0-9]+$ && "$mux" =~ ^(1|2|4|8|16)$ ]] || {
    echo "Invalid macro name or numeric field: $macro_name" >&2; exit 2;
  }
  [[ -z "${seen_names[$macro_name]:-}" ]] || { echo "Duplicate macro name: $macro_name" >&2; exit 2; }
  seen_names[$macro_name]=1
  case "$compiler" in
    uhd|d127) printf '%s %s %s %s s\n' "$macro_name" "$depth" "$width" "$mux" >> "$output_dir/$compiler/config.txt" ;;
    *) echo "Unsupported compiler '$compiler' for $macro_name" >&2; exit 2 ;;
  esac
done < "$specs_file"

[[ -s "$output_dir/uhd/config.txt" || -s "$output_dir/d127/config.txt" ]] || { echo "No specifications found" >&2; exit 2; }

run_compiler() {
  local compiler="$1" compiler_home script options
  case "$compiler" in
    uhd)
      compiler_home="$uhd_home"
      script=tsn28hpcpuhdspsram_170a.pl
      options=(-NonBIST -NonBWEB -NonSLP -NonSD)
      ;;
    d127)
      compiler_home="$d127_home"
      script=tsn28hpcpd127spsram_180a.pl
      options=(-NonBIST -NonBWEB -NonAWT -NonSLP -NonSD)
      ;;
  esac
  [[ -s "$output_dir/$compiler/config.txt" ]] || return
  (
    cd "$output_dir/$compiler"
    PATH="$mc2_bin:$PATH" MC_HOME="$compiler_home" LM_LICENSE_FILE="$license_file" \
      perl "$compiler_home/$script" -NonTsmcName -file config.txt "${options[@]}"
  )
}

run_compiler uhd
run_compiler d127

while read -r macro_name depth width mux compiler; do
  [[ -z "${macro_name:-}" || "$macro_name" == \#* ]] && continue
  macro_root="$output_dir/$compiler/$macro_name"
  required_files=(
    "$macro_root/GDSII/$macro_name.gds"
    "$macro_root/LEF/$macro_name.lef"
    "$macro_root/SPICE/$macro_name.spi"
    "$macro_root/VERILOG/${macro_name}_ssg0p81v125c.v"
    "$macro_root/NLDM/${macro_name}_ssg0p81v125c.lib"
    "$macro_root/LOG/$macro_name.log"
  )
  for required_file in "${required_files[@]}"; do
    [[ -s "$required_file" ]] || { echo "Missing deliverable: $required_file" >&2; exit 1; }
  done
  rg -q 'Number of errors : 0, Number of warnings : 0' "$macro_root/LOG/$macro_name.log" || {
    echo "MC2 reported a failure for $macro_name" >&2; exit 1;
  }
  rg -q 'Normal Termination.' "$macro_root/LOG/$macro_name.log" || {
    echo "MC2 did not terminate normally for $macro_name" >&2; exit 1;
  }
  [[ -s "$output_dir/$compiler/$macro_name.cfg" ]] || { echo "Missing PDK-generated cfg for $macro_name" >&2; exit 1; }
done < "$specs_file"

echo "Validated SRAM deliverables: $output_dir"
