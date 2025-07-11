# 添加信号
add wave -noupdate /tb_sent/u_sent_top/clk
add wave -noupdate /tb_sent/u_sent_top/rst

add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/rx_axis_udp_tdata
add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/rx_axis_udp_tvalid
add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/rx_axis_udp_tlast

add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/sent_config_vld
add wave -noupdate -expand -group SENT_PARAM -radix unsigned /tb_sent/u_sent_top/u_sent_config/sent_config_channel
add wave -noupdate -expand -group SENT_PARAM -radix unsigned /tb_sent/u_sent_top/u_sent_config/sent_ctick_len
add wave -noupdate -expand -group SENT_PARAM -radix unsigned /tb_sent/u_sent_top/u_sent_config/sent_ltick_len
add wave -noupdate -expand -group SENT_PARAM -radix unsigned /tb_sent/u_sent_top/u_sent_config/sent_pause_mode
add wave -noupdate -expand -group SENT_PARAM -radix unsigned /tb_sent/u_sent_top/u_sent_config/sent_pause_len
add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/sent_crc_mode
add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/sent_frame_vld
add wave -noupdate -expand -group SENT_PARAM /tb_sent/u_sent_top/u_sent_config/sent_frame_data

add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_ctick_len_local}
add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_ltick_len_local}
add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_pause_mode_local}
add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_pause_len_local}
add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_crc_mode_local}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_busy}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sync_en}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/data_en}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/crc_en}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/pause_en}
add wave -noupdate -expand -group SENT-0 -radix unsigned {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_frame_len_reg}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_frame_data_srl}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_crc_req}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_crc_ack}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_crc}
add wave -noupdate -expand -group SENT-0 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_frame_crc}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_fifo_empty_temp}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_fifo_pfull}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[0]/u_sent_ctrl/sent_ready}

add wave -noupdate -expand -group SENT_OUT -expand /tb_sent/u_sent_top/sent

add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_ctick_len_local}
add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_ltick_len_local}
add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_pause_mode_local}
add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_pause_len_local}
add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_crc_mode_local}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_busy}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sync_en}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/data_en}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/crc_en}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/pause_en}
add wave -noupdate -expand -group SENT-1 -radix unsigned {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_frame_len_reg}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_frame_data_srl}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_crc_req}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_crc_ack}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_crc}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_frame_crc}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_fifo_empty_temp}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_fifo_pfull}
add wave -noupdate -expand -group SENT-1 {/tb_sent/u_sent_top/genblk1[1]/u_sent_ctrl/sent_ready}

configure wave -namecolwidth 177
configure wave -valuecolwidth 100
configure wave -timelineunits us
# 显示信号名称简称
configure wave -signalnamewidth 1
wave zoom full