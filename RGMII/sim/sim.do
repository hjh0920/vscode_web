# 1. 清除之前的工作
quit -sim
.main clear
 
# 2. 设置库路径
set VIVADO_DIR "C:/Software/Xilinx/Vivado/2020.1/data"
set VIVADO_LIB_DIR "C:/modeltech64_2020.4/vivado2020_lib"
set IP_DIR "../ip"
set RTL_DIR "../rtl"

# 3. 创建库
# unisim 库 提供Xilinx FPGA所有基本硬件原语(LUT/FDCE/RAMB36E1/BUFG/MMCM/IO原语等)的行为级和结构级仿真模型
vlib unisim
# unimacro库 提供复杂功能模块(如FIFO/移位寄存器/DSP宏)的仿真模型
vlib unimacro
# secureip 库 提供Xilinx加密IP核(如PCIe/GTX收发器)的仿真模型
vlib secureip
# xpm 库 提供Xilinx CDC/XPM_MEMORY/XPM_FIFO参数宏的仿真模型
vlib xpm_lib
# xil_defaultlib 库 存放Vivado自动生成的IP核仿真模型(如FIFO/DDR控制器等)
vlib xil_defaultlib
# work 库 为用户自定义库
vlib work

# 4. 映射库
vmap unisim "$VIVADO_LIB_DIR/unisim"
vmap unimacro "$VIVADO_LIB_DIR/unimacro"
vmap secureip "$VIVADO_LIB_DIR/secureip"
vmap xpm_lib "$VIVADO_LIB_DIR/xpm"
vmap xil_defaultlib ./xil_defaultlib
vmap work ./work

# 5. 编译库文件
  # 编译 glbl 模块
  vlog -work xil_defaultlib "$VIVADO_DIR/verilog/src/glbl.v"
  # 编译 xpm 模块
  vlog -work xpm_lib "$VIVADO_DIR/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv"
  # 编译 Xilinx IP
  # vlog -work xil_defaultlib "$IP_DIR/fifo_generator_0/simulation/fifo_generator_0.v"
  # vlog -work xil_defaultlib "$IP_DIR/fifo_generator_0/simulation/fifo_generator_0_sim_netlist.v"
  # 编译设计文件
  vlog -work work "$RTL_DIR/*.v"

# 6. 启动仿真
vsim -voptargs="+acc" -L unisim -L unimacro -L secureip -L xpm_lib -L xil_defaultlib -L work xil_defaultlib.glbl work.tb_usb

# 7. 添加波形
do wave.do

# 8. 运行仿真
run -all
wave zoom full
