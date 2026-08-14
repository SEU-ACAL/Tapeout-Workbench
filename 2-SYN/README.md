# DC Synthesis

Run this flow from inside the EDA container. Set `TAPE_ENV` to the tape-env
repository before invoking `run_core`.

## SMIC180 ROM IP

For a `TapeoutConfig` generated with `USE_SMIC180_ROM=1`, prepare the shared
ROM timing libraries once before synthesis:

```sh
./scripts/prepare_rom_libs.sh --smic180-rom-cache
```

The script reads the ROM IP from `/data2/smic180/rom-ip` and keeps the generated
DC `.db` files in `/data2/smic180/rom-ip/dc-libdb`. If the ROM Liberty inputs
and conversion script are unchanged, it exits without invoking Library Compiler.

ROMs are link-only hard macros. With `--tech smic180`, their timing `.db` files
are added to the DC link library automatically; do not add behavioral Verilog
models to the synthesis filelist:

```sh
config=chipyard.harness.TestHarness.TapeoutConfig
gen_dir="$TAPE_ENV/soc-generator/sims/vcs/generated-src/$config"

./run_core --tech smic180 \
  --source-code-home "$gen_dir" \
  --filelist "$gen_dir.top.f" \
  --top ChipTop \
  --sram-wrapper "$gen_dir/gen-collateral/$config.top.mems.v" \
  --clock-period 10.0 --run-id smic180-rom
```

Use the same `--run-id` as `NETLIST_RUN` when running gate-level simulation.
