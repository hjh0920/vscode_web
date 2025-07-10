`timescale 1ns/1ns


module tb_sent;

//*************************** Parameters ***************************
  parameter  PERIOD_CLK = 10;
  parameter  SENT_NUM = 5; // SENT通道数
  parameter  ID_SENT_PARAM = 2; // SENT参数帧ID
  parameter  CLK_FREQ = 100000000; // 模块时钟频率, Unit: Hz

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
        sent_config(0, 3, 4, NO_Pause, 10, Legacy_CRC, 4'b1010, 6, 24'h123456); #10000;
      
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
    input [3:0]  sent_status_nibble; // 状态和通信nibble
    input [2:0]  sent_data_len; // 数据长度, 支持1~6 Nibbles, 单位 Nibble
    input [23:0] sent_data_nibble; // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
    begin
      @(posedge clk);
        rx_axis_udp_tdata = {16'h2, sent_config_channel, 8'h0};
        rx_axis_udp_tvalid = 1;
        rx_axis_udp_tlast = 0;
      @(posedge clk);
        rx_axis_udp_tdata = {sent_ctick_len,sent_ltick_len, 6'h0,sent_pause_mode, sent_pause_len[15:8]};
      @(posedge clk);
        rx_axis_udp_tdata = {sent_pause_len[7:0], 7'h0,sent_crc_mode, 4'h0,sent_status_nibble, 5'h0,sent_data_len};
      @(posedge clk);
        rx_axis_udp_tdata = {sent_data_nibble,8'h0};
        rx_axis_udp_tlast = 1;
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
    .CLK_FREQ     (CLK_FREQ    )  // 模块时钟频率, Unit: Hz
  )u_sent_top(
    // 模块时钟及复位
    .clk                (clk               ),
    .rst                (rst               ),
    // 用户UDP数据接收接口
    .rx_axis_udp_tdata  (rx_axis_udp_tdata ),
    .rx_axis_udp_tvalid (rx_axis_udp_tvalid),
    .rx_axis_udp_tlast  (rx_axis_udp_tlast ),
    // SENT输出
    .sent()
  );

endmodule
