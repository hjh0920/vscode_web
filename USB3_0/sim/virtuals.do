virtual type { \
{0x1 IDLE}\
{0x2 RX_DLY}\
{0x4 RX_OE}\
{0x8 RX_DATA}\
{0x10 TX_DLY}\
{0x20 TX_DATA}\
} state_type_t
virtual function -install /tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm -env /glbl { (state_type_t)/tb_usb/u_ftdi_245fifo/u_ftdi_245fifo_fsm/usb_state} usb_state_named
