# BACKEND/PR：Place & Route 流程说明

本目录是 `multiplier_pipe3` 的 Innovus Place & Route（P&R）工程。流程由 Flowkit 定义，使用项目脚本完成 floorplan、布局优化、CTS、布线、post-route 优化、时序报告和交付物输出。

## 1. 目录结构

```text
scripts/                 Flowkit、Innovus 和项目配置
scripts/run_flow.tcl     Flowkit 入口及 block flow 定义
scripts/project_config.tcl  网表、SDC、LEF、LIB、QRC 和 MMMC 配置
runs/<run_name>/         每次运行的数据库、日志和中间文件
reports/final/           最终报告
reports/final/timing/    按 setup/hold、view、path group 分层的时序报告
reports/final/timing_debug/  Innovus timeDesign 的详细压缩报告
outputs/                 通过 gate 后生成的网表、DEF、SPEF 和 manifest
```

## 2. 环境和工具检查

在主机上进入项目容器：

```bash
docker exec -it gb_env bash
cd /data1/GB/ic_workbench/BACKEND/PR
innovus -version
flowtool -version
```

当前流程应在普通 Innovus 模式运行。不要添加 `-stylus`；该模式不提供本流程使用的 Flowkit 命令（例如 `define_flowkit_db` 和 `run_flow`）。

## 3. 完整运行（推荐）

在 Innovus 内 source Flowkit 入口，然后执行 `block` flow：

```bash
RUN_NAME=block-$(date +%Y%m%d-%H%M%S)
innovus -no_gui \
  -log /tmp/icwb_pr.log \
  -execute "source scripts/run_flow.tcl; run_flow -flow block -directory runs/$RUN_NAME"
```

也可以使用固定名称，便于复现或覆盖前先确认目录状态：

```bash
innovus -no_gui -log /tmp/icwb_pr.log \
  -execute 'source scripts/run_flow.tcl; run_flow -flow block -directory runs/block-20260717'
```

`block` flow 的执行顺序为：

```text
floorplan -> prects -> cts -> postcts -> route -> postroute
```

完整流程结束后会执行 `run_final_reports`、`gate_final_signoff` 和 `write_outputs`。只有 gate 通过，才会写入 `outputs/`。

## 4. MMMC 配置

当前启用四个 analysis view，定义在 `scripts/project_config.tcl`，由 `scripts/mmmc_config.tcl` 创建并通过 `set_analysis_view` 激活：

| View | 检查类型 | Library/PVT | RC corner | 用途 |
| --- | --- | --- | --- | --- |
| `view_setup` | setup | `lib_ss`，0.81 V / 125 C | `rc_worst` | 常规 setup 最坏 RC |
| `view_setup_cworst` | setup | `lib_ss`，0.81 V / 125 C | `c_worst` | 电容最坏 setup |
| `view_hold` | hold | `lib_ff`，1.05 V / -40 C | `rc_best` | 常规 hold 最好 RC |
| `view_hold_cbest` | hold | `lib_ff`，1.05 V / -40 C | `c_best` | 电容最好 hold |

新增 view 时，应同时更新 `PR_MMMC_VIEW_SPECS`，并确认 library、PVT 和 QRC corner 是 PDK 中已标定的组合。不要仅修改报告脚本而不修改 MMMC 定义。

## 5. I/O pin planning

未提供 `FLOORPLAN_DEF` 时，流程会将输入端口固定在左边界、输出端口固定在右边界；`clock` 因而获得物理入口，CTS 可将 source-to-root 连线纳入实现。层和边界由 `IO_PIN_*` 配置项控制。

CTS 前与最终报告阶段都会导出 I/O placement DEF 并检查每个顶层端口均为 `PLACED`、`FIXED` 或 `COVER`；任一未放置端口都会阻止 CTS 或交付。若项目有封装或 block pin plan，应设置 `FLOORPLAN_DEF` 并确保其中包含所有 I/O 的位置。

## 6. Path group 和时序报告

上游 SDC 中的 `group_path` 是 path group 的唯一来源。Innovus 将 SDC 作为 `create_constraint_mode` 输入时，`group_path` 可能只保存在 mode 局部；因此 `init_design` 后会临时屏蔽时钟和 I/O 约束命令，再次 source 上游 SDC，只重放全局 path group。这样既不会重复创建 clock，也能保证报告按真实 group 划分。

最终时序报告入口：

```text
reports/final/timing/setup/index.rpt
reports/final/timing/hold/index.rpt
```

每个 `index.rpt` 会列出 active view；每个 view 下有：

```text
summary.rpt       view 级分析摘要
constraints.rpt   该 view 的约束违规
<path_group>/endpoints.rpt  该 group 的端点路径
<path_group>/worst_path.rpt 该 group 的最差完整时钟路径
```

时钟相关报告位于：

```text
reports/final/clock.summary.rpt
reports/final/clock.latency.rpt
reports/final/clock.skew.rpt
reports/final/clock.drv.rpt
```

如果 `clock.skew.rpt` 显示 0，先确认 CTS 已执行、时钟网络已连接，并查看 `/tmp/icwb_pr.log` 中的 clock/CTS 警告；`IMPCCOPT-2215` 表示某个 clock 路由图未完全连通，需要单独调查，不能把 0 直接当作 signoff 结果。

## 7. `timing_debug` 压缩报告

`reports/final/timing_debug/` 下的 `.gz` 文件是 gzip 压缩的文本报告。文件名中的 `.tarpt.gz` 是 Innovus 的报告命名方式，并不表示 tar archive，不要使用 `tar -xzf` 解压。

```bash
gzip -cd reports/final/timing_debug/multiplier_pipe3_default.tarpt.gz | less
```

也可以先检查文件类型：

```bash
file reports/final/timing_debug/*.tarpt.gz
```

## 8. 断点续跑

可以在 Innovus 会话中从指定步骤开始，到指定步骤结束：

```tcl
source scripts/run_flow.tcl
run_flow -flow block \
  -directory runs/block-20260717 \
  -from cts.block_start \
  -to postroute.run_opt_postroute
```

断点续跑前确认 `runs/block-20260717/` 中已有对应的 Flowkit/Innovus 数据库。若要从头开始，请使用新的 `run_name`，避免混用旧数据库和新脚本。

## 9. 运行结果检查

先查看 gate 汇总：

```bash
cat outputs/manifest.txt
```

正常交付至少应包含：

```text
outputs/multiplier_pipe3.v
outputs/multiplier_pipe3.def
outputs/multiplier_pipe3.rc_worst.spef
outputs/multiplier_pipe3.rc_best.spef
outputs/manifest.txt
```

同时检查最终报告：

```bash
less reports/final/timing/setup/index.rpt
less reports/final/timing/hold/index.rpt
less reports/final/route.drc.rpt
less reports/final/route.open.rpt
less reports/final/route.antenna.rpt
less reports/final/io_pin_placement.rpt
```

## 10. 当前限制和后续完善项

- metal density 和 cut density 已生成报告，但尚未纳入 gate 硬门禁；当前 run 中仍可能存在 density 违规。
- setup/hold 的 WNS、TNS 尚未纳入自动 gate，需要在确认项目时序目标后增加阈值检查。
- IR/EM 分析尚未接入本 PR flow。
- 修改 pin plan 后必须从 floorplan 重新完整运行；不能复用缺少端口位置的 CTS 数据库。
- `scripts/run_flow.tcl` 是 Innovus 内使用的标准入口；不要用不匹配的 `flowtool` 命令替代 Innovus 执行本流程。
