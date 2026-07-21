#!/usr/bin/env bash
set -euo pipefail

required=(NETLIST BUILD_DIR TOP TEST_DRIVER SDF_ANNOTATE STD_CELL_MODEL SRAM_ROOT SRAM_CORNER HARNESS_FILELIST SRAM_FILELIST GLS_FILELIST)
for variable_name in "${required[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required environment variable: ${variable_name}" >&2
    exit 2
  fi
done

model_filelist="${BUILD_DIR}/${BUILD_DIR##*/}.model.f"
if [[ ! -f "${model_filelist}" ]]; then
  echo "Missing Chipyard model filelist: ${model_filelist}" >&2
  exit 2
fi

for input_file in "${NETLIST}" "${TEST_DRIVER}" "${SDF_ANNOTATE}" "${STD_CELL_MODEL}"; do
  if [[ ! -f "${input_file}" ]]; then
    echo "Missing GLS input: ${input_file}" >&2
    exit 2
  fi
done

mkdir -p "$(dirname "${HARNESS_FILELIST}")"

netlist_modules="$(mktemp)"
trap 'rm -f "${netlist_modules}"' EXIT
sed -nE 's/^[[:space:]]*module[[:space:]]+([[:alnum:]_$]+).*/\1/p' "${NETLIST}" | sort -u > "${netlist_modules}"
if ! grep -qx "${TOP}" "${netlist_modules}"; then
  echo "Netlist ${NETLIST} does not define top module ${TOP}" >&2
  exit 2
fi

: > "${HARNESS_FILELIST}"
while IFS= read -r source_file; do
  [[ -z "${source_file}" ]] && continue
  [[ -f "${source_file}" ]] || { echo "Missing source listed by ${model_filelist}: ${source_file}" >&2; exit 2; }

  source_modules="$(sed -nE 's/^[[:space:]]*module[[:space:]]+([[:alnum:]_$]+).*/\1/p' "${source_file}" | sort -u)"
  if [[ -n "${source_modules}" ]] && comm -12 <(printf '%s\n' "${source_modules}") "${netlist_modules}" | grep -q .; then
    continue
  fi
  printf '%s\n' "${source_file}" >> "${HARNESS_FILELIST}"
done < "${model_filelist}"

awk '!seen[$0]++' "${HARNESS_FILELIST}" > "${HARNESS_FILELIST}.tmp"
mv "${HARNESS_FILELIST}.tmp" "${HARNESS_FILELIST}"

if ! grep -Fxq "${BUILD_DIR}/gen-collateral/TestHarness.sv" "${HARNESS_FILELIST}"; then
  echo "Generated harness filelist does not contain TestHarness.sv" >&2
  exit 2
fi

: > "${SRAM_FILELIST}"
while IFS= read -r macro_name; do
  macro_model="${SRAM_ROOT}/${macro_name}/VERILOG/${macro_name}_${SRAM_CORNER}.v"
  [[ -f "${macro_model}" ]] || { echo "Missing SRAM Verilog model: ${macro_model}" >&2; exit 2; }
  printf '%s\n' "${macro_model}" >> "${SRAM_FILELIST}"
done < <(rg -o 'chipyard_sram_[[:alnum:]_]+' "${NETLIST}" | sort -u)

{
  cat "${HARNESS_FILELIST}"
  printf '%s\n' "${TEST_DRIVER}" "${SDF_ANNOTATE}" "${NETLIST}" "${STD_CELL_MODEL}"
  cat "${SRAM_FILELIST}"
} > "${GLS_FILELIST}"

printf 'Generated GLS filelist: %s\n' "${GLS_FILELIST}"
