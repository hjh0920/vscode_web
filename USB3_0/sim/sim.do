# 1. ���֮ǰ�Ĺ���
quit -sim
.main clear

# 2. ���ÿ�·��
set VIVADO_DIR "C:/Software/Xilinx/Vivado/2020.1/data"
set VIVADO_LIB_DIR "C:/modeltech64_2020.4/vivado2020_lib"
set IP_DIR "../ip"
set RTL_DIR "../rtl"

# 3. ������
# unisim �� �ṩXilinx FPGA���л���Ӳ��ԭ��(LUT/FDCE/RAMB36E1/BUFG/MMCM/IOԭ���)����Ϊ���ͽṹ������ģ��
vlib unisim
# unimacro�� �ṩ���ӹ���ģ��(��FIFO/��λ�Ĵ���/DSP��)�ķ���ģ��
vlib unimacro
# secureip �� �ṩXilinx����IP��(��PCIe/GTX�շ���)�ķ���ģ��
vlib secureip
# xpm �� �ṩXilinx CDC/XPM_MEMORY/XPM_FIFO������ķ���ģ��
vlib xpm_lib
# xil_defaultlib �� ���Vivado�Զ����ɵ�IP�˷���ģ��(��FIFO/DDR��������)
vlib xil_defaultlib
# work �� Ϊ�û��Զ����
vlib work

# 4. ӳ���
vmap unisim "$VIVADO_LIB_DIR/unisim"
vmap unimacro "$VIVADO_LIB_DIR/unimacro"
vmap secureip "$VIVADO_LIB_DIR/secureip"
vmap xpm_lib "$VIVADO_LIB_DIR/xpm"
vmap xil_defaultlib ./xil_defaultlib
vmap work ./work

# 5. ������ļ�
  # ���� glbl ģ��
  vlog -work xil_defaultlib "$VIVADO_DIR/verilog/src/glbl.v"
  # ���� xpm ģ��
  vlog -work xpm_lib "$VIVADO_DIR/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv"
  # ���� Xilinx IP
  # vlog -work xil_defaultlib "$IP_DIR/fifo_generator_0/simulation/fifo_generator_0.v"
  # vlog -work xil_defaultlib "$IP_DIR/fifo_generator_0/simulation/fifo_generator_0_sim_netlist.v"
  # ��������ļ�
  vlog -work work "$RTL_DIR/*.v"

# 6. ��������
vsim -voptargs="+acc" -L unisim -L unimacro -L secureip -L xpm_lib -L xil_defaultlib -L work xil_defaultlib.glbl work.tb_usb

# 7. ��Ӳ���
do wave.do

# 8. ���з���
run -all
wave zoom full