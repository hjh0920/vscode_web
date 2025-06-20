`timescale 1ns/1ns


module tb_usb;

//*************************** Parameters ***************************
  parameter integer  PERIOD_TXCLK = 12;
  parameter integer  PERIOD_RXCLK = 12;
  parameter integer  PERIOD_USBCLK = 10;

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
    reg                          usb_clk = 0;
    wire                         usb_rstn;
    reg                          usb_txe_n = 0; // 传输FIFO空指示，低有效
    reg                          usb_rxf_n = 1; // 接收FIFO满指示，只有低电平时才进行读数据
    wire                         usb_wr_n; // 写使能
    wire                         usb_rd_n; // 读使能
    wire                         usb_oe_n; // 数据输出使能
    reg  [FIFO_BUS_WIDTH-1:0]    usb_be_i = 0; // 并行数据字节使能(接收)
    wire [FIFO_BUS_WIDTH-1:0]    usb_be_o; // 并行数据字节使能(发送)
    wire                         usb_be_t; // 三态输入使能信号, output(0), input(1)
    wire                         usb_be;
    reg  [FIFO_BUS_WIDTH*8-1:0]  usb_data_i = 0; // 并行数据(接收)
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
    reg                          m_axis_tready = 1;
    wire [M_TDATA_WIDTH*8-1:0]   m_axis_tdata;
    wire [M_TDATA_WIDTH-1:0]     m_axis_tstrb;
    wire [M_TDATA_WIDTH-1:0]     m_axis_tkeep;
    wire                         m_axis_tlast;
  // Test signals
    reg [FIFO_BUS_WIDTH*8-1:0]   index = 1;

//*************************** Test Logic ***************************
  always # (PERIOD_TXCLK/2) tx_clk = ~tx_clk;
  always # (PERIOD_RXCLK/2) rx_clk = ~rx_clk;
  always # (PERIOD_USBCLK/2) usb_clk = ~usb_clk;

  initial
    begin
      #100
      rst_glbl = 0;
      #1000;
// rx package 1
      @(negedge usb_clk)
        usb_rxf_n = 0;
      @(negedge usb_rd_n)
        usb_be_i = {{FIFO_BUS_WIDTH}{1'b1}};
        usb_data_i = 'd1;
      repeat(20)
        begin
          @(negedge usb_clk)
          usb_data_i = usb_data_i + 1;
        end
      @(negedge usb_clk)
        usb_rxf_n = 1;
        usb_be_i = {{FIFO_BUS_WIDTH}{1'b0}};
        usb_data_i = 0;
// rx package 2
      @(negedge usb_clk)
        usb_rxf_n = 0;
      @(negedge usb_rd_n)
        usb_be_i = {{FIFO_BUS_WIDTH}{1'b1}};
        usb_data_i = 'd1;
      repeat(20)
        begin
          @(negedge usb_clk)
          usb_data_i = usb_data_i + 1;
        end
      @(negedge usb_clk)
        usb_rxf_n = 1;
        usb_be_i = {{FIFO_BUS_WIDTH}{1'b0}};
        usb_data_i = 0;

// tx package 1
      @(posedge tx_clk);
        s_axis_tdata = 32'h0001_0002;
        s_axis_tkeep = {{S_TDATA_WIDTH}{1'b1}};
        s_axis_tlast = 0;
        s_axis_tstrb = {{S_TDATA_WIDTH}{1'b1}};
        s_axis_tvalid = 1;

      while(index < 20)
        begin
          @(posedge tx_clk);
          if (s_axis_tready)
            begin
              index = index + 1;
              s_axis_tdata = s_axis_tdata + 32'h0002_0002;
            end
        end

      @(posedge tx_clk);
      @(posedge tx_clk);
      if (s_axis_tready)
        begin
          s_axis_tdata = s_axis_tdata + 32'h0002_0002;
          s_axis_tkeep = {{S_TDATA_WIDTH}{1'b1}};
          s_axis_tlast = 1;
          s_axis_tstrb = {{S_TDATA_WIDTH}{1'b1}};
          s_axis_tvalid = 1;
        end

      @(posedge tx_clk);
      @(posedge tx_clk);
      if (s_axis_tready)
        begin
          s_axis_tdata = 0;
          s_axis_tkeep = {{S_TDATA_WIDTH}{1'b0}};
          s_axis_tlast = 0;
          s_axis_tstrb = {{S_TDATA_WIDTH}{1'b0}};
          s_axis_tvalid = 0;
          index = 0;
        end

// tx package 2
      @(posedge tx_clk);
        s_axis_tdata = 32'h0001_0002;
        s_axis_tkeep = {{S_TDATA_WIDTH}{1'b1}};
        s_axis_tlast = 0;
        s_axis_tstrb = {{S_TDATA_WIDTH}{1'b1}};
        s_axis_tvalid = 1;

      while(index < 20)
        begin
          @(posedge tx_clk);
          if (s_axis_tready)
            begin
              index = index + 1;
              s_axis_tdata = s_axis_tdata + 32'h0002_0002;
            end
        end

      @(posedge tx_clk);
      @(posedge tx_clk);
      if (s_axis_tready)
        begin
          s_axis_tdata = s_axis_tdata + 32'h0002_0002;
          s_axis_tkeep = {{S_TDATA_WIDTH}{1'b1}};
          s_axis_tlast = 1;
          s_axis_tstrb = {{S_TDATA_WIDTH}{1'b1}};
          s_axis_tvalid = 1;
        end

      @(posedge tx_clk);
      @(posedge tx_clk);
      if (s_axis_tready)
        begin
          s_axis_tdata = 0;
          s_axis_tkeep = {{S_TDATA_WIDTH}{1'b0}};
          s_axis_tlast = 0;
          s_axis_tstrb = {{S_TDATA_WIDTH}{1'b0}};
          s_axis_tvalid = 0;
          index = 0;
        end



      #10000;
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


endmodule
