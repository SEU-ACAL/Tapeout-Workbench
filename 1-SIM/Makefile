# 定义变量
TB          = tb_shift_reg
SIM_FILES   = /data2/EDA_DOCKER/ic_workbench/0-RTL/CPU/shift.v /data2/EDA_DOCKER/ic_workbench/1-SIM/tb/tb_shift.v
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