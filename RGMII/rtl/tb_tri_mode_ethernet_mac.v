`timescale 1ns/1ns


module tb_tri_mode_ethernet_mac;

//*************************** Parameters ***************************
  parameter integer  PERIOD_CLK125M = 8;

  // 帧过滤使能, 与本地MAC地址不一致过滤
  parameter C_FILTER_EN = 1;
  // 本地MAC地址
  parameter C_LOCAL_MAC = 48'h0102_0304_0506;
  // 接收超时时间(unit: rx_mac_aclk)
  parameter C_TIMEOUT   = 3000;
  // 帧间隔(Unit: bit time, 8整倍数)
  parameter C_IFG = 96;

  localparam [1:0] SPEED_1000M = 2'b10;
  localparam [1:0] SPEED_100M = 2'b01;
  localparam [1:0] SPEED_10M = 2'b00;
//***************************   Signals  ***************************
  reg           clk_125mhz = 0;
  wire          clk90_125mhz;
  reg           reset = 1;
  reg           reset90 = 1;
  reg           rgmii_rxc = 0;
  reg           rgmii_rx_ctl = 0;
  reg  [3:0]    rgmii_rxd = 0;
  wire          tx_mac_aclk;
  wire          tx_mac_reset;
  reg           tx_axis_mac_tvalid = 0;
  reg  [7:0]    tx_axis_mac_tdata = 0;
  reg           tx_axis_mac_tlast = 0;
  wire          tx_axis_mac_tready;
//*************************** Test Logic ***************************
  always # (PERIOD_CLK125M/2) clk_125mhz = ~clk_125mhz;
  assign # (PERIOD_CLK125M/4) clk90_125mhz = clk_125mhz;
  always # (PERIOD_CLK125M/2) rgmii_rxc = ~rgmii_rxc;


  initial
    begin
      #100;
        reset = 0;
        reset90 = 0;
      #1000;

      T_LINK_UP(5,SPEED_1000M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);
      T_LINK_UP(5,SPEED_1000M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);

      T_LINK_UP(5,SPEED_100M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);
      T_LINK_UP(5,SPEED_100M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);

      T_LINK_UP(5,SPEED_10M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);
      T_LINK_UP(5,SPEED_10M);
      T_RX_DATA(10,8'h5A);
      T_RX_ERR_DATA(10,8'hAF);
      T_RX_DATA(10,8'h5A);
      T_LINK_DOWM(5);

      #1000;
      $stop;
    end
//***************************    Task    ***************************
  task T_LINK_DOWM;
    input integer keep_time;
    begin
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = 4'b1100;
        end
    end
  endtask
  task T_LINK_UP;
    input integer keep_time;
    input [1:0]   speed_status;
    begin
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = {1'b1,speed_status,1'b1};
        end
    end
  endtask
  task T_RX_DATA;
    input integer keep_time;
    input [7:0]   rx_data;
    reg   [7:0]   rx_data_ff;
    begin
      rx_data_ff = rx_data;
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[3:0];
          @(negedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = rx_data_ff[7:4];
            rx_data_ff = rx_data_ff + 1;
        end
    end
  endtask
  task T_RX_ERR_DATA;
    input integer keep_time;
    input [7:0]   rx_data;
    reg   [7:0]   rx_data_ff;
    begin
      rx_data_ff = rx_data;
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[3:0];
          @(negedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[7:4];
            rx_data_ff = rx_data_ff + 1;
        end
    end
  endtask


//***************************  Instance  ***************************
// 三速以太网MAC模块
  tri_mode_ethernet_mac #(
    // 帧过滤使能, 与本地MAC地址不一致过滤
    .C_FILTER_EN   (C_FILTER_EN),
    // 本地MAC地址
    .C_LOCAL_MAC   (C_LOCAL_MAC),
    // 接收超时时间(unit: rx_mac_aclk)
    .C_TIMEOUT     (C_TIMEOUT),
    // 帧间隔(Unit: bit time, 8整倍数)
    .C_IFG         (C_IFG)
  )u_ethernet(
    .clk_125mhz           (clk_125mhz),
    .clk90_125mhz         (clk90_125mhz),
    .reset                (reset),
    .reset90              (reset90),
    // PHY 芯片状态指示
    .inband_link_status   (), // up(1), down(0)
    .inband_clock_speed   (), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    .inband_duplex_status (), // half-duplex(0), full-duplex(1)
    // RGMII_RX
    .rgmii_rxc            (rgmii_rxc),
    .rgmii_rx_ctl         (rgmii_rx_ctl),
    .rgmii_rxd            (rgmii_rxd),
    // RGMII_TX
    .rgmii_txc            (),
    .rgmii_tx_ctl         (),
    .rgmii_txd            (),
    // 用户接收数据 AXIS 接口
    .rx_mac_aclk          (),
    .rx_mac_reset         (),
    .rx_axis_mac_tdata    (),
    .rx_axis_mac_tvalid   (),
    .rx_axis_mac_tlast    (),
    .rx_axis_mac_tuser    (),
    // 用户发送数据 AXIS 接口
    .tx_mac_aclk          (tx_mac_aclk),
    .tx_mac_reset         (tx_mac_reset),
    .tx_axis_mac_tvalid   (tx_axis_mac_tvalid),
    .tx_axis_mac_tdata    (tx_axis_mac_tdata),
    .tx_axis_mac_tlast    (tx_axis_mac_tlast),
    .tx_axis_mac_tready   (tx_axis_mac_tready)
  );


endmodule
