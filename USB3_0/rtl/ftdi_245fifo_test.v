 
module ftdi_245fifo_test #(
  parameter  FIFO_BUS_WIDTH   = 2, // FT600(2Bytes), FT601(4Bytes)
  parameter  S_TDATA_WIDTH    = 4, // 1-512 (byte)
  parameter  M_TDATA_WIDTH    = 4, // 1-512 (byte)
  parameter  FIFO_DEPTH       = 2048, // 16-4194304
  parameter  PROG_FULL_THRESH = 10 // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
)(
// 板载时钟及复位
  input                         clk_rtl, // 50MHz
  input                         rstn_rtl,
// FT60x芯片接口
  input                         usb_clk,
  output                        usb_rstn,
  input                         usb_txe_n, // 传输FIFO空指示，低有效
  input                         usb_rxf_n, // 接收FIFO满指示，只有低电平时才进行读数据
  output                        usb_wr_n, // 写使能
  output                        usb_rd_n, // 读使能
  output                        usb_oe_n, // 数据输出使能
  inout  [FIFO_BUS_WIDTH-1:0]   usb_be, // 并行数据字节使能
  inout  [FIFO_BUS_WIDTH*8-1:0] usb_data, // 并行数据
  output [1:0]                  usb_gpio, // 模式选择
  output                        usb_siwu_n,
  output                        usb_wakeup_n,
  output [2:0]                  usb_led // 转接板LED灯
);

//------------------------------------
//             Local Signal
//------------------------------------
    wire                        clk_100mhz;
    wire                        locked;
    
    wire [FIFO_BUS_WIDTH-1:0]   usb_be_i; // 并行数据字节使能(接收)
    wire [FIFO_BUS_WIDTH-1:0]   usb_be_o; // 并行数据字节使能(发送)
    wire                        usb_be_t; // 三态输入使能信号, output(0), input(1)
    wire [FIFO_BUS_WIDTH*8-1:0] usb_data_i; // 并行数据(接收)
    wire [FIFO_BUS_WIDTH*8-1:0] usb_data_o; // 并行数据(发送)
    wire                        usb_data_t; // 三态输入使能信号, output(0), input(1)
  // 用户发送接口
    wire                        s_axis_tvalid;
    wire                        s_axis_tready;
    wire [S_TDATA_WIDTH*8-1:0]  s_axis_tdata;
    wire [S_TDATA_WIDTH-1:0]    s_axis_tstrb;
    wire [S_TDATA_WIDTH-1:0]    s_axis_tkeep;
    wire                        s_axis_tlast;
  // 用户接收接口
    wire                        m_axis_tvalid;
    wire                        m_axis_tready;
    wire [M_TDATA_WIDTH*8-1:0]  m_axis_tdata;
    wire [M_TDATA_WIDTH-1:0]    m_axis_tstrb;
    wire [M_TDATA_WIDTH-1:0]    m_axis_tkeep;
    wire                        m_axis_tlast;
    wire                        m_almost_full_axis;

//------------------------------------
//             Instance
//------------------------------------

// 时钟管理模块
  clk_wiz_0 clock_mng(
    // Clock out ports
    .clk_100mhz (clk_100mhz),     // output clk_100mhz
    // Clock in ports
    .clk_rtl    (clk_rtl),     // input clk_rtl
    // Status and control signals
    .resetn     (rstn_rtl),     // input resetn
    .locked     (locked)      // output locked
  );

// Loop Back FIFO
  axis_data_fifo #(
    .CDC_SYNC_STAGES      (2), // 2-8
    .CLOCKING_MODE        ("common_clock"), // common_clock, independent_clock
    .FIFO_DEPTH           (2048), // 16-4194304
    .FIFO_MEMORY_TYPE     ("auto"), // auto, block, distributed, ultra
    .PACKET_FIFO          ("true"), // false, true
    .PROG_FULL_THRESH     (2043), // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
    .RELATED_CLOCKS       (0), // Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.
    .TDATA_WIDTH          (4*8), // 8-2048
    .TDEST_WIDTH          (1), // 1-32
    .TID_WIDTH            (1), // 1-32
    .TUSER_WIDTH          (1) // 1-4096
  )rx_axis_data_fifo(
    .s_aclk               (clk_100mhz),
    .s_aresetn            (~locked),
    .s_axis_tdata         (m_axis_tdata),
    .s_axis_tdest         (0),
    .s_axis_tid           (0),
    .s_axis_tkeep         (m_axis_tkeep),
    .s_axis_tlast         (m_axis_tlast),
    .s_axis_tstrb         (m_axis_tstrb),
    .s_axis_tuser         (0),
    .s_axis_tvalid        (m_axis_tvalid),
    .s_axis_tready        (m_axis_tready),
    .almost_full_axis     (m_almost_full_axis),
    .m_aclk               (clk_100mhz),
    .m_axis_tdata         (s_axis_tdata),
    .m_axis_tdest         (),
    .m_axis_tid           (),
    .m_axis_tkeep         (s_axis_tkeep),
    .m_axis_tlast         (s_axis_tlast),
    .m_axis_tstrb         (s_axis_tstrb),
    .m_axis_tuser         (),
    .m_axis_tvalid        (s_axis_tvalid),
    .m_axis_tready        (s_axis_tready)
  );

