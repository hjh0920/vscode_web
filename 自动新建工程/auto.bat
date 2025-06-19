@echo off

@REM path %path%;C:\Software\Xilinx\Vivado\2020.1\bin
echo Create vivado project.
@REM set cache_floder=project_1.cache
cd %~dp0
cd ./prj
if exist "*.xpr" ( 
    echo The project exists.
    pause
) else (
    echo The project does not exist.
    echo Creating ...
    @REM vivado -log ../prj/vivado.log -journal ../prj/vivado.jou -source non_prj.tcl
    vivado -source ../tcl/non_prj.tcl
)
pause
exit

@REM @REM vivado 中，cmd窗口的当前路径，就是存放 log文件、jou文件、.Xil文件夹的路径
@REM @REM 因此，所有的命令在 ./prj 目录下执行
@REM @REM 
@REM @REM vivado_pid***.str文件，是一个临时文件，打开xpr工程时自动生成，
@REM @REM 其存放位置依据打开方式有所不同，
@REM @REM 当在资源管理器中双击xpr文件打开，则存放于xpr文件所在路径
@REM @REM 当在cmd中用命令打开，则存放在 cmd窗口的当前路径