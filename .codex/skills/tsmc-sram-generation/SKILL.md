---
name: tsmc-sram-generation
description: Generate and validate TSMC 28nm single-port SRAM macros from Chipyard/FIRRTL mems.conf files. Use when analyzing `mems.conf`, decomposing `mrw` memories by `mask_gran`, selecting TSMC UDH or D127 SRAM compilers, invoking PDK `.pl` generation scripts, or checking generated GDS/LEF/SPICE/Verilog/NLDM deliverables.
---

# TSMC SRAM Generation

Generate physical macros only through the PDK-provided `.pl` scripts. Never hand-author an MC2 `.cfg`: the PDK script must create it and invoke `mc2-eu`.

## Workflow

1. Read every `mems.conf` entry.
2. Map `rw` to one `depth × width` macro.
3. Map logical `mrw` to independent single-port slices:
   - physical width = `mask_gran`
   - instance count = `width / mask_gran`
   - the wrapper routes write enable independently to every slice.
4. Resolve non-divisible widths or unsupported PDK sizes before generating. Document padding and tie off/ignore unused bits in the wrapper; do not silently change the interface.
5. Select a valid compiler/MUX from `references/pdk.md`.
6. Create a physical spec file, then run `scripts/generate_sram.sh` in a temporary directory.
7. Validate logs and deliverables before moving results to the final SRAM directory.

## Physical Spec File

Use whitespace-separated rows with no header:

```text
# macro_name depth width mux compiler
chipyard_sram_1024x17 1024 17 4 uhd
chipyard_sram_16384x64 16384 64 8 d127
```

Use stable names: `chipyard_sram_<depth>x<physical_width>`. Deduplicate identical physical specifications before generating.

## Generate

```bash
scripts/generate_sram.sh \
  --specs /path/to/physical_srams.txt \
  --output /path/to/staging
```

The script creates isolated compiler-specific working directories, lets PDK scripts generate all `.cfg` files, verifies all requested macros, then leaves the validated directories and automatic `.cfg` files under `--output`. Review them before moving them into the final SRAM library.

## Acceptance Criteria

For every macro, require:

```text
LOG/<macro>.log: Number of errors : 0, Number of warnings : 0
LOG/<macro>.log: Normal Termination.
GDSII/<macro>.gds
LEF/<macro>.lef
SPICE/<macro>.spi
VERILOG/<macro>_ssg0p81v125c.v
NLDM/<macro>_ssg0p81v125c.lib
```

Do not call `rm -rf` on an existing final SRAM library. Generate into a new staging path and move only verified artifacts.