// 三态信号 IOBUF
genvar i_be;
generate
  for (i_be = 0; i_be < FIFO_BUS_WIDTH; i_be = i_be + 1) begin: i_be_loop
    IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
    ) IOBUF_usb_be (
      .O  (usb_be_i[i_be]),     // Buffer output
      .IO (usb_be[i_be]),   // Buffer inout port (connect directly to top-level port)
      .I  (usb_be_o[i_be]),     // Buffer input
      .T  (usb_be_t)      // 3-state enable input, high=input, low=output
    );    
  end
endgenerate

genvar i_data;
generate
  for (i_data = 0; i_data < FIFO_BUS_WIDTH*8; i_data = i_data + 1) begin: i_data_loop
    IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
    ) IOBUF_usb_be (
      .O  (usb_data_i[i_data]),     // Buffer output
      .IO (usb_data[i_data]),   // Buffer inout port (connect directly to top-level port)
      .I  (usb_data_o[i_data]),     // Buffer input
      .T  (usb_data_t)      // 3-state enable input, high=input, low=output
    );    
  end
endgenerate

// FT60x驱动模块
  ftdi_245fifo_top #(
    .FIFO_BUS_WIDTH   (FIFO_BUS_WIDTH), // FT600(2Bytes), FT601(4Bytes)
    .S_TDATA_WIDTH    (S_TDATA_WIDTH), // 1-512 (byte)
    .M_TDATA_WIDTH    (M_TDATA_WIDTH), // 1-512 (byte)
    .FIFO_DEPTH       (FIFO_DEPTH), // 16-4194304
    .PROG_FULL_THRESH (PROG_FULL_THRESH) // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
  ) ftdi_245fifo(
  // 模块时钟
    .tx_clk        (clk_100mhz), // 发送时钟
    .rx_clk        (clk_100mhz), // 接收时钟
  // 全局异步复位
    .rst_glbl      (locked),
  // FT60x芯片接口
    .usb_clk       (usb_clk),
    .usb_rstn      (usb_rstn),
    .usb_txe_n     (usb_txe_n), // 传输FIFO空指示，低有效
    .usb_rxf_n     (usb_rxf_n), // 接收FIFO满指示，只有低电平时才进行读数据
    .usb_wr_n      (usb_wr_n), // 写使能
    .usb_rd_n      (usb_rd_n), // 读使能
    .usb_oe_n      (usb_oe_n), // 数据输出使能
    .usb_be_i      (usb_be_i), // 并行数据字节使能(接收)
    .usb_be_o      (usb_be_o), // 并行数据字节使能(发送)
    .usb_be_t      (usb_be_t), // 三态输入使能信号, output(0), input(1)
    .usb_data_i    (usb_data_i), // 并行数据(接收)
    .usb_data_o    (usb_data_o), // 并行数据(发送)
    .usb_data_t    (usb_data_t), // 三态输入使能信号, output(0), input(1)
    .usb_gpio      (usb_gpio), // 模式选择
    .usb_siwu_n    (usb_siwu_n),
    .usb_wakeup_n  (usb_wakeup_n),
  // 用户发送接口
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tstrb  (s_axis_tstrb),
    .s_axis_tkeep  (s_axis_tkeep),
    .s_axis_tlast  (s_axis_tlast),
  // 用户接收接口
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tstrb  (m_axis_tstrb),
    .m_axis_tkeep  (m_axis_tkeep),
    .m_axis_tlast  (m_axis_tlast)
  );

