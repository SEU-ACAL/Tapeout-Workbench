# PrimeTime post-route timing signoff

`PT_SIGNOFF` 与 `PR` 同级，专门处理 Innovus 导出的 post-route 网表和 SPEF。SPEF 只包含 RC 寄生参数，PrimeTime 结合对应 Liberty、SDC 和网表计算延迟，然后输出时序报告和 SDF。

默认输入为：

- `../PR/outputs/smic180/ChipTop.v`
- `../PR/outputs/smic180/ChipTop.rc_setup.spef`
- `../PR/outputs/smic180/ChipTop.rc_hold.spef`
- `../../2-SYN/outputs/0830_1319/ChipTop.sdc`

运行：

```bash
cd /data1/GB/ic_workbench/BACKEND/PT_SIGNOFF
./run_pt_signoff.sh
```

输出：

```text
outputs/smic180/ChipTop.setup.sdf
outputs/smic180/ChipTop.hold.sdf
reports/smic180/pt_setup.rpt
reports/smic180/pt_hold.rpt
```

如果 PR 输出来自其他 run，必须同时覆盖 `NETLIST`、`SDC`、`SPEF_MAX`、`SPEF_MIN`，确保四者来自同一次设计交付：

```bash
NETLIST=../PR/runs/<run>/ChipTop.v \
SDC=../../2-SYN/outputs/<synth-run>/ChipTop.sdc \
SPEF_MAX=../PR/outputs/<technology>/ChipTop.rc_setup.spef \
SPEF_MIN=../PR/outputs/<technology>/ChipTop.rc_hold.spef \
./run_pt_signoff.sh
```

`setup.sdf` 使用 SS/1.62 V/125 C 与 setup SPEF，`hold.sdf` 使用 FF/1.98 V/-40 C 与 hold SPEF。生成前应检查 PT 日志中的 link、unconstrained path 和 parasitic annotation；PT 报错或报告不完整时，SDF 只能用于调试，不能作为签核结果。
