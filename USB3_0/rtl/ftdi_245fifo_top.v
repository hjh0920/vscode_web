// FT60x����ģ��

module ftdi_245fifo_top #(
  parameter  FIFO_BUS_WIDTH   = 2, // FT600(2Bytes), FT601(4Bytes)
  parameter  S_TDATA_WIDTH    = 0, // 1-512 (byte)
  parameter  M_TDATA_WIDTH    = 0, // 1-512 (byte)
  parameter  FIFO_DEPTH       = 2048, // 16-4194304
  parameter  PROG_FULL_THRESH = 10 // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
)(
// ģ��ʱ��
  input                         tx_clk, // ����ʱ��
  input                         rx_clk, // ����ʱ��
// ȫ���첽��λ
  input                         rst_glbl,
// FT60xоƬ�ӿ�
  input                         usb_clk,
  output                        usb_rstn,
  input                         usb_txe_n, // ����FIFO��ָʾ������Ч
  input                         usb_rxf_n, // ����FIFO��ָʾ��ֻ�е͵�ƽʱ�Ž��ж�����
  output                        usb_wr_n, // дʹ��
  output                        usb_rd_n, // ��ʹ��
  output                        usb_oe_n, // �������ʹ��
  input  [FIFO_BUS_WIDTH-1:0]   usb_be_i, // ���������ֽ�ʹ��(����)
  output [FIFO_BUS_WIDTH-1:0]   usb_be_o, // ���������ֽ�ʹ��(����)
  output                        usb_be_t, // ��̬����ʹ���ź�, output(0), input(1)
  input  [FIFO_BUS_WIDTH*8-1:0] usb_data_i, // ��������(����)
  output [FIFO_BUS_WIDTH*8-1:0] usb_data_o, // ��������(����)
  output                        usb_data_t, // ��̬����ʹ���ź�, output(0), input(1)
  output [1:0]                  usb_gpio, // ģʽѡ��
  output                        usb_siwu_n,
  output                        usb_wakeup_n,
// �û��ӿ�
  input                         s_axis_tvalid,
  output                        s_axis_tready,
  input  [S_TDATA_WIDTH*8-1:0]  s_axis_tdata,
  input  [S_TDATA_WIDTH-1:0]    s_axis_tstrb,
  input  [S_TDATA_WIDTH-1:0]    s_axis_tkeep,
  input                         s_axis_tlast,

  output                        m_axis_tvalid,
  input                         m_axis_tready,
  output [M_TDATA_WIDTH*8-1:0]  m_axis_tdata,
  output [M_TDATA_WIDTH-1:0]    m_axis_tstrb,
  output [M_TDATA_WIDTH-1:0]    m_axis_tkeep,
  output                        m_axis_tlast
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam  CDC_SYNC_STAGES = 2; // 2-8
  localparam  CLOCKING_MODE = "independent_clock"; // common_clock, independent_clock
  localparam  FIFO_MEMORY_TYPE = "auto"; // auto, block, distributed, ultra
  localparam  PACKET_FIFO = "true"; // false, true
  localparam  RELATED_CLOCKS = 0; // Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.

//------------------------------------
//             Local Signal
//------------------------------------
  wire                        rst_txclk;
  wire                        rst_rxclk;
  wire                        rst_usbclk;
  wire                        rstn_txclk;
  wire                        rstn_rxclk;
  wire                        rstn_usbclk;

  wire                        m_axis_tx_tvalid;
  wire                        m_axis_tx_tready;
  wire [FIFO_BUS_WIDTH*8-1:0] m_axis_tx_tdata;
  wire [FIFO_BUS_WIDTH-1:0]   m_axis_tx_tstrb;
  wire [FIFO_BUS_WIDTH-1:0]   m_axis_tx_tkeep;
  wire                        m_axis_tx_tlast;

  wire [FIFO_BUS_WIDTH*8-1:0] s_axis_tx_tdata_usbclk;
  wire [FIFO_BUS_WIDTH-1:0]   s_axis_tx_tkeep_usbclk;
  wire                        s_axis_tx_tlast_usbclk;
  wire [FIFO_BUS_WIDTH-1:0]   s_axis_tx_tstrb_usbclk;
  wire                        s_axis_tx_tvalid_usbclk;
  wire                        s_axis_tx_tready_usbclk;

  wire [FIFO_BUS_WIDTH*8-1:0] m_axis_rx_tdata_usbclk;
  wire [FIFO_BUS_WIDTH-1:0]   m_axis_rx_tkeep_usbclk;
  wire                        m_axis_rx_tlast_usbclk;
  wire [FIFO_BUS_WIDTH-1:0]   m_axis_rx_tstrb_usbclk;
  wire                        m_axis_rx_tvalid_usbclk;
  wire                        m_axis_rx_tready_usbclk;
  wire                        rx_almost_full_axis;

  wire                        s_axis_rx_tvalid;
  wire                        s_axis_rx_tready;
  wire [FIFO_BUS_WIDTH*8-1:0] s_axis_rx_tdata;
  wire [FIFO_BUS_WIDTH-1:0]   s_axis_rx_tstrb;
  wire [FIFO_BUS_WIDTH-1:0]   s_axis_rx_tkeep;
  wire                        s_axis_rx_tlast;

//------------------------------------
//             Instance
//------------------------------------
// ��λ����ģ��
  reset_ctrl u_reset_ctrl(
    // ģ��ʱ��
    .tx_clk        (tx_clk), // ����ʱ��
    .rx_clk        (rx_clk), // ����ʱ��
    .usb_clk       (usb_clk), // USBԴͬ��ʱ��
    // ȫ���첽��λ
    .rst_glbl      (rst_glbl),
    // ģ�鸴λ
    .o_rst_txclk   (rst_txclk),
    .o_rst_rxclk   (rst_rxclk),
    .o_rst_usbclk  (rst_usbclk),
    .o_rstn_txclk  (rstn_txclk),
    .o_rstn_rxclk  (rstn_rxclk),
    .o_rstn_usbclk (rstn_usbclk)
  );

// AXI4-Stream������λ��ת��ģ��
  axis_width_converter #(
    .S_TDATA_WIDTH         (S_TDATA_WIDTH), // 1-512 (byte)
    .M_TDATA_WIDTH         (FIFO_BUS_WIDTH), // 1-512 (byte)
    .TID_WIDTH             (0), // 0-32 (bit)
    .TDEST_WIDTH           (0), // 0-32 (bit)
    .TUSER_WIDTH_PER_BYTE  (0) // 0-2048 (bit)
  ) tx_axis_width_converter(
    .aclk                  (tx_clk),
    .aresetn               (rstn_txclk),
    .s_axis_tvalid         (s_axis_tvalid),
    .s_axis_tready         (s_axis_tready),
    .s_axis_tdata          (s_axis_tdata),
    .s_axis_tstrb          (s_axis_tstrb),
    .s_axis_tkeep          (s_axis_tkeep),
    .s_axis_tlast          (s_axis_tlast),
    .s_axis_tid            (0),
    .s_axis_tdest          (0),
    .s_axis_tuser          (0),
    .m_axis_tvalid         (m_axis_tx_tvalid),
    .m_axis_tready         (m_axis_tx_tready),
    .m_axis_tdata          (m_axis_tx_tdata),
    .m_axis_tstrb          (m_axis_tx_tstrb),
    .m_axis_tkeep          (m_axis_tx_tkeep),
    .m_axis_tlast          (m_axis_tx_tlast),
    .m_axis_tid            (),
    .m_axis_tdest          (),
    .m_axis_tuser          ()
  );
