`timescale 1ns/1ns



module tb_usb;

//*************************** Parameters ***************************
  parameter integer  PERIOD_TXCLK = 12;
  parameter integer  PERIOD_RXCLK = 12;

  parameter  FIFO_BUS_WIDTH   = 2; // FT600(2Bytes), FT601(4Bytes)
  parameter  S_TDATA_WIDTH    = 4; // 1-512 (byte)
  parameter  M_TDATA_WIDTH    = 4; // 1-512 (byte)
  parameter  FIFO_DEPTH       = 2048; // 16-4194304
  parameter  PROG_FULL_THRESH = 1024; // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
//***************************   Signals  ***************************
  // 模块时钟
    reg                          tx_clk = 0; // 发送时钟
    reg                          rx_clk = 0; // 接收时钟
  // 全局异步复位
    reg                          rst_glbl = 1;
  // FT60x芯片接口
    wire                         usb_clk;
    wire                         usb_rstn;
    wire                         usb_txe_n; // 传输FIFO空指示，低有效
    wire                         usb_rxf_n; // 接收FIFO满指示，只有低电平时才进行读数据
    wire                         usb_wr_n; // 写使能
    wire                         usb_rd_n; // 读使能
    wire                         usb_oe_n; // 数据输出使能
    wire [FIFO_BUS_WIDTH-1:0]    usb_be_i = 0; // 并行数据字节使能(接收)
    wire [FIFO_BUS_WIDTH-1:0]    usb_be_o; // 并行数据字节使能(发送)
    wire                         usb_be_t; // 三态输入使能信号, output(0), input(1)
    wire                         usb_be;
    wire [FIFO_BUS_WIDTH*8-1:0]  usb_data_i = 0; // 并行数据(接收)
    wire [FIFO_BUS_WIDTH*8-1:0]  usb_data_o; // 并行数据(发送)
    wire                         usb_data_t; // 三态输入使能信号, output(0), input(1)
    wire                         usb_data;
    wire [1:0]                   usb_gpio; // 模式选择
    wire                         usb_siwu_n;
    wire                         usb_wakeup_n;
  // 用户接口
    reg                          s_axis_tvalid = 0;
    wire                         s_axis_tready;
    reg  [S_TDATA_WIDTH*8-1:0]   s_axis_tdata = 0;
    reg  [S_TDATA_WIDTH-1:0]     s_axis_tstrb = 0;
    reg  [S_TDATA_WIDTH-1:0]     s_axis_tkeep = 0;
    reg                          s_axis_tlast = 0;

    wire                         m_axis_tvalid;
    reg                          m_axis_tready = 0;
    wire [M_TDATA_WIDTH*8-1:0]   m_axis_tdata;
    wire [M_TDATA_WIDTH-1:0]     m_axis_tstrb;
    wire [M_TDATA_WIDTH-1:0]     m_axis_tkeep;
    wire                         m_axis_tlast;
//*************************** Test Logic ***************************
  always # (PERIOD_TXCLK/2) tx_clk = ~tx_clk;
  always # (PERIOD_RXCLK/2) rx_clk = ~rx_clk;

  assign usb_data_i = usb_data;
  assign usb_data = usb_data_t ? {{FIFO_BUS_WIDTH*8}{1'bz}} : usb_data_o;
  assign usb_be_i = usb_be;
  assign usb_be = usb_be_t ? {{FIFO_BUS_WIDTH}{1'bz}} : usb_be_o;


  initial
    begin
      #100
      rst_glbl = 0;
      #100



    #1000;
    $stop;
    end
//***************************    Task    ***************************

//***************************  Instance  ***************************
// FT60x驱动模块
  ftdi_245fifo_top #(
    .FIFO_BUS_WIDTH   (FIFO_BUS_WIDTH), // FT600(2Bytes), FT601(4Bytes)
    .S_TDATA_WIDTH    (S_TDATA_WIDTH), // 1-512 (byte)
    .M_TDATA_WIDTH    (M_TDATA_WIDTH), // 1-512 (byte)
    .FIFO_DEPTH       (FIFO_DEPTH), // 16-4194304
    .PROG_FULL_THRESH (PROG_FULL_THRESH) // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
  )u_ftdi_245fifo(
  // 模块时钟
    .tx_clk         (tx_clk), // 发送时钟
    .rx_clk         (rx_clk), // 接收时钟
  // 全局异步复位
    .rst_glbl       (rst_glbl),
  // FT60x芯片接口
    .usb_clk        (usb_clk),
    .usb_rstn       (usb_rstn),
    .usb_txe_n      (usb_txe_n), // 传输FIFO空指示，低有效
    .usb_rxf_n      (usb_rxf_n), // 接收FIFO满指示，只有低电平时才进行读数据
    .usb_wr_n       (usb_wr_n), // 写使能
    .usb_rd_n       (usb_rd_n), // 读使能
    .usb_oe_n       (usb_oe_n), // 数据输出使能
    .usb_be_i       (usb_be_i), // 并行数据字节使能(接收)
    .usb_be_o       (usb_be_o), // 并行数据字节使能(发送)
    .usb_be_t       (usb_be_t), // 三态输入使能信号, output(0), input(1)
    .usb_data_i     (usb_data_i), // 并行数据(接收)
    .usb_data_o     (usb_data_o), // 并行数据(发送)
    .usb_data_t     (usb_data_t), // 三态输入使能信号, output(0), input(1)
    .usb_gpio       (usb_gpio), // 模式选择
    .usb_siwu_n     (usb_siwu_n),
    .usb_wakeup_n   (usb_wakeup_n),
  // 用户接口
    .s_axis_tvalid  (s_axis_tvalid),
    .s_axis_tready  (s_axis_tready),
    .s_axis_tdata   (s_axis_tdata),
    .s_axis_tstrb   (s_axis_tstrb),
    .s_axis_tkeep   (s_axis_tkeep),
    .s_axis_tlast   (s_axis_tlast),

    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tstrb   (m_axis_tstrb),
    .m_axis_tkeep   (m_axis_tkeep),
    .m_axis_tlast   (m_axis_tlast)
  );

  tb_ftdi_chip_model #(
    .CHIP_EW (1)        // FTDI USB chip data width, 0=8bit, 1=16bit, 2=32bit. for FT232H is 0, for FT600 is 1, for FT601 is 2.
  )ft_600_model(
    .ftdi_clk    (usb_clk),
    .ftdi_rxf_n  (usb_rxf_n),
    .ftdi_txe_n  (usb_txe_n),
    .ftdi_oe_n   (usb_oe_n),
    .ftdi_rd_n   (usb_rd_n),
    .ftdi_wr_n   (usb_wr_n),
    .ftdi_data   (usb_data),
    .ftdi_be     (usb_be)
  );


endmodule
