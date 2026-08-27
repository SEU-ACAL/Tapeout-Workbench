# IC Workbench 使用说明

本文档是仓库顶层的中文操作入口。所有示例命令都从仓库根目录
`/data1/GB/ic_workbench` 执行；命令中的 `<...>` 需要替换为实际值。已有的
子目录 README 仍然保留，但以本文档的命令和脚本接口为准。

## 1. 流程总览

```text
0-RTL  RTL 源码
  -> 1-SIM           RTL 仿真
  -> 2-SYN           Design Compiler 综合，生成网表/SDC/SDF
  -> 3-Pre_PR_NETSIM 门级仿真（可选 SDF）
  -> 4-Pre_PR_STA_POWER STA、SDF 校验和功耗
  -> BACKEND/PR      Innovus 布局布线
  -> BACKEND/RC_EXTRACT StarRC 寄生参数提取（TSMC28）
  -> BACKEND/DRC_LVS  Calibre DRC/LVS
  -> FM               Formality 等价性检查（旧 shift_reg 示例）
```

## 2. 环境准备

不同阶段使用不同 EDA 容器和许可证。进入项目容器后，先确认工具在
`PATH` 中：

```bash
cd /data1/GB/ic_workbench
docker exec -it gb_env bash
innovus -version
dc_shell -version
vcs -ID
pt_shell -version
calibre -version
```

门级仿真和 Chipyard CI 必须在 `tape-env` Nix shell 中运行：

```bash
cd /data1/GB/ic_workbench
export TAPE_ENV=/path/to/tape-env
export CHIPYARD_ROOT=/data1/GB/chipyard   # Chipyard 不在默认路径时设置
nix develop "$TAPE_ENV"
```

如果工具安装路径不是项目脚本中的默认路径，请通过命令行变量覆盖，详见
各阶段命令。

## 3. RTL 仿真：`1-SIM`

这是 `tb_shift_reg` 的 VCS 仿真。`1-SIM/Makefile` 当前使用绝对路径
`/data2/EDA_DOCKER/ic_workbench/...`；若本机路径不同，请先修改 Makefile
中的 `SIM_FILES`。

```bash
cd /data1/GB/ic_workbench
make -C 1-SIM comp                 # 编译
make -C 1-SIM run                  # 运行，生成 sim.log
make -C 1-SIM verdi                # 用 Verdi 打开波形
make -C 1-SIM clean                # 清理 VCS/波形临时文件
```

RTL 源码位于 `0-RTL/`；修改 RTL 后重新执行上述 `comp` 和 `run` 即可。该目录
本身没有独立的构建脚本。

## 4. 综合：`2-SYN`

综合入口是 `2-SYN/run_core`，默认顶层为 `ChipTop`、工艺为 `tsmc28`、时钟
周期为 `10.0 ns`。输出写入 `2-SYN/outputs/<run-id>/`，报告写入
`2-SYN/rpt/<run-id>/`。

先查看所有参数：

```bash
cd /data1/GB/ic_workbench
2-SYN/run_core --help
```

使用默认配置综合：

```bash
cd /data1/GB/ic_workbench/2-SYN
./run_core --run-id <run-name>
```

指定 Chipyard 生成目录、文件列表、顶层和时钟周期：

```bash
cd /data1/GB/ic_workbench/2-SYN
./run_core \
  --source-code-home /path/to/generated-src/chipyard.harness.TestHarness.TapeoutConfig \
  --filelist /path/to/chipyard.harness.TestHarness.TapeoutConfig.top.f \
  --top ChipTop \
  --clock-period 2.0 \
  --run-id chiptop_smic180_0816 \
  --tech smic180 \
  --sram-wrapper /path/to/top.mems.v
```

常用产物为 `ChipTop.v`、`ChipTop.sdc`、`ChipTop.sdf`、`ChipTop.ddc` 和
`link_library.txt`。`--tech smic180` 时，标准单元、SRAM、ROM 和 IO 库路径
由 `2-SYN/scripts/tech/smic180.tcl` 定义，也可按该文件修改。

## 5. 门级仿真：`3-Pre_PR_NETSIM`

以下命令在 Chipyard Nix shell 中执行。`TECH` 支持 `smic180` 和 `tsmc28`；
`NETLIST_RUN` 必须与 `2-SYN/outputs/<run>/` 一致。

