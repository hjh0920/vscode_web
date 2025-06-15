# ��Ӳ���
# add wave *

# ״̬��������
  # ɾ�����ܴ��ڵľɶ��壨��ֹ��ͻ��
  catch {virtual type -delete state_type_t}
  # ����״̬����ӳ���ϵ�����ڷ���ǰִ�У�
  virtual type {
    {'b000001   IDLE     }
    {'b000010   RX_DLY   }
    {'b000100   RX_OE    }
    {'b001000   RX_DATA  }
    {'b010000   TX_DLY   }
    {'b100000   TX_DATA  }
  } state_type_t

  # ���źŹ�������������
  virtual function {(state_type_t)/tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state} usb_state_named

  # �������������źŵ�����
  # add wave -color pink /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state_named
# ����ź�
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
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tdata
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tkeep
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tlast
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tstrb
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tvalid
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/s_axis_tready
add wave -noupdate -expand -group TX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/rx_dly_cnt
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tdata
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tkeep
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tlast
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tstrb
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tvalid
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/m_axis_tready
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/almost_full_axis
add wave -noupdate -expand -group RX /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/tx_dly_cnt

  # ��ʾ�ź����Ƽ��
  configure wave -signalnamewidth 1