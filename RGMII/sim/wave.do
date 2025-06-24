# 添加波形
# add wave *

add wave -noupdate -expand -group RGMII_RX \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/inband_link_status    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/inband_clock_speed    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/inband_duplex_status  \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rgmii_rxc             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rgmii_rx_ctl          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rgmii_rxd             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rx_mac_aclk           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rx_axis_rgmii_tdata   \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_rx/rx_axis_rgmii_tvalid
# 状态机重命名
  # 删除可能存在的旧定义（防止冲突）
  catch {virtual type -delete state_type_t}
  # 创建状态名称映射关系（需在仿真前执行）
  virtual type {
    {4'd0 S_IDLE     }
    {4'd1 S_PREAMBLE }
    {4'd2 S_MAC_HEAD }
    {4'd3 S_FILTER   }
    {4'd4 S_ARP      }
    {4'd5 S_IP_HEAD  }
    {4'd6 S_IP_DATA  }
    {4'd7 S_FCS      }
    {4'd8 S_FCS_CHECK}
    {4'd9 S_ERR_TYPE }
  } state_type_t

  # 将信号关联到虚拟类型
  virtual function {(state_type_t)/tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_mac_state} rx_mac_state_named


add wave -noupdate -expand -group MAC_RX \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_mac_aclk           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_mac_reset          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_rgmii_tvalid  \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_rgmii_tdata   \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_mac_state_named    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_timeout_cnt        \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_byte_cnt           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_fcs_byte_cnt       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_dst_mac            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_eth_type           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_ip_total_length    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_eth_fcs            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_last_data          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_preamble_flag      \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_preamble_type_flag \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_eth_head_done      \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_arp_data_done      \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_ip_head_done       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_ip_data_done       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_fcs_done           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_timeout_flag       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_filter_success     \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_crc32_result       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_mac_tvalid    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_mac_tdata     \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_mac_tlast     \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_rx/rx_axis_mac_tuser

add wave -noupdate -expand -group MAC_TX \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/inband_clock_speed      \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_mac_aclk             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_mac_reset            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_rgmii_tvalid    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_rgmii_tdata     \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_rgmii_tready    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/inband_clock_speed_txclk\
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_mac_en               \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_byte_cnt             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_total_byte           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_55d5_flag            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_stuff_flag           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_data_flag            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_fcs_flag             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_fcs_flag_d1          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_fcs_byte_cnt         \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_mac_done             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_mac_done_d1          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_ifg_flag             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_ifg_flag_d1          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_ifg_cnt              \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_crc32_reset          \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_crc32_din            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_crc32_enable         \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_crc32_result         \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_mac_tvalid      \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_mac_tdata       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_mac_tlast       \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/U_tri_mode_ethernet_mac_tx/tx_axis_mac_tready

add wave -noupdate -expand -group RGMII_TX \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/clk_125mhz              \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/clk90_125mhz            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/reset                   \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/reset90                 \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/phy_link_status         \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/phy_speed_status        \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/rgmii_txc               \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/rgmii_tx_ctl            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/rgmii_txd               \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_tvalid    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_tdata     \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_tready    \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/phy_link_status_txclk   \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/phy_speed_status_txclk  \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_tdata_ff  \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_handshake \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/clk_cnt                 \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/clk_div5_50             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/clk90_div5_50           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_data_en              \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_data_error           \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_axis_rgmii_tready_ff \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_data_msb             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_data_lsb             \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_nibble_sw            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx_nibble_sw_d1         \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/msb_lsb_flag            \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/bus_status              \
                                  /tb_tri_mode_ethernet_mac/u_ethernet/u_rgmii_tx/tx10_100_data_en

configure wave -namecolwidth 216
configure wave -valuecolwidth 141
# 显示信号名称简称
configure wave -signalnamewidth 1
wave zoom full