//------------------------------------
//             Debug
//------------------------------------
  vio_usb_led u_vio_usb_led (
    .clk        (clk_100mhz),
    .probe_out0 (usb_led[0]),
    .probe_out1 (usb_led[1]),
    .probe_out2 (usb_led[2])
  );

  wire [0:0]                  ila_usb_txe_n;      assign ila_usb_txe_n[0]     = usb_txe_n;
  wire [0:0]                  ila_usb_rxf_n;      assign ila_usb_rxf_n[0]     = usb_rxf_n;
  wire [0:0]                  ila_usb_wr_n;       assign ila_usb_wr_n[0]      = usb_wr_n;
  wire [0:0]                  ila_usb_rd_n;       assign ila_usb_rd_n[0]      = usb_rd_n;
  wire [0:0]                  ila_usb_oe_n;       assign ila_usb_oe_n[0]      = usb_oe_n;
  wire [FIFO_BUS_WIDTH-1:0]   ila_usb_be_i;       assign ila_usb_be_i         = usb_be_i;
  wire [FIFO_BUS_WIDTH-1:0]   ila_usb_be_o;       assign ila_usb_be_o         = usb_be_o;
  wire [0:0]                  ila_usb_be_t;       assign ila_usb_be_t[0]      = usb_be_t;
  wire [FIFO_BUS_WIDTH*8-1:0] ila_usb_data_i;     assign ila_usb_data_i       = usb_data_i;
  wire [FIFO_BUS_WIDTH*8-1:0] ila_usb_data_o;     assign ila_usb_data_o       = usb_data_o;
  wire [0:0]                  ila_usb_data_t;     assign ila_usb_data_t[0]    = usb_data_t;
  wire [1:0]                  ila_usb_gpio;       assign ila_usb_gpio         = usb_gpio;
  wire [0:0]                  ila_usb_siwu_n;     assign ila_usb_siwu_n[0]    = usb_siwu_n;
  wire [0:0]                  ila_usb_wakeup_n;   assign ila_usb_wakeup_n[0]  = usb_wakeup_n;

  ila_usb_if u_ila_usb_if (
    .clk        (usb_clk),
    .probe0     (ila_usb_txe_n),
    .probe1     (ila_usb_rxf_n),
    .probe2     (ila_usb_wr_n),
    .probe3     (ila_usb_rd_n),
    .probe4     (ila_usb_oe_n),
    .probe5     (ila_usb_be_i),
    .probe6     (ila_usb_be_o),
    .probe7     (ila_usb_be_t),
    .probe8     (ila_usb_data_i),
    .probe9     (ila_usb_data_o),
    .probe10    (ila_usb_data_t),
    .probe11    (ila_usb_gpio),
    .probe12    (ila_usb_siwu_n),
    .probe13    (ila_usb_wakeup_n)
  );
  wire [0:0]                  ila_s_axis_tvalid;          assign ila_s_axis_tvalid[0]      = s_axis_tvalid;
  wire [0:0]                  ila_s_axis_tready;          assign ila_s_axis_tready[0]      = s_axis_tready;
  wire [S_TDATA_WIDTH*8-1:0]  ila_s_axis_tdata;           assign ila_s_axis_tdata          = s_axis_tdata;
  wire [S_TDATA_WIDTH-1:0]    ila_s_axis_tstrb;           assign ila_s_axis_tstrb          = s_axis_tstrb;
  wire [S_TDATA_WIDTH-1:0]    ila_s_axis_tkeep;           assign ila_s_axis_tkeep          = s_axis_tkeep;
  wire [0:0]                  ila_s_axis_tlast;           assign ila_s_axis_tlast[0]       = s_axis_tlast;
  wire [0:0]                  ila_m_axis_tvalid;          assign ila_m_axis_tvalid[0]      = m_axis_tvalid;
  wire [0:0]                  ila_m_axis_tready;          assign ila_m_axis_tready[0]      = m_axis_tready;
  wire [M_TDATA_WIDTH*8-1:0]  ila_m_axis_tdata;           assign ila_m_axis_tdata          = m_axis_tdata;
  wire [M_TDATA_WIDTH-1:0]    ila_m_axis_tstrb;           assign ila_m_axis_tstrb          = m_axis_tstrb;
  wire [M_TDATA_WIDTH-1:0]    ila_m_axis_tkeep;           assign ila_m_axis_tkeep          = m_axis_tkeep;
  wire [0:0]                  ila_m_axis_tlast;           assign ila_m_axis_tlast[0]       = m_axis_tlast;
  wire [0:0]                  ila_m_almost_full_axis;     assign ila_m_almost_full_axis[0] = m_almost_full_axis;

 ila_usb_axis u_ila_usb_axis (
    .clk        (clk_100mhz),
    .probe0     (ila_s_axis_tvalid),
    .probe1     (ila_s_axis_tready),
    .probe2     (ila_s_axis_tdata),
    .probe3     (ila_s_axis_tstrb),
    .probe4     (ila_s_axis_tkeep),
    .probe5     (ila_s_axis_tlast),
    .probe6     (ila_m_axis_tvalid),
    .probe7     (ila_m_axis_tready),
    .probe8     (ila_m_axis_tdata),
    .probe9     (ila_m_axis_tstrb),
    .probe10    (ila_m_axis_tkeep),
    .probe11    (ila_m_axis_tlast),
    .probe12    (ila_m_almost_full_axis)
  );
    


endmodule
