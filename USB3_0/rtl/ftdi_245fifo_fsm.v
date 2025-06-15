// FT60x����ģ��

module ftdi_245fifo_fsm #(
  parameter FIFO_BUS_WIDTH = 2
)(
// FT60xоƬ�ӿ�
  input                          usb_clk,
  output                         usb_rstn,
  input                          usb_txe_n, // ����FIFO��ָʾ������Ч
  input                          usb_rxf_n, // ����FIFO��ָʾ��ֻ�е͵�ƽʱ�Ž��ж�����
  output                         usb_wr_n, // дʹ��
  output                         usb_rd_n, // ��ʹ��
  output                         usb_oe_n, // �������ʹ��
  input  [FIFO_BUS_WIDTH-1:0]    usb_be_i, // ���������ֽ�ʹ��(����)
  output [FIFO_BUS_WIDTH-1:0]    usb_be_o, // ���������ֽ�ʹ��(����)
  output                         usb_be_t, // ��̬����ʹ���ź�, output(0), input(1)
  input  [FIFO_BUS_WIDTH*8-1:0]  usb_data_i, // ��������(����)
  output [FIFO_BUS_WIDTH*8-1:0]  usb_data_o, // ��������(����)
  output                         usb_data_t, // ��̬����ʹ���ź�, output(0), input(1)
  output [1:0]                   usb_gpio, // ģʽѡ��
  output                         usb_siwu_n,
  output                         usb_wakeup_n,
// �ڲ��û��ӿ�
  input                          rstn_usbclk,
  input  [FIFO_BUS_WIDTH*8-1:0]  s_axis_tdata,
  input  [FIFO_BUS_WIDTH-1:0]    s_axis_tkeep,
  input                          s_axis_tlast,
  input  [FIFO_BUS_WIDTH-1:0]    s_axis_tstrb,
  input                          s_axis_tvalid,
  output                         s_axis_tready,

  output [FIFO_BUS_WIDTH*8-1:0]  m_axis_tdata,
  output [FIFO_BUS_WIDTH-1:0]    m_axis_tkeep,
  output                         m_axis_tlast,
  output [FIFO_BUS_WIDTH-1:0]    m_axis_tstrb,
  output                         m_axis_tvalid,
  input                          m_axis_tready,
  input                          almost_full_axis
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam S_IDLE    = 'b000001;
  localparam S_RX_DLY  = 'b000010;
  localparam S_RX_OE   = 'b000100;
  localparam S_RX_DATA = 'b001000;
  localparam S_TX_DLY  = 'b010000;
  localparam S_TX_DATA = 'b100000;

//------------------------------------
//             Local Signal
//------------------------------------
  reg [5:0]                  usb_state = S_IDLE;
  reg [FIFO_BUS_WIDTH-1:0]   usb_be_i_d1 = 0; // �ӳ�1��:���������ֽ�ʹ��(����)
  reg [FIFO_BUS_WIDTH*8-1:0] usb_data_i_d1 = 0; // �ӳ�1��:��������(����)
  reg [1:0]                  rx_dly_cnt = 0; 
  reg [1:0]                  tx_dly_cnt = 0; 
  
  reg                        usb_wr_n_ff = 1'b1;
  reg                        usb_rd_n_ff = 1'b1;
  reg                        usb_oe_n_ff = 1'b1;
  reg [FIFO_BUS_WIDTH-1:0]   usb_be_o_ff = 0;
  reg                        usb_be_t_ff = 1'b1;
  reg [FIFO_BUS_WIDTH*8-1:0] usb_data_o_ff = 0;
  reg                        usb_data_t_ff = 1'b1;

  reg [FIFO_BUS_WIDTH*8-1:0] m_axis_tdata_ff = 0;
  reg [FIFO_BUS_WIDTH-1:0]   m_axis_tkeep_ff = 0;
  reg                        m_axis_tlast_ff = 0;
  reg [FIFO_BUS_WIDTH-1:0]   m_axis_tstrb_ff = 0;
  reg                        m_axis_tvalid_ff = 0;
  reg                        s_axis_tready_ff = 0;

//------------------------------------
//             User Logic
//------------------------------------

// USB ״̬��  
  always @(posedge usb_clk or negedge rstn_usbclk)
    if (!rstn_usbclk)
      usb_state <= S_IDLE;
    else
      case(usb_state)
        S_IDLE:
          if ((!usb_rxf_n) && (!almost_full_axis))
            usb_state <= S_RX_DLY;
          else if ((!usb_txe_n) && s_axis_tvalid)
            usb_state <= S_TX_DLY;
        S_RX_DLY:
          if (rx_dly_cnt == 'd1)
            usb_state <= S_RX_OE;
        S_RX_OE:
            usb_state <= S_RX_DATA;
        S_RX_DATA:
          if (usb_rxf_n)
            usb_state <= S_IDLE;
        S_TX_DLY:
          if (tx_dly_cnt == 'd1)
            usb_state <= S_TX_DATA;
        S_TX_DATA:
          if ((s_axis_tvalid && s_axis_tlast) || usb_txe_n)
            usb_state <= S_IDLE;
        default: usb_state <= S_IDLE;
      endcase
// Receiver
  // rx delay counter
    always @ (posedge usb_clk)
      if (usb_state[1])
        rx_dly_cnt <= rx_dly_cnt + 'd1;
      else
        rx_dly_cnt <= 'd0;

    always @ (negedge usb_clk)
      if (usb_state[2])
        usb_oe_n_ff <= 1'b0;
      else if (usb_state[0])
        usb_oe_n_ff <= 1'b1;

    always @ (negedge usb_clk)
      if (usb_state[3])
        usb_rd_n_ff <= 1'b0;
      else
        usb_rd_n_ff <= 1'b1;

    always @ (posedge usb_clk)  usb_be_i_d1 <= usb_be_i;
    always @ (posedge usb_clk)  usb_data_i_d1 <= usb_data_i;
      
    always @ (posedge usb_clk or negedge rstn_usbclk)
      if (!rstn_usbclk)
        m_axis_tvalid_ff <= 1'b0;
      else if (usb_state[3])
        begin
          if (|usb_be_i_d1)
            m_axis_tvalid_ff <= 1'b1;
          else
            m_axis_tvalid_ff <= 1'b0;
        end
      else
        m_axis_tvalid_ff <= 1'b0;
      
    always @ (posedge usb_clk or negedge rstn_usbclk)
      if (!rstn_usbclk)
        m_axis_tlast_ff <= 1'b0;
      else if (usb_state[3] && usb_rxf_n)
        m_axis_tlast_ff <= 1'b1;
      else
        m_axis_tlast_ff <= 1'b0;

    always @ (posedge usb_clk)  m_axis_tdata_ff <= usb_data_i_d1;
    always @ (posedge usb_clk)  m_axis_tkeep_ff <= usb_be_i_d1;
    always @ (posedge usb_clk)  m_axis_tstrb_ff <= usb_be_i_d1;

// Transmitter
  // tx delay counter
    always @ (posedge usb_clk)
      if (usb_state[4])
        tx_dly_cnt <= tx_dly_cnt + 'd1;
      else
        tx_dly_cnt <= 'd0;

    always @ (posedge usb_clk)
      if (usb_state[5])
        usb_wr_n_ff <= 1'b0;
      else
        usb_wr_n_ff <= 1'b1;

    always @ (posedge usb_clk)  usb_data_o_ff <= s_axis_tdata;
    always @ (posedge usb_clk)  usb_be_o_ff <= (s_axis_tkeep & s_axis_tstrb);

    always @ (posedge usb_clk)
      if (usb_state[5])
        s_axis_tready_ff <= 1'b1;
      else
        s_axis_tready_ff <= 1'b0;
//------------------------------------
//             Output
//------------------------------------
  assign usb_gpio = 2'b00;// 245 FIFO Mode
  assign usb_siwu_n = 1'b1; // Reserve, Pull Up
  assign usb_wakeup_n = 1'b0;
  assign usb_rstn = rstn_usbclk;
  assign usb_wr_n = usb_wr_n_ff;
  assign usb_rd_n = usb_rd_n_ff;
  assign usb_oe_n = usb_oe_n_ff;
  assign usb_be_o = usb_be_o_ff;
  assign usb_be_t = usb_be_t_ff;
  assign usb_data_o = usb_data_o_ff;
  assign usb_data_t = usb_data_t_ff;
  assign m_axis_tdata = m_axis_tdata_ff;
  assign m_axis_tkeep = m_axis_tkeep_ff;
  assign m_axis_tlast = m_axis_tlast_ff;
  assign m_axis_tstrb = m_axis_tstrb_ff;
  assign m_axis_tvalid = m_axis_tvalid_ff;
  assign s_axis_tready = s_axis_tready_ff;

endmodule