无 SDF 编译和运行：

```bash
cd /data1/GB/ic_workbench
make -C 3-Pre_PR_NETSIM gls_zero TECH=smic180 NETLIST_RUN=<run-name>
make -C 3-Pre_PR_NETSIM run_zero \
  TECH=smic180 NETLIST_RUN=<run-name> \
  BINARY="$TAPE_ENV/applications/tests/build/hello.riscv"
```

带 SDF 编译和运行（`SDF` 默认取 `2-SYN/outputs/<run>/ChipTop.sdf`）：

```bash
cd /data1/GB/ic_workbench
make -C 3-Pre_PR_NETSIM gls_sdf \
  TECH=smic180 NETLIST_RUN=<run-name> WAVEFORM=1
make -C 3-Pre_PR_NETSIM run_sdf \
  TECH=smic180 NETLIST_RUN=<run-name> WAVEFORM=1 \
  BINARY="$TAPE_ENV/applications/tests/build/hello.riscv"
```

库路径不在默认位置时覆盖配置：

```bash
make -C 3-Pre_PR_NETSIM gls_zero TECH=smic180 NETLIST_RUN=<run-name> \
  STD_CELL_MODEL=/path/to/standard-cell.v \
  SRAM_ROOT=/path/to/sram-root SRAM_CORNER=<corner> \
  SRAM_MODEL_TEMPLATE='%s.v'
```

运行 Chipyard 外设 CI：

```bash
make -C 3-Pre_PR_NETSIM ci_i2c_zero TECH=smic180 NETLIST_RUN=<run-name> BINARY=<elf>
make -C 3-Pre_PR_NETSIM ci_spi_zero TECH=smic180 NETLIST_RUN=<run-name> BINARY=<elf>
make -C 3-Pre_PR_NETSIM ci_jtag_zero TECH=smic180 NETLIST_RUN=<run-name>
make -C 3-Pre_PR_NETSIM ci_i2c_sdf TECH=smic180 NETLIST_RUN=<run-name> BINARY=<elf>
make -C 3-Pre_PR_NETSIM ci_spi_sdf TECH=smic180 NETLIST_RUN=<run-name> BINARY=<elf>
make -C 3-Pre_PR_NETSIM ci_jtag_sdf TECH=smic180 NETLIST_RUN=<run-name>
```

`WAVEFORM=1` 时生成 `3-Pre_PR_NETSIM/gen/<config>/<run>/run-zero.fsdb` 或
`run-sdf.fsdb`，不会自动生成 VCD/VPD/SAIF。

## 6. STA 和功耗：`4-Pre_PR_STA_POWER`

检查综合生成的 SDF：

```bash
cd /data1/GB/ic_workbench
make -C 4-Pre_PR_STA_POWER sdf TECH=smic180 NETLIST_RUN=<run-name>
```

直接读取门级 FSDB 计算平均功耗（FSDB 必须先由上一节的 `WAVEFORM=1` 运行生成）：

```bash
make -C 4-Pre_PR_STA_POWER power \
  TECH=smic180 NETLIST_RUN=<run-name>
```

一条命令完成 SDF 检查、SDF 门级仿真和功耗报告：

```bash
make -C 4-Pre_PR_STA_POWER sdf_power \
  TECH=smic180 NETLIST_RUN=<run-name> \
  BINARY="$TAPE_ENV/applications/tests/build/hello.riscv"
```

覆盖 PrimeTime、库、波形和分析窗口：

```bash
PT_SHELL=/path/to/pt_shell make -C 4-Pre_PR_STA_POWER power \
  TECH=smic180 NETLIST_RUN=<run-name> \
  STD_CELL_DB=/path/to/stdcell.db SRAM_ROOT=/path/to/sram-root \
  SRAM_CORNER=<corner> FSDB=/path/to/run-sdf.fsdb POWER_START_NS=2000
```

报告目录为 `4-Pre_PR_STA_POWER/outputs/<tech>/<run>/sdf-fsdb/`。

## 7. Innovus P&R：`BACKEND/PR`

进入项目容器，在普通 Innovus 模式执行（不要加 `-stylus`）。默认是
TSMC28 `multiplier_pipe3`：

