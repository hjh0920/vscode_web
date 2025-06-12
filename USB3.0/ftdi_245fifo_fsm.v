// FT60x驱动模块

module ftdi_245fifo_fsm #(
  parameter interger TDATA_WIDTH = 0
)(
// FT60x芯片接口
  input                      usb_clk,
  output                     usb_rstn,
  input                      usb_txe_n,
  input                      usb_rxf_n,
  output                     usb_wr_n,
  output                     usb_rd_n,
  output                     usb_oe_n,
  input  [TDATA_WIDTH/8-1:0] usb_be_i,
  output [TDATA_WIDTH/8-1:0] usb_be_o,
  output [TDATA_WIDTH/8-1:0] usb_be_t,
  input  [TDATA_WIDTH-1:0]   usb_data_i,
  output [TDATA_WIDTH-1:0]   usb_data_o,
  output [TDATA_WIDTH-1:0]   usb_data_t,
  output [1:0]               usb_gpio,
  output                     usb_siwu_n,
  output                     usb_wakeup_n,
// 内部用户接口
  input                       rstn_usbclk,
  input  [TDATA_WIDTH-1:0]    s_axis_tdata,
  input  [TDATA_WIDTH/8-1:0]  s_axis_tkeep,
  input                       s_axis_tlast,
  input  [TDATA_WIDTH/8-1:0]  s_axis_tstrb,
  input                       s_axis_tvalid,
  output                      s_axis_tready,

  output [TDATA_WIDTH-1:0]    m_axis_tdata,
  output [TDATA_WIDTH/8-1:0]  m_axis_tkeep,
  output                      m_axis_tlast,
  output [TDATA_WIDTH/8-1:0]  m_axis_tstrb,
  output                      m_axis_tvalid,
  input                       m_axis_tready
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam S_IDLE = 'b000001;
  localparam S_RX_DLY = 'b000010;
  localparam S_RX_DATA = 'b000100;
  localparam S_TX_DLY = 'b001000;
  localparam S_TX_DATA = 'b010000;
  localparam S = 'b100000;

//------------------------------------
//             Local Signal
//------------------------------------
  reg [5:0] usb_state = S_IDLE;

//------------------------------------
//             User Logic
//------------------------------------

状态机  always @(posedge usb_clk or negedge rstn_usbclk)
    if (!rstn_usbclk)
      usb_state <= S_IDLE;
    else
      case(usb_state)
        S_IDLE:
          if (!usb_rxf_n)
            usb_state <= S_RX_DLY;
          else if (s_axis_tvalid)
            usb_state <= S_TX_DLY;
        S_RX_DLY:
          if (rx_dly_cnt == 'd1)
            usb_state <= S_RX_DATA;
        S_RX_DATA:
          if (usb_rxf_n)
            usb_state <= S_IDLE;
        S_TX_DLY:
          if (tx_dly_cnt == 'd1)
            usb_state <= S_TX_DATA;
        S_TX_DATA:
          if (s_axis_tvalid && s_axis_tlast)
            usb_state <= S_IDLE;
        default: usb_state <= S_IDLE;
      endcase
    



endmodule