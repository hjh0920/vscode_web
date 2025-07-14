`timescale 1ns/1ns

module tb_lin;

//*************************** Parameters ***************************
  parameter  PERIOD_CLK = 100;
  parameter  SENT_NUM = 2; // SENT通道数
  parameter  ID_SENT_PARAM = 2; // SENT参数帧ID
  parameter  ID_SENT_DATA = 3; // SENT数据帧ID
  parameter  CLK_FREQ = 10000000; // 模块时钟频率, Unit: Hz

  localparam Legacy_CRC = 0;
  localparam Recommend_CRC = 1;
  localparam NO_Pause = 0;
  localparam Fixed_Pause = 1;
  localparam Variable_Pause = 2;


 
//***************************   Signals  ***************************
    // 模块时钟及复位
    reg        clk = 0;
    reg        rst = 1;
    // 用户UDP数据接收接口
    reg [31:0] rx_axis_udp_tdata = 0;
    reg        rx_axis_udp_tvalid = 0;
    reg        rx_axis_udp_tlast = 0;

//*************************** Test Logic ***************************
  always # (PERIOD_CLK/2) clk = ~clk;

  initial
    begin
      #100
      rst = 0;
      #1000;
        sent_data(0); #1000;
        wait(u_sent_top.sent_ready[0]);
        sent_config(0, 10, 5, Fixed_Pause, 20, Legacy_CRC); #100;
        sent_data(0); #1000;
        wait(u_sent_top.sent_ready[0]);
        sent_config(0, 5, 5, Variable_Pause, 30, Recommend_CRC); #100;
        sent_data(0); #100;

        sent_data(1); #1000;
        wait(u_sent_top.sent_ready[1]);
        sent_config(1, 10, 5, Fixed_Pause, 20, Legacy_CRC); #100;
        sent_data(1); #1000;
        wait(u_sent_top.sent_ready[1]);
        sent_config(1, 5, 5, Variable_Pause, 30, Recommend_CRC); #100;
        sent_data(1); #10000;
        wait(u_sent_top.sent_ready[1]);
        #1000;
      $stop;
    end
//***************************    Task    ***************************
  task sent_config;
    input [7:0]  sent_config_channel; // 通道索引
    input [7:0]  sent_ctick_len; // Tick长度, 支持3~90us, 单位 us
    input [7:0]  sent_ltick_len; // 低脉冲 Tick 个数, 至少 4 Ticks
    input [1:0]  sent_pause_mode; // Pause Mode
    input [15:0] sent_pause_len; // 暂停脉冲长度, 12~768Ticks
    input        sent_crc_mode; // CRC Mode
    begin
      @(posedge clk);
        rx_axis_udp_tdata = {ID_SENT_PARAM[15:0], sent_config_channel, 8'h0};
        rx_axis_udp_tvalid = 1;
        rx_axis_udp_tlast = 0;
      @(posedge clk);
        rx_axis_udp_tdata = {sent_ctick_len,sent_ltick_len, 6'h0,sent_pause_mode, sent_pause_len[15:8]};
      @(posedge clk);
        rx_axis_udp_tdata = {sent_pause_len[7:0], 7'h0,sent_crc_mode, 16'h0};
        rx_axis_udp_tlast = 1;
      @(posedge clk);
        rx_axis_udp_tdata = 32'b0;
        rx_axis_udp_tvalid = 0;
        rx_axis_udp_tlast = 0;
    end
    endtask

  task sent_data;
    input [7:0]  sent_config_channel; // 通道索引
    begin
      @(posedge clk);
        rx_axis_udp_tdata = {ID_SENT_DATA[15:0], sent_config_channel, 8'h0};
        rx_axis_udp_tvalid = 1;
        rx_axis_udp_tlast = 0;
  `ifdef CRC_TEST
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A53E53E;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A748748;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A4AC4AC;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A78F78F;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A91D91D;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A000000;
        rx_axis_udp_tlast = 1;
  `else
      @(posedge clk);
        rx_axis_udp_tdata = 32'h6A654321;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h5A543210;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h4A432100;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h3A321000;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h2A210000;
      @(posedge clk);
        rx_axis_udp_tdata = 32'h1A100000;
        rx_axis_udp_tlast = 1;
  `endif
      @(posedge clk);
        rx_axis_udp_tdata = 32'b0;
        rx_axis_udp_tvalid = 0;
        rx_axis_udp_tlast = 0;
    end
    endtask
//***************************  Instance  ***************************
  sent_top #(
    .SENT_NUM     (SENT_NUM     ), // SENT通道数
    .ID_SENT_PARAM(ID_SENT_PARAM), // SENT参数帧ID
    .ID_SENT_DATA (ID_SENT_DATA ), // SENT数据帧ID
    .CLK_FREQ     (CLK_FREQ     )  // 模块时钟频率, Unit: Hz
  )u_sent_top(
    // 模块时钟及复位
    .clk                (clk               ),
    .rst                (rst               ),
    // 用户UDP数据接收接口
    .rx_axis_udp_tdata  (rx_axis_udp_tdata ),
    .rx_axis_udp_tvalid (rx_axis_udp_tvalid),
    .rx_axis_udp_tlast  (rx_axis_udp_tlast ),
    // SENT输出
    .sent_ready        (), // SENT 准备好标志, 置位时才可以改变参数
    .sent_fifo_pfull   (), // SENT FIFO满标志, 置位时不能在下发数据
    .sent()
  );

endmodule
