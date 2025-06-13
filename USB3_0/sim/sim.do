# 1. ���֮ǰ�Ĺ���
quit -sim
.main clear

# 2. ������
vlib xpm_lib
vlib xil_defaultlib
vlib work

# 3. ӳ���
# ��Ҫ�ȸ��� xpm�� �� "./xpm_lib" ·����, xmp�Լ�����IP���� modelsim ���� vivado ���ɵĿ��ļ�����
vmap xpm_lib ./xpm_lib
vmap xil_defaultlib ./xil_defaultlib
vmap work ./work

# 4. ���� XPM ��
# xpm�ļ������ "./vivado/2020.2/data/ip/xmp" ·����, ��Ҫ��ǰ���Ƶ���ǰĿ¼��
vlog -work xpm_lib "./xpm_lib/xpm_fifo.sv"
# ���������Ҫ�� XPM �ļ�...

# 5. ��������ļ�
vlog -work work +incdir+../rtl ../rtl/*.v

# 6. ����Xilinx IP�� (�����)
   # ����FIFO IP
   # vlog -work xil_defaultlib ../ip/fifo_generator_0/simulation/fifo_generator_0.v
   # vlog -work xil_defaultlib ../ip/fifo_generator_0/simulation/fifo_generator_0_sim_netlist.v

# 7. ���� glbl ģ��
# glbl ģ������ "./vivado/2020.2/data/verilog/src/glbl.v" ·����, ��Ҫ��ǰ���Ƶ���ǰĿ¼��
vlog -work xil_defaultlib ./glbl.v

# 8. ��������
vsim -voptargs="+acc" -L xpm_lib -L xil_defaultlib -L work work.tb_usb xil_defaultlib.glbl

# 9. ��Ӳ���
do wave.do

# 10. ���з���
run -all
wave zoom full