# TSMC28 SRAM PDK Reference

## Common Environment

```text
MC2_BIN=/data2/TSMC28/Memory/1/tsmc_n28hpcpmc_20120200_110a/AN61001_20180125/TSMCHOME/sram/Compiler/tsmc_n28hpcpmc_20120200_110a/MC2_2012.02.00.d/bin
LM_LICENSE_FILE=/data2/tools/license/license.dat
```

## UDH Single-Port SRAM

```text
Compiler: tsn28hpcpuhdspsram_20120200_170a
MCO directory: /data2/TSMC28/Memory/tsn28hpcpuhdspsram_20120200_170a/AN61001_20180125/TSMCHOME/sram/Compiler/tsn28hpcpuhdspsram_20120200_170a
Script: tsn28hpcpuhdspsram_170a.pl
```

Valid non-redundant ranges, segment `s`:

| MUX | Depth | Width |
| --- | --- | --- |
| 1 | 8, 12, 16 … 128 | even 16 … 288 |
| 2 | 16, 24, 32 … 256 | 8 … 144 |
| 4 | 32, 48, 64 … 2048 | 8 … 144 |

Use UDH for small and medium macros when the requested size is valid.

## D127 Single-Port SRAM

```text
Compiler: tsn28hpcpd127spsram_20120200_180a
MCO directory: /data2/TSMC28/Memory/tsn28hpcpd127spsram_20120200_180a/AN61001_20180416/TSMCHOME/sram/Compiler/tsn28hpcpd127spsram_20120200_180a
Script: tsn28hpcpd127spsram_180a.pl
```

Valid non-redundant ranges, segment `s`:

| MUX | Depth | Width |
| --- | --- | --- |
| 4 | 32, 48 … 8192 | 8 … 144 |
| 8 | 64, 96 … 16384 | 4 … 72 |
| 16 | 4096, 4224 … 32768 | 2 … 39 |

Use D127 for deep macros beyond the UDH range. Do not use `NWORD/NMUX` values 260, 772, 1284, or 1796.

## PDK Feature Options

Pass these to produce a minimal single-port macro:

```text
-NonBIST  disable built-in self-test interface
-NonBWEB  disable bit-level write mask interface
-NonSLP   disable sleep mode
-NonSD    disable shutdown mode
-NonAWT   disable asynchronous write-through (D127 only)
```

Keep `BWEB` disabled only when MRW semantics are implemented by independent full-width slices. Otherwise preserve bit-write functionality.
