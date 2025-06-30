# 添加波形
# add wave *
 

# 状态机重命名
  # 删除可能存在的旧定义（防止冲突）
  catch {virtual type -delete state_type_t}
  # 创建状态名称映射关系（需在仿真前执行）
  virtual type {
    {'b000001   IDLE     }
    {'b000010   RX_DLY   }
    {'b000100   RX_OE    }
    {'b001000   RX_DATA  }
    {'b010000   TX_DLY   }
    {'b100000   TX_DATA  }
  } state_type_t

  # 将信号关联到虚拟类型
  virtual function {(state_type_t)/tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state} usb_state_named

  # 添加重命名后的信号到波形
  # add wave -color pink /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state_named
# 添加信号
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_clk
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rstn
add wave -noupdate -color Gold /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_txe_n
add wave -noupdate -color Gold /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rxf_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_oe_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rd_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_wr_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_i
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_o
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_t
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_i
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_o
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_t
add wave -noupdate -color pink /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state_named

add wave -noupdate -expand -group TX_CONV_S /tb_usb/u_ftdi_245fifo/s_axis_tvalid \
                                    /tb_usb/u_ftdi_245fifo/s_axis_tready \
                                    /tb_usb/u_ftdi_245fifo/s_axis_tdata \
                                    /tb_usb/u_ftdi_245fifo/s_axis_tstrb \
                                    /tb_usb/u_ftdi_245fifo/s_axis_tkeep \
                                    /tb_usb/u_ftdi_245fifo/s_axis_tlast
add wave -noupdate -expand -group TX_CONV_M /tb_usb/u_ftdi_245fifo/m_axis_tx_tvalid \
                                    /tb_usb/u_ftdi_245fifo/m_axis_tx_tready \
                                    /tb_usb/u_ftdi_245fifo/m_axis_tx_tdata \
                                    /tb_usb/u_ftdi_245fifo/m_axis_tx_tstrb \
                                    /tb_usb/u_ftdi_245fifo/m_axis_tx_tkeep \
                                    /tb_usb/u_ftdi_245fifo/m_axis_tx_tlast
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tdata \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tdata \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tkeep \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tlast \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tstrb \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tvalid \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tready \
                             /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/rx_dly_cnt

add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tdata \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tkeep \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tlast \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tstrb \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tvalid \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tready \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/almost_full_axis \
                                     /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/tx_dly_cnt

add wave -noupdate -expand -group RX_CONV_S /tb_usb/u_ftdi_245fifo/s_axis_rx_tvalid \
                                            /tb_usb/u_ftdi_245fifo/s_axis_rx_tready \
                                            /tb_usb/u_ftdi_245fifo/s_axis_rx_tdata \
                                            /tb_usb/u_ftdi_245fifo/s_axis_rx_tstrb \
                                            /tb_usb/u_ftdi_245fifo/s_axis_rx_tkeep \
                                            /tb_usb/u_ftdi_245fifo/s_axis_rx_tlast \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tvalid \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tready \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tdata \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tstrb \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tkeep \
                                            /tb_usb/u_ftdi_245fifo/m_axis_tlast


  # 显示信号名称简称
  configure wave -signalnamewidth 1