```bash
cd /data1/GB/ic_workbench
docker exec -it gb_env bash
cd /data1/GB/ic_workbench/BACKEND/PR
RUN_NAME=block-$(date +%Y%m%d-%H%M%S)
innovus -no_gui -log /tmp/icwb_pr.log \
  -execute "source scripts/run_flow.tcl; run_flow -flow block -directory runs/$RUN_NAME"
```

SMIC180 ChipTop 必须提供包含 pad-ring、`PVDD1R` 和 `PVSS1R` 的 DEF：

```bash
cd /data1/GB/ic_workbench/BACKEND/PR
PR_TECHNOLOGY=smic180 \
PR_FLOORPLAN_DEF=/absolute/path/ChipTop_pad_ring.def \
innovus -no_gui -log /tmp/icwb_pr_smic180.log \
  -execute 'source scripts/run_flow.tcl; run_flow -flow block -directory runs/smic180-<run-name>'
```

正式运行前可单独执行 SMIC180 输入检查：

```bash
cd /data1/GB/ic_workbench
tclsh BACKEND/PR_CHIPTOP_SMIC180/scripts/preflight.tcl
```

该检查会确认综合网表、标准单元、IO、SRAM、ROM 和 QRC 配置，并在没有 pad-ring
DEF（或等效 floorplan 脚本）时阻止正式 P&R。

流程顺序为 `floorplan -> prects -> cts -> postcts -> route -> postroute`，完成后
自动生成最终报告并在 gate 通过后写入 `BACKEND/PR/outputs/<technology>/`。

断点续跑：

```bash
cd /data1/GB/ic_workbench/BACKEND/PR
innovus -no_gui -log /tmp/icwb_pr_resume.log \
  -execute 'source scripts/run_flow.tcl; run_flow -flow block \
  -directory runs/<run-name> -from cts.block_start -to postroute.run_opt_postroute'
```

主要检查报告：

```bash
less BACKEND/PR/reports/final/timing/setup/index.rpt
less BACKEND/PR/reports/final/timing/hold/index.rpt
less BACKEND/PR/reports/final/route.drc.rpt
less BACKEND/PR/reports/final/io_pin_placement.rpt
cat BACKEND/PR/outputs/<technology>/manifest.txt
```

按 setup/hold、analysis view 和 path group 查看详细时序：

```bash
less BACKEND/PR/reports/final/timing/setup/index.rpt
less BACKEND/PR/reports/final/timing/hold/index.rpt
less BACKEND/PR/reports/final/clock.summary.rpt
gzip -cd BACKEND/PR/reports/final/timing_debug/<report>.tarpt.gz | less
```

`.tarpt.gz` 是 gzip 文本报告，不是 tar 包，使用 `gzip -cd`，不要使用
`tar -xzf`。若只想清理 P&R 根目录工具会话文件并执行某个命令，可使用：

```bash
cd /data1/GB/ic_workbench/BACKEND/PR
./scripts/run_clean.sh innovus -no_gui -log /tmp/icwb_pr.log \
  -execute 'source scripts/run_flow.tcl; run_flow -flow block -directory runs/<run-name>'
```

修改 IO pin plan 后必须从 floorplan 重新完整运行，不能复用缺少端口位置的 CTS 数据库。

## 8. RC 提取：`BACKEND/RC_EXTRACT`

当前脚本针对 TSMC28 StarRC，执行最坏/最好 RC 两个 corner：

```bash
cd /data1/GB/ic_workbench
(cd BACKEND/RC_EXTRACT && ./run_starrc.sh)
```

日志位于 `BACKEND/RC_EXTRACT/starrc/logs/`，SPEF 位于
`BACKEND/RC_EXTRACT/starrc/outputs/` 或对应 StarRC 工作目录。若 StarXtract
不在 `/data2/tools/starrc/R-2020.09-SP5/bin/`，请修改脚本中的 `STARXTRACT`。

## 9. DRC/LVS：`BACKEND/DRC_LVS`

这些脚本必须在提供 Calibre、PDK 和许可证的 `test_env` 容器中执行。先运行 DRC：

```bash
cd /data1/GB/ic_workbench
docker exec -it test_env bash
cd /data1/GB/ic_workbench
```

```bash
cd /data1/GB/ic_workbench
bash BACKEND/DRC_LVS/scripts/run_drc.sh \
  multiplier_pipe3 \
  BACKEND/PR/outputs/tsmc28/multiplier_pipe3.gds
```

