# ChipTop STA And Power

This directory exports an SDF from the synthesized ChipTop netlist and reports
averaged power from a zero-delay gate-level simulation waveform.

Run the commands from the `ic_workbench` root. The zero-delay waveform must be
generated first with `WAVEFORM=1` in `3-Pre_PR_NETSIM`.

## Environment

Set technology paths outside the Makefile:

```sh
export STD_CELL_DB=/path/to/standard-cell-power.db
export SRAM_ROOT=/path/to/sram/library/root
export SRAM_CORNER=ssg0p81v125c
export FSDB2SAIF=/path/to/verdi-w2024/bin/fsdb2saif
```

`FSDB2SAIF` must be from a Verdi release that supports the VCS-generated FSDB
version. The current zero-delay waveform is FSDB 6.1, which requires W-2024.

`PT_SHELL` defaults to `pt_shell`. Set it explicitly when the PrimeTime binary
is not already in `PATH`:

```sh
export PT_SHELL=/path/to/pt_shell
```

## Zero-Delay Power

Build and run the no-SDF gate-level simulation with waveform enabled. See
`3-Pre_PR_NETSIM/README.md` for its required tape-env and model variables.

```sh
make -C 3-Pre_PR_NETSIM gls_zero NETLIST_RUN=0720_1845 WAVEFORM=1
make -C 3-Pre_PR_NETSIM run_zero NETLIST_RUN=0720_1845 WAVEFORM=1 \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

Run averaged power analysis:

```sh
make -C 4-Pre_PR_STA_POWER power NETLIST_RUN=0720_1845
```

The target converts `run-zero.fsdb` to SAIF only when the waveform is newer
than the existing SAIF. It analyzes activity after `1000 ns`, excluding reset
startup. Override the activity window or waveform path when needed:

```sh
make -C 4-Pre_PR_STA_POWER power NETLIST_RUN=0720_1845 \
  FSDB=/path/to/run-zero.fsdb POWER_START_NS=2000
```

Reports are written under `outputs/<netlist-run>/zero-fsdb/`:

- `power_total.rpt`: total internal, switching, leakage, and total power
- `power_hierarchy.rpt`: hierarchy breakdown
- `power_verbose.rpt`: detailed power report
- `check_power.rpt`: library table and model coverage checks
- `activity_inconsistent.rpt`: conflicting SAIF annotations, if present

This is a pre-layout averaged-power estimate. It does not use SDF or extracted
parasitics, so it is suitable for workload comparison but not signoff.

## SDF Export

Export MAXIMUM timing checks and delays for the matching synthesized netlist:

```sh
make -C 4-Pre_PR_STA_POWER sdf NETLIST_RUN=0720_1845
```

The default SDF output is
`3-Pre_PR_NETSIM/inputs/<netlist-run>/ChipTop.sdf`. Override `NETLIST`, `SDC`,
`SDF_OUT`, or `TOP` for another synthesis run.
