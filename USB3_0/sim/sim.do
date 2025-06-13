# 1. 清除之前的工作
quit -sim
.main clear

# 2. 创建库
vlib xpm_lib
vlib xil_defaultlib
vlib work

# 3. 映射库
# 需要先复制 xpm库 到 "./xpm_lib" 路径下, xmp以及各种IP库在 modelsim 联合 vivado 生成的库文件夹下
vmap xpm_lib ./xpm_lib
vmap xil_defaultlib ./xil_defaultlib
vmap work ./work

# 4. 编译 XPM 库
# xpm文件存放在 "./vivado/2020.2/data/ip/xmp" 路径下, 需要提前复制到当前目录下
vlog -work xpm_lib "./xpm_lib/xpm_fifo.sv"
# 添加其他需要的 XPM 文件...

# 5. 编译设计文件
vlog -work work +incdir+../rtl ../rtl/*.v

# 6. 编译Xilinx IP核 (如果有)
   # 编译FIFO IP
   # vlog -work xil_defaultlib ../ip/fifo_generator_0/simulation/fifo_generator_0.v
   # vlog -work xil_defaultlib ../ip/fifo_generator_0/simulation/fifo_generator_0_sim_netlist.v

# 7. 编译 glbl 模块
# glbl 模块存放在 "./vivado/2020.2/data/verilog/src/glbl.v" 路径下, 需要提前复制到当前目录下
vlog -work xil_defaultlib ./glbl.v

# 8. 启动仿真
vsim -voptargs="+acc" -L xpm_lib -L xil_defaultlib -L work work.tb_usb xil_defaultlib.glbl

# 9. 添加波形
do wave.do

# 10. 运行仿真
run -all
wave zoom full