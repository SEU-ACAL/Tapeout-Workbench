# ChipTop STA And Power

This directory exports an SDF from the synthesized ChipTop netlist and reports
averaged power from a zero-delay gate-level simulation waveform.

Run the commands from the `ic_workbench` root. The zero-delay waveform must be
generated first with `WAVEFORM=1` in `3-Pre_PR_NETSIM`.

## Environment

Select the technology directly. `tsmc28` remains the default:

```sh
make -C 4-Pre_PR_STA_POWER power TECH=tsmc28 NETLIST_RUN=0720_1845
make -C 4-Pre_PR_STA_POWER power TECH=smic180 NETLIST_RUN=<smic180-run>
```

The SMIC180 configuration uses voltage-consistent standard-cell and S018SP
SRAM `SS 1.62V/125C` views.

Technology configuration files set `STD_CELL_DB`, `SRAM_ROOT`, `SRAM_CORNER`,
and the SRAM DB layout. All remain overridable from the command line for a
different characterized corner:

```sh
make -C 4-Pre_PR_STA_POWER power TECH=smic180 NETLIST_RUN=<smic180-run> \
  STD_CELL_DB=/path/to/stdcell.db SRAM_ROOT=/path/to/sram-root \
  SRAM_CORNER=<corner> SRAM_DB_TEMPLATE='%s_%s.db'
```

`PT_SHELL` defaults to `pt_shell`. Use PrimePower W-2024 or later: the
zero-delay waveform is FSDB 6.1, and W-2024 reads it natively. Set the shell
explicitly when it is not already in `PATH`:

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
make -C 4-Pre_PR_STA_POWER power TECH=tsmc28 NETLIST_RUN=0720_1845
```

The target reads `run-zero.fsdb` directly. It analyzes activity after `1000 ns`,
excluding reset startup. Override the activity window or waveform path when
needed:

```sh
make -C 4-Pre_PR_STA_POWER power NETLIST_RUN=0720_1845 \
  FSDB=/path/to/run-zero.fsdb POWER_START_NS=2000
```

Reports are written under `outputs/<technology>/<netlist-run>/zero-fsdb/`:

- `power_total.rpt`: total internal, switching, leakage, and total power
- `power_hierarchy.rpt`: hierarchy breakdown
- `power_verbose.rpt`: detailed power report
- `check_power.rpt`: library table and model coverage checks

This is a pre-layout averaged-power estimate. It does not use SDF or extracted
parasitics, so it is suitable for workload comparison but not signoff.

## SDF Export

Export MAXIMUM timing checks and delays for the matching synthesized netlist:

```sh
make -C 4-Pre_PR_STA_POWER sdf TECH=tsmc28 NETLIST_RUN=0720_1845
```

The default SDF output is
`3-Pre_PR_NETSIM/inputs/<netlist-run>/ChipTop.sdf`. Override `NETLIST`, `SDC`,
`SDF_OUT`, or `TOP` for another synthesis run.
