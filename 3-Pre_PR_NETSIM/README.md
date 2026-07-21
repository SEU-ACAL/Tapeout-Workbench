# Chipyard Gate-Level Simulation

This flow replaces the generated `ChipTop` RTL with the synthesized netlist
inside Chipyard's generated `TestHarness`.

Run from the [`tape-env`](https://github.com/SEU-ACAL/tape-env) Nix development shell:

Set the tape-env root and technology model paths before building:

```sh
export TAPE_ENV=/path/to/tape-env
export STD_CELL_MODEL=/path/to/standard-cell.v
export SRAM_ROOT=/path/to/sram/models
export SRAM_CORNER=ssg0p81v125c
```

```sh
make -C 3-Pre_PR_NETSIM gls_zero NETLIST_RUN=0720_1845
make -C 3-Pre_PR_NETSIM run_zero NETLIST_RUN=0720_1845 \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

`gls_zero` builds a no-SDF simulation without VCS register-initialization
options. `run_zero` uses Chipyard's DRAMSim and ELF-loading arguments, with a
default timeout of 10,000,000 cycles.

For timing simulation, provide the matching SDF:

```sh
make -C 3-Pre_PR_NETSIM gls_sdf NETLIST_RUN=0720_1845 SDF=/path/to/ChipTop.sdf
make -C 3-Pre_PR_NETSIM run_sdf NETLIST_RUN=0720_1845 SDF=/path/to/ChipTop.sdf \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

Add `WAVEFORM=1` to both the build and run command to produce an FSDB under
`gen/<config>/<netlist-run>/`. The waveform build is separate from the default
build, so FSDB debug options are never enabled implicitly.
