onerror {resume}
quietly virtual signal -install /tb_pwm/u_pwm_top/u_pwm_config { /tb_pwm/u_pwm_top/u_pwm_config/m_axis_dout_tdata[63:32]} quotient
quietly virtual signal -install /tb_pwm/u_pwm_top/u_pwm_config { /tb_pwm/u_pwm_top/u_pwm_config/m_axis_dout_tdata[31:0]} remainder
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_pwm/u_pwm_top/clk
add wave -noupdate /tb_pwm/u_pwm_top/rst
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/rx_axis_udp_tdata
add wave -noupdate -expand -group PWM_PARAM /tb_pwm/u_pwm_top/u_pwm_config/rx_axis_udp_tvalid
add wave -noupdate -expand -group PWM_PARAM /tb_pwm/u_pwm_top/u_pwm_config/rx_axis_udp_tlast
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/rx_axis_udp_tuser
add wave -noupdate -expand -group PWM_PARAM /tb_pwm/u_pwm_top/u_pwm_config/pwm_config_vld
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_config_channel
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_en
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_period
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_hlevel
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_config_channel_ff
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_frequency
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_duty
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_en_ff
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/s_axis_divisor_tdata
add wave -noupdate -expand -group PWM_PARAM /tb_pwm/u_pwm_top/u_pwm_config/s_axis_dividend_tvalid
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/s_axis_dividend_tdata
add wave -noupdate -expand -group PWM_PARAM /tb_pwm/u_pwm_top/u_pwm_config/m_axis_dout_tvalid
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/quotient
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/remainder
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_mul_a
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_mul_b
add wave -noupdate -expand -group PWM_PARAM -radix unsigned /tb_pwm/u_pwm_top/u_pwm_config/pwm_mul_p
add wave -noupdate -expand -group PWM_OUT /tb_pwm/u_pwm_top/pwm
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {401155 ns} 1} {{Cursor 2} {401392 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 177
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {401012 ns} {402513 ns}
