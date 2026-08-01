# ChipTop STA And Power

This directory verifies the SDF exported by DC from the synthesized ChipTop netlist and reports
averaged power from a zero-delay gate-level simulation waveform.

Run the commands from the `ic_workbench` root. The zero-delay waveform must be
generated first with `WAVEFORM=1` in `3-Pre_PR_NETSIM`.

## Environment

Select the technology directly. `smic180` is the default for the latest
`0731_0611` netlist package:

```sh
make -C 4-Pre_PR_STA_POWER power TECH=smic180 NETLIST_RUN=0731_0611
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

`PT_SHELL` defaults to `pt_shell`. Use a PrimeTime PX/PrimePower version that
reads FSDB natively. Set the shell explicitly when it is not already in `PATH`:

```sh
export PT_SHELL=/path/to/pt_shell
```

## SDF Simulation Power

The default flow uses the DC-generated SDF at `2-SYN/outputs/0731_0611/ChipTop.sdf`,
runs an SDF-annotated gate-level simulation, and reads that FSDB directly for
averaged power. It does not create or consume VCD, VPD, or SAIF files.

```sh
make -C 4-Pre_PR_STA_POWER sdf_power TECH=smic180 \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

Run the two stages explicitly when needed:

```sh
make -C 4-Pre_PR_STA_POWER sdf TECH=smic180 NETLIST_RUN=0731_0611
make -C 3-Pre_PR_NETSIM gls_sdf TECH=smic180 NETLIST_RUN=0731_0611 WAVEFORM=1
make -C 3-Pre_PR_NETSIM run_sdf TECH=smic180 NETLIST_RUN=0731_0611 WAVEFORM=1 \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
make -C 4-Pre_PR_STA_POWER power TECH=smic180 NETLIST_RUN=0731_0611
```

The target reads `run-sdf.fsdb` directly and preserves SDF event timing. It
analyzes activity after `1000 ns`, excluding reset startup. Override the
activity window or waveform path when needed:

```sh
make -C 4-Pre_PR_STA_POWER power NETLIST_RUN=0731_0611 \
  FSDB=/path/to/run-sdf.fsdb POWER_START_NS=2000
```

Reports are written under `outputs/<technology>/<netlist-run>/sdf-fsdb/`:

- `power_total.rpt`: total internal, switching, leakage, and total power
- `power_hierarchy.rpt`: hierarchy breakdown
- `power_verbose.rpt`: detailed power report
- `check_power.rpt`: library table and model coverage checks

This is an SDF-based, pre-layout averaged-power estimate. It is suitable for
workload comparison but is not extracted-parasitic signoff.

## SDF Export

Export MAXIMUM timing checks and delays for the matching synthesized netlist:

```sh
make -C 4-Pre_PR_STA_POWER sdf TECH=smic180 NETLIST_RUN=0731_0611
```

The default SDF output is `../2-SYN/outputs/<netlist-run>/ChipTop.sdf`; it is
written by DC during synthesis. Override
`3-Pre_PR_NETSIM/inputs/<netlist-run>/ChipTop.sdf`. Override `NETLIST`, `SDC`,
`SDF_OUT`, or `TOP` for another synthesis run.
