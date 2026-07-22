# Chipyard Gate-Level Simulation

This flow replaces the generated `ChipTop` RTL with the synthesized netlist
inside Chipyard's generated `TestHarness`.

Run from the [`tape-env`](https://github.com/SEU-ACAL/tape-env) Nix development shell:

Set the tape-env root before building:

```sh
export TAPE_ENV=/path/to/tape-env
```

```sh
make -C 3-Pre_PR_NETSIM gls_zero TECH=tsmc28 NETLIST_RUN=0720_1845
make -C 3-Pre_PR_NETSIM run_zero TECH=tsmc28 NETLIST_RUN=0720_1845 \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

`TECH` selects the standard-cell and SRAM Verilog models. Supported values are
`tsmc28` (the default) and `smic180`. The SMIC180 flow uses the SCC018UG UHD
RVT model and the SMIC SRAM models at the `ss_1.62_125` corner:

```sh
make -C 3-Pre_PR_NETSIM gls_zero TECH=smic180 NETLIST_RUN=<smic180-run>
make -C 3-Pre_PR_NETSIM run_zero TECH=smic180 NETLIST_RUN=<smic180-run> \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

Technology defaults may be overridden for a different installation or corner:

```sh
make -C 3-Pre_PR_NETSIM gls_zero TECH=smic180 \
  STD_CELL_MODEL=/path/to/standard-cell.v SRAM_ROOT=/path/to/sram-root \
  SRAM_CORNER=<corner> SRAM_MODEL_TEMPLATE='%s.v'
```

`SRAM_MODEL_TEMPLATE` is resolved below each macro directory. Its first `%s`
is replaced by the macro name and its optional second `%s` by `SRAM_CORNER`.
For example, TSMC28 uses `VERILOG/%s_%s.v`, while SMIC180 uses `%s.v`.

`gls_zero` builds a no-SDF simulation without VCS register-initialization
options. `run_zero` uses Chipyard's DRAMSim and ELF-loading arguments, with a
default timeout of 10,000,000 cycles.

For timing simulation, provide the matching SDF:

```sh
make -C 3-Pre_PR_NETSIM gls_sdf TECH=tsmc28 NETLIST_RUN=0720_1845 SDF=/path/to/ChipTop.sdf
make -C 3-Pre_PR_NETSIM run_sdf TECH=tsmc28 NETLIST_RUN=0720_1845 SDF=/path/to/ChipTop.sdf \
  BINARY=$TAPE_ENV/applications/tests/build/hello.riscv
```

Add `WAVEFORM=1` to both the build and run command to produce an FSDB under
`gen/<config>/<netlist-run>/`. The waveform build is separate from the default
build, so FSDB debug options are never enabled implicitly.