准备 TSMC28 标准单元 SPICE/CDL：

```bash
cd /data1/GB/ic_workbench
bash BACKEND/DRC_LVS/scripts/extract_tsmc28_stdcell_spi.sh
```

运行 LVS（GDS 和门级 Verilog 必须来自同一次 P&R）：

```bash
bash BACKEND/DRC_LVS/scripts/run_lvs.sh \
  multiplier_pipe3 \
  BACKEND/PR/outputs/tsmc28/multiplier_pipe3.gds \
  BACKEND/PR/outputs/tsmc28/multiplier_pipe3.v \
  BACKEND/DRC_LVS/libraries/tcbn28hpcplusbwp7t40p140lvt_110a.spi
```

如果只需要从 Verilog 生成 LVS 源 CDL，不运行 Calibre：

```bash
bash BACKEND/DRC_LVS/scripts/generate_lvs_source.sh \
  multiplier_pipe3 \
  BACKEND/PR/outputs/tsmc28/multiplier_pipe3.v \
  BACKEND/DRC_LVS/libraries/tcbn28hpcplusbwp7t40p140lvt_110a.spi
```

结果写入 `BACKEND/DRC_LVS/runs/<top>/`。LVS 报告中的 `INCORRECT` 表示比较完成
但存在不匹配，需要查看 `.lvs.report`，不等同于脚本执行失败。

## 10. Formality 等价性检查：`FM`

`FM` 当前脚本是 `shift_reg` 示例，引用 `2-SYN/default.svf` 和固定的综合运行号。
在 Formality 环境中从根目录执行：

```bash
cd /data1/GB/ic_workbench
(cd FM && ./run_fm)
```

日志写入 `FM/logs/<月日_时分>.log`。更换设计或综合运行号时，修改
`FM/scripts/fm.tcl` 中的 `top_design`、RTL、网表和 `dc_date`。

## 11. `oh2bin` PPA 基准

该目录需要 TSMC28 DC 环境。运行初始基线和完整 sweep：

```bash
cd /data1/GB/ic_workbench/oh2bin_ppa
./scripts/run_initial.sh
./scripts/run_sweep.sh
./scripts/summarize_results.sh results > results/summary.csv
python3 scripts/plot_ppa.py results_initial/ppa.csv figures
```

需要重新生成精确 `casez` 变体时：

```bash
cd /data1/GB/ic_workbench/oh2bin_ppa
./scripts/generate_casez_variant.sh 32
```

结果在 `oh2bin_ppa/results/summary.csv`，图表在 `oh2bin_ppa/figures/`。

## 12. 波形查看和清理

打开门级 FSDB：

```bash
verdi -ssf 3-Pre_PR_NETSIM/gen/<config>/<run-name>/run-sdf.fsdb &
```

清理门级仿真编译产物但保留 FSDB：

```bash
make -C 3-Pre_PR_NETSIM clean-gls
```

`5-PR` 目前只保存 Verdi/波形会话文件，没有独立的自动化运行脚本；查看其中
已有会话可直接打开 FSDB：

```bash
verdi -ssf 5-PR/verdiLog/novas_autosave.ses.wave.0 &
```

各 Makefile 自带帮助，可在根目录直接查看完整可选参数：

```bash
make -C 3-Pre_PR_NETSIM help
make -C 4-Pre_PR_STA_POWER help
```

不要删除正在复用的 `2-SYN/outputs/<run>`、`BACKEND/PR/runs/<run>` 或
`BACKEND/PR/outputs/<technology>`；断点续跑和 DRC/LVS 都依赖这些目录。

## 13. 常见问题

- `TAPE_ENV`、`RISCV` 未设置：进入 Chipyard Nix shell，并重新导出 `TAPE_ENV`。
- GLS 找不到 SRAM/ROM/标准单元模型：检查 `TECH`、`*_ROOT`、`*_CORNER` 和模板参数。
- P&R 报告显示 IO 未放置：重新生成包含全部顶层端口位置的 `FLOORPLAN_DEF`，不要复用旧 CTS 数据库。
- DRC/LVS 找不到 PDK 或 `calibre`：确认在 `test_env` 容器且许可证环境已加载。
- STA/功耗找不到 FSDB：先用 `WAVEFORM=1` 执行 `gls_sdf` 和 `run_sdf`。