// ��װ xpm_fifo_axis
  axis_data_fifo #(
    .CDC_SYNC_STAGES      (CDC_SYNC_STAGES), // 2-8
    .CLOCKING_MODE        (CLOCKING_MODE), // common_clock, independent_clock
    .FIFO_DEPTH           (FIFO_DEPTH), // 16-4194304
    .FIFO_MEMORY_TYPE     (FIFO_MEMORY_TYPE), // auto, block, distributed, ultra
    .PACKET_FIFO          (PACKET_FIFO), // false, true
    .PROG_FULL_THRESH     (PROG_FULL_THRESH), // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
    .RELATED_CLOCKS       (RELATED_CLOCKS), // Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.
    .TDATA_WIDTH          (FIFO_BUS_WIDTH*8), // 8-2048
    .TDEST_WIDTH          (1), // 1-32
    .TID_WIDTH            (1), // 1-32
    .TUSER_WIDTH          (1) // 1-4096
  )tx_axis_data_fifo(
    .s_aclk               (tx_clk),
    .s_aresetn            (rstn_txclk),
    .s_axis_tdata         (m_axis_tx_tdata),
    .s_axis_tdest         (0),
    .s_axis_tid           (0),
    .s_axis_tkeep         (m_axis_tx_tkeep),
    .s_axis_tlast         (m_axis_tx_tlast),
    .s_axis_tstrb         (m_axis_tx_tstrb),
    .s_axis_tuser         (0),
    .s_axis_tvalid        (m_axis_tx_tvalid),
    .s_axis_tready        (m_axis_tx_tready),
    .almost_full_axis     (),
    .m_aclk               (usb_clk),
    .m_axis_tdata         (s_axis_tx_tdata_usbclk),
    .m_axis_tdest         (),
    .m_axis_tid           (),
    .m_axis_tkeep         (s_axis_tx_tkeep_usbclk),
    .m_axis_tlast         (s_axis_tx_tlast_usbclk),
    .m_axis_tstrb         (s_axis_tx_tstrb_usbclk),
    .m_axis_tuser         (),
    .m_axis_tvalid        (s_axis_tx_tvalid_usbclk),
    .m_axis_tready        (s_axis_tx_tready_usbclk)
  );

