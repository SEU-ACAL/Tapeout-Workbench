# ChipTop SMIC180 P&R Migration

This directory is an isolated migration target for the `ChipTop` SMIC180
implementation flow. It does not modify or reuse the TSMC28
`BACKEND/PR` project database.

## Known inputs

- Synthesized top: `ChipTop`, handoff run `0816_0804`
- Standard cells: SCC018UG UHD RVT, 1.62 V / 125 C setup corner
- I/O cells: SP018RP 6MT
- SRAMs: all eight `chipyard_sram_*` macro LEFs
- RC extraction: native SMIC QRC at SS 1.62 V / 125 C and FF 1.98 V / -40 C

Run the preflight from this directory:

```sh
tclsh scripts/preflight.tcl
```

The preflight intentionally blocks a full Innovus run until the floorplan
script provides the following:

1. A pad-ring DEF or a floorplan script which creates and places the pad ring.
2. `PVDD1R` and `PVSS1R` pad instances placed around the die and globally
   connected to `VDD` and `VSS`; add `PVDD2R`/`PVSS2R` only where pad-ring
   continuity requires them.

Do not use generic core `editPin` placement for SP018RP pad macros, and do not
reuse the TSMC28 library, QRC, tie, filler, tap, or PG scripts.
