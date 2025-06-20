:: 注意: 换行符必须为 CRLF, LF 会导致闪退

:: 关闭命令回显, 即打印执行的命令
@echo off
:: 设置编码为UTF-8
chcp 65001
:: ------------------------------
:: 配置部分（用户可修改）
:: ------------------------------
set "VIVADO_PATH=C:\Xilinx\Vivado\2020.1\bin\vivado.bat"  :: Vivado可执行文件路径

:: ------------------------------
:: 检查依赖项
:: ------------------------------
:: 检查Vivado是否可用
if not exist "%VIVADO_PATH%" (
    echo [ERROR] 请修改脚本中的 VIVADO_PATH 或安装Vivado
    pause
    exit /b 1
)

:: 检查TCL脚本是否存在
if not exist "%~dp0create_project.tcl" (
    echo [ERROR] create_project.tcl 文件不存在！
    pause
    exit /b 1
)

:: 检查并自动创建 prj 文件夹
if not exist "%~dp0prj\" (
    mkdir "%~dp0prj"
    echo [INFO] 正在创建 prj 文件夹 ...
) else (
    echo [INFO] prj 文件夹已存在
)

:: ------------------------------
:: 检查并创建项目
:: ------------------------------
cd /d "%~dp0prj/"

if exist "*.xpr" ( 
    echo [INFO] 工程已存在, 按任意键退出 ...
    pause
) else (
    echo [INFO] 正在创建 Vivado 工程 ...

    :: 调用Vivado执行TCL脚本
    "%VIVADO_PATH%" -source ../create_project.tcl
)

echo [INFO] 工程创建完成！
pause
exit /b 0