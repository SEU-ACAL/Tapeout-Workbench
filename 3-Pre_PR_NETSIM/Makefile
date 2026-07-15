# 定义变量
TB          = tb_shift_reg
SIM_FILES   = /data2/TSMC28/logic/tcbn28hpcplusbwp12t40p140lvt_180a/AN61001_20180514/TSMCHOME/digital/Front_End/verilog/tcbn28hpcplusbwp12t40p140lvt_170a/tcbn28hpcplusbwp12t40p140lvt.v /data2/EDA_DOCKER/ic_workbench/2-SYN/outputs/0215_1436/shift_reg.v /data2/EDA_DOCKER/ic_workbench/1-SIM/tb/tb_shift.v
GEN_DIR     = ./gen

# 整合你提供的 VCS 参数
VCS_FLAGS = -full64 -notice \
    -line \
    +lint=all,noVCDE,noONGS,noUI \
    -error=noZMMCM \
    -timescale=1ns/10ps \
    -quiet \
    -q \
    +rad \
    +vcs+lic+wait \
    -sverilog +systemverilogext+.sv \
    -debug_access+all \
    -top $(TB)

# 编译命令
comp:
	vcs $(VCS_FLAGS) $(SIM_FILES) -l compile.log

# 运行命令
run:
	./simv -l sim.log

# 查看波形 (Verdi)
verdi:
	verdi -sv $(SIM_FILES) -ssf shift_reg.vcd &

# 清理环境
clean:
	rm -rf csrc simv* *.log *.fsdb ucli.key *.vcd verdiLog vfastLog