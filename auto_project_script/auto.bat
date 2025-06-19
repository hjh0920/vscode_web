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

@REM @REM vivado �У�cmd���ڵĵ�ǰ·�������Ǵ�� log�ļ���jou�ļ���.Xil�ļ��е�·��
@REM @REM ��ˣ����е������� ./prj Ŀ¼��ִ��
@REM @REM 
@REM @REM vivado_pid***.str�ļ�����һ����ʱ�ļ�����xpr����ʱ�Զ����ɣ�
@REM @REM ����λ�����ݴ򿪷�ʽ������ͬ��
@REM @REM ������Դ��������˫��xpr�ļ��򿪣�������xpr�ļ�����·��
@REM @REM ����cmd��������򿪣������� cmd���ڵĵ�ǰ·��