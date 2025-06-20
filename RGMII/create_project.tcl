# 设置器件参数
set device      xc7a35t
set package     fgg484
set speed       -2
set part        ${device}${package}${speed}

set prjName     top
set rtlTopName  ftdi_245fifo_test
set simTopName  tb_usb

# 设置目录路径
set prjDir      [pwd]                       ;# 使用绝对路径更可靠
set srcDir      [file normalize "../src"]   ;# 规范化路径
set ipDir       [file normalize "../src/ip"]

# 创建工程
create_project $prjName $prjDir -part $part

# 设置工程属性
set_property target_language Verilog [current_project]  ;# 设置默认硬件描述语言
set_property simulator_language Verilog [current_project]  ;# 设置仿真语言
# set_property DEFAULT_LIB work [current_project]

# 创建目录 (如果不存在)
if {![file exists $ipDir]} {
    file mkdir $ipDir
}

# 添加设计文件 (更安全的文件添加方式)
# 不加 -nocomplain 时, 如果目录为空, glob 会报错导致脚本终止
# 这种写法能安全处理空目录或无效路径的情况
if {[llength [glob -nocomplain $srcDir/rtl/*.v]] > 0} {
    add_files [glob $srcDir/rtl/*.v]
}

# 设置RTL顶层（建议明确指定）
set_property top $rtlTopName [current_fileset]
update_compile_order -fileset sources_1


# 添加约束文件
if {[llength [glob -nocomplain $srcDir/xdc/*.xdc]] > 0} {
    add_files -fileset constrs_1 [glob $srcDir/xdc/*.xdc]
}

# 添加仿真文件
if {[llength [glob -nocomplain $srcDir/tb/*.v]] > 0} {
    add_files -fileset sim_1 [glob $srcDir/tb/*.v]
}

# 设置仿真顶层（建议明确指定）
set_property top $simTopName [get_filesets sim_1]
update_compile_order -fileset sim_1

# 可选: 设置综合和实现策略
# set_property strategy Flow_AreaOptimized_high [get_runs synth_1]
# set_property strategy Performance_Explore [get_runs impl_1]

# 可选: 自动运行综合和实现
# launch_runs synth_1
# wait_on_run synth_1
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1

# 打开GUI
start_gui

# 打印工程信息
puts "#############################################"
puts "# 工程创建成功"
puts "# 器件型号: $part"
puts "# 工程目录: $prjDir"
puts "# RTL目录: $srcDir/rtl"
puts "# IP目录: $ipDir"
puts "#############################################"