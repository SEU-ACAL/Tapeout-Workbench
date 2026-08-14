#!/usr/bin/env bash
set -euo pipefail

required=(NETLIST BUILD_DIR TOP TEST_DRIVER SDF_ANNOTATE STD_CELL_MODEL SRAM_ROOT SRAM_CORNER SRAM_MODEL_TEMPLATE ROM_MODEL_FILELIST HARNESS_FILELIST SRAM_FILELIST ROM_FILELIST GLS_FILELIST)
for variable_name in "${required[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required environment variable: ${variable_name}" >&2
    exit 2
  fi
done

if [[ "${SRAM_MODEL_TEMPLATE}" != *%s* ]]; then
  echo "SRAM_MODEL_TEMPLATE must contain %s for the SRAM macro name" >&2
  exit 2
fi

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
if command -v rg >/dev/null 2>&1; then
  sram_names_command=(rg -o 'chipyard_sram_[[:alnum:]_]+')
else
  sram_names_command=(grep -Eo 'chipyard_sram_[[:alnum:]_]+')
fi
while IFS= read -r macro_name; do
  macro_model_relative="${SRAM_MODEL_TEMPLATE/\%s/${macro_name}}"
  macro_model_relative="${macro_model_relative/\%s/${SRAM_CORNER}}"
  if [[ "${macro_model_relative}" == *%s* ]]; then
    echo "SRAM_MODEL_TEMPLATE supports only macro-name and corner substitutions: ${SRAM_MODEL_TEMPLATE}" >&2
    exit 2
  fi
  macro_model="${SRAM_ROOT}/${macro_name}/${macro_model_relative}"
  [[ -f "${macro_model}" ]] || { echo "Missing SRAM Verilog model: ${macro_model}" >&2; exit 2; }
  printf '%s\n' "${macro_model}" >> "${SRAM_FILELIST}"
done < <("${sram_names_command[@]}" "${NETLIST}" | sort -u)

: > "${ROM_FILELIST}"
if command -v rg >/dev/null 2>&1; then
  rom_macro_search=(rg -q 'S018VM_[[:alnum:]_$]+')
else
  rom_macro_search=(grep -Eq 'S018VM_[[:alnum:]_$]+')
fi
if "${rom_macro_search[@]}" "${NETLIST}"; then
  [[ -f "${ROM_MODEL_FILELIST}" ]] || {
    echo "Netlist contains an S018VM ROM macro but the ROM model filelist is missing: ${ROM_MODEL_FILELIST}" >&2
    exit 2
  }
  while IFS= read -r rom_model || [[ -n "${rom_model}" ]]; do
    [[ -z "${rom_model}" || "${rom_model}" == \#* ]] && continue
    [[ -f "${rom_model}" ]] || { echo "Missing ROM Verilog model: ${rom_model}" >&2; exit 2; }
    printf '%s\n' "${rom_model}" >> "${ROM_FILELIST}"
  done < "${ROM_MODEL_FILELIST}"
  [[ -s "${ROM_FILELIST}" ]] || {
    echo "ROM model filelist is empty: ${ROM_MODEL_FILELIST}" >&2
    exit 2
  }
fi

{
  cat "${HARNESS_FILELIST}"
  printf '%s\n' "${TEST_DRIVER}" "${SDF_ANNOTATE}" "${NETLIST}" "${STD_CELL_MODEL}"
  cat "${SRAM_FILELIST}"
  cat "${ROM_FILELIST}"
} > "${GLS_FILELIST}"

printf 'Generated GLS filelist: %s\n' "${GLS_FILELIST}"
