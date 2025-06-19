
set device      xc7a35t
set package     fgg484
set speed       -2
set part        $device$package$speed
set prjName     top
# current dir already : prj
set prjDir      ./
set srcDir      ../src

# if current dir = C:/cur/prj
# ./ =  C:/cur/prj
# ./prj = C:/cur/prj/prj
# ./prj/ = ./prj

create_project $prjName $prjDir -part $part

add_files   [glob $srcDir/rtl/*]
# add_files   [glob $srcDir/rtl/*.v]
# add_files   [glob $srcDir/rtl/*.vh]
# add_files   [glob $srcDir/ip/*.xcix]
update_compile_order -fileset sources_1
# update_compile_order
# 用于更新指定文件集下文件的编译顺序，Vivado可据此确定顶层文件模块名
# set_property top top [current_fileset]
# 设置顶层文件

add_files -fileset constrs_1 [glob $srcDir/xdc/*.xdc]

add_files -fileset sim_1 [glob $srcDir/tb/*.v]
update_compile_order -fileset sim_1

# set_property strategy Flow_AreaOptimized_high [get_runs synth_1]
# set_property strategy Performance_Explore [get_runs impl_1]
# 指定综合策略 
# 指定实现策略
# 未指定，则使用默认策略

# launch_runs synth_1
# wait_on_run synth_1
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# 执行综合操作
# 执行实现操作，如果没有-to_step，则只会执行到布线操作，不会生成bitstream

start_gui
# 打开Vivado图形界面