// FT60x����ģ��
ftdi_245fifo_fsm #(
  .FIFO_BUS_WIDTH   (FIFO_BUS_WIDTH)
)u_ftdi_245fifo_fsm(
// FT60xоƬ�ӿ�
  .usb_clk          (usb_clk),
  .usb_rstn         (usb_rstn),
  .usb_txe_n        (usb_txe_n), // ����FIFO��ָʾ������Ч
  .usb_rxf_n        (usb_rxf_n), // ����FIFO��ָʾ��ֻ�е͵�ƽʱ�Ž��ж�����
  .usb_wr_n         (usb_wr_n), // дʹ��
  .usb_rd_n         (usb_rd_n), // ��ʹ��
  .usb_oe_n         (usb_oe_n), // �������ʹ��
  .usb_be_i         (usb_be_i), // ���������ֽ�ʹ��(����)
  .usb_be_o         (usb_be_o), // ���������ֽ�ʹ��(����)
  .usb_be_t         (usb_be_t), // ��̬����ʹ���ź�, output(0), input(1)
  .usb_data_i       (usb_data_i), // ��������(����)
  .usb_data_o       (usb_data_o), // ��������(����)
  .usb_data_t       (usb_data_t), // ��̬����ʹ���ź�, output(0), input(1)
  .usb_gpio         (usb_gpio), // ģʽѡ��
  .usb_siwu_n       (usb_siwu_n),
  .usb_wakeup_n     (usb_wakeup_n),
// �ڲ��û��ӿ�
  .rstn_usbclk      (rstn_usbclk),
  .s_axis_tdata     (s_axis_tx_tdata_usbclk),
  .s_axis_tkeep     (s_axis_tx_tkeep_usbclk),
  .s_axis_tlast     (s_axis_tx_tlast_usbclk),
  .s_axis_tstrb     (s_axis_tx_tstrb_usbclk),
  .s_axis_tvalid    (s_axis_tx_tvalid_usbclk),
  .s_axis_tready    (s_axis_tx_tready_usbclk),

  .m_axis_tdata     (m_axis_rx_tdata_usbclk),
  .m_axis_tkeep     (m_axis_rx_tkeep_usbclk),
  .m_axis_tlast     (m_axis_rx_tlast_usbclk),
  .m_axis_tstrb     (m_axis_rx_tstrb_usbclk),
  .m_axis_tvalid    (m_axis_rx_tvalid_usbclk),
  .m_axis_tready    (m_axis_rx_tready_usbclk),
  .almost_full_axis (rx_almost_full_axis)
);

// ��װ xpm_fifo_axis
  axis_data_fifo #(
    .CDC_SYNC_STAGES      (CDC_SYNC_STAGES), // 2-8
    .CLOCKING_MODE        (CLOCKING_MODE), // common_clock, independent_clock
    .FIFO_DEPTH           (FIFO_DEPTH), // 16-4194304
    .FIFO_MEMORY_TYPE     (FIFO_MEMORY_TYPE), // auto, block, distributed, ultra
    .PACKET_FIFO          (PACKET_FIFO), // false, true
    .PROG_FULL_THRESH     (PROG_FULL_THRESH), // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
    .RELATED_CLOCKS       (RELATED_CLOCKS), // Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.
    .TDATA_WIDTH          (FIFO_BUS_WIDTH*8), // 8-2048
    .TDEST_WIDTH          (1), // 1-32
    .TID_WIDTH            (1), // 1-32
    .TUSER_WIDTH          (1) // 1-4096
  )rx_axis_data_fifo(
    .s_aclk               (usb_clk),
    .s_aresetn            (rstn_usbclk),
    .s_axis_tdata         (m_axis_rx_tdata_usbclk),
    .s_axis_tdest         (0),
    .s_axis_tid           (0),
    .s_axis_tkeep         (m_axis_rx_tkeep_usbclk),
    .s_axis_tlast         (m_axis_rx_tlast_usbclk),
    .s_axis_tstrb         (m_axis_rx_tstrb_usbclk),
    .s_axis_tuser         (0),
    .s_axis_tvalid        (m_axis_rx_tvalid_usbclk),
    .s_axis_tready        (m_axis_rx_tready_usbclk),
    .almost_full_axis     (rx_almost_full_axis),
    .m_aclk               (rx_clk),
    .m_axis_tdata         (s_axis_rx_tdata),
    .m_axis_tdest         (),
    .m_axis_tid           (),
    .m_axis_tkeep         (s_axis_rx_tkeep),
    .m_axis_tlast         (s_axis_rx_tlast),
    .m_axis_tstrb         (s_axis_rx_tstrb),
    .m_axis_tuser         (),
    .m_axis_tvalid        (s_axis_rx_tvalid),
    .m_axis_tready        (s_axis_rx_tready)
  );

// AXI4-Stream������λ��ת��ģ��
  axis_width_converter #(
    .S_TDATA_WIDTH         (FIFO_BUS_WIDTH*8), // 1-512 (byte)
    .M_TDATA_WIDTH         (M_TDATA_WIDTH), // 1-512 (byte)
    .TID_WIDTH             (0), // 0-32 (bit)
    .TDEST_WIDTH           (0), // 0-32 (bit)
    .TUSER_WIDTH_PER_BYTE  (0) // 0-2048 (bit)
  ) rx_axis_width_converter(
    .aclk                  (rx_clk),
    .aresetn               (rstn_rxclk),
    .s_axis_tvalid         (s_axis_rx_tvalid),
    .s_axis_tready         (s_axis_rx_tready),
    .s_axis_tdata          (s_axis_rx_tdata),
    .s_axis_tstrb          (s_axis_rx_tstrb),
    .s_axis_tkeep          (s_axis_rx_tkeep),
    .s_axis_tlast          (s_axis_rx_tlast),
    .s_axis_tid            (0),
    .s_axis_tdest          (0),
    .s_axis_tuser          (0),
    .m_axis_tvalid         (m_axis_tvalid),
    .m_axis_tready         (m_axis_tready),
    .m_axis_tdata          (m_axis_tdata),
    .m_axis_tstrb          (m_axis_tstrb),
    .m_axis_tkeep          (m_axis_tkeep),
    .m_axis_tlast          (m_axis_tlast),
    .m_axis_tid            (),
    .m_axis_tdest          (),
    .m_axis_tuser          ()
  );

endmodule