
# 添加信号
add wave -noupdate /u_pwm_top/u_pwm_top/clk
add wave -noupdate /u_pwm_top/u_pwm_top/rst

add wave -noupdate -expand -group PWM_PARAM \
    /u_pwm_top/u_pwm_top/u_pwm_config/rx_axis_udp_tdata  \
    /u_pwm_top/u_pwm_top/u_pwm_config/rx_axis_udp_tvalid \
    /u_pwm_top/u_pwm_top/u_pwm_config/rx_axis_udp_tlast  \
    /u_pwm_top/u_pwm_top/u_pwm_config/rx_axis_udp_tuser  \
    /u_pwm_top/u_pwm_top/u_pwm_config/pwm_config_vld     \
    /u_pwm_top/u_pwm_top/u_pwm_config/pwm_config_channel \
    /u_pwm_top/u_pwm_top/u_pwm_config/pwm_en             \
    /u_pwm_top/u_pwm_top/u_pwm_config/pwm_period         \
    /u_pwm_top/u_pwm_top/u_pwm_config/pwm_hlevel

add wave -noupdate -expand -group PWM_OUT \
    /u_pwm_top/u_pwm_top/pwm


  # 显示信号名称简称
  configure wave -signalnamewidth 1
