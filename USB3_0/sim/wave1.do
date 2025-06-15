onerror {resume}
virtual type { \
{0x1 IDLE}\
{0x2 RX_DLY}\
{0x4 RX_OE}\
{0x8 RX_DATA}\
{0x10 TX_DLY}\
{0x20 TX_DATA}\
} state_type_t
quietly virtual function -install /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm -env /glbl { (state_type_t)/tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state} usb_state_named
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_clk
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rstn
add wave -noupdate -color Gold /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_txe_n
add wave -noupdate -color Gold /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rxf_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_wr_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_rd_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_oe_n
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_i
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_o
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_be_t
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_i
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_o
add wave -noupdate /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_data_t
add wave -noupdate -color pink -subitemconfig {/tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state {-color pink}} /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state_named
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
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1083274 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ms
update
WaveRestoreZoom {1040205 ps} {1249795 ps}
