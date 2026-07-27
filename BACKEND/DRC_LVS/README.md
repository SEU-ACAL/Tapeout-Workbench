# DRC and LVS

This stage performs physical verification after P&R. It is intentionally
separate from `BACKEND/PR`: it consumes exported artifacts and never reads an
Innovus run directory implicitly.

All commands are run inside the default `test_env` container. The container
provides the Calibre executables, license configuration, and PDK mounts; the
scripts validate that `calibre` and `v2lvs` are available on `PATH` but do not
override container environment variables.

Inputs required for a design are:

- merged GDSII with the standard-cell GDS included;
- gate-level Verilog generated from the same final Innovus database;
- transistor-level standard-cell SPICE/CDL matching the GDS library;
- the PDK Calibre DRC and LVS decks.

The merged GDSII is exported by the PR stage to `BACKEND/PR/outputs/`. This
stage does not start Innovus or read an Innovus database.

## 1. Run DRC

```bash
bash scripts/run_drc.sh \
  multiplier_pipe3 \
  ../PR/outputs/multiplier_pipe3.gds
```

Key outputs are `multiplier_pipe3.drc.summary`,
`multiplier_pipe3.drc.results`, and `multiplier_pipe3.calibre_drc.log`.

## 2. Prepare Standard-Cell SPICE

For the installed TSMC28 `tcbn28hpcplusbwp7t40p140lvt_110a` library, extract
the SPICE file from its PDK archive into this stage:

```bash
bash scripts/extract_tsmc28_stdcell_spi.sh
```

It prints the resulting path:

```text
BACKEND/DRC_LVS/libraries/tcbn28hpcplusbwp7t40p140lvt_110a.spi
```

The file contains the transistor-level `.subckt` definitions that LVS needs;
functional Verilog is not an LVS source library.

## 3. Run LVS

Use the GDS and gate-level Verilog emitted by the same final P&R database.

```bash
bash scripts/run_lvs.sh \
  multiplier_pipe3 \
  ../PR/outputs/multiplier_pipe3.gds \
  ../PR/outputs/multiplier_pipe3.v \
  libraries/tcbn28hpcplusbwp7t40p140lvt_110a.spi
```

The script calls `v2lvs`, adds the PDK SPICE as an include, creates a local
copy of the LVS deck, and runs `calibre -lvs -hier`. Outputs include:

- `multiplier_pipe3.cdl`: source CDL generated from gate-level Verilog;
- `multiplier_pipe3.lvs.report`: comparison result and mismatches;
- `multiplier_pipe3.calibre_lvs.log`: Calibre transcript;
- `svdb/`: RVE query database.

An `INCORRECT` LVS result is a completed comparison, not a tool failure. Check
top-level `VDD/VSS` labels and ensure the GDS and Verilog came from the same
P&R database before debugging detailed mismatch entries.
