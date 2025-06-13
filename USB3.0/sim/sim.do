# 1. 清除之前的工作
quit -sim
.main clear

# 2. 创建库
vlib xpm_lib
vlib xil_defaultlib
vlib work

# 3. 映射库
vmap xpm_lib ./xpm_lib
vmap xil_defaultlib ./xil_defaultlib
vmap work ./work

# 4. 编译 XPM 库
vlog -work xpm_lib ".xpm_lib/xpm_fifo.sv"
# 添加其他需要的 XPM 文件...

# 5. 编译设计文件
vlog -work work +incdir+../rtl ../rtl/*.v

# 6. 编译Xilinx IP核 (如果有)
# vlog -work xil_defaultlib ../ip/fifo_generator_0/simulation/fifo_generator_0.v

# 7. 编译 glbl 模块
vlog -work xil_defaultlib ./glbl.v

# 8. 启动仿真
vsim -L xpm_lib -L xil_defaultlib -L work work.top_module xil_defaultlib.glbl

# 9. 添加波形
do wave.do

# 10. 运行仿真
run -all