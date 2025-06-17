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
//***************************   Signals  ***************************
  reg           clk_125mhz = 0;
  wire          clk90_125mhz;
  reg           reset = 1;
  reg           reset90 = 1;
  wire          rgmii_txc;
  wire          rgmii_tx_ctl;
  wire [3:0]    rgmii_txd;
  wire          tx_mac_alck;
  wire          tx_mac_reset;
  reg           tx_axis_mac_tvalid = 0;
  reg  [7:0]    tx_axis_mac_tdata = 0;
  reg           tx_axis_mac_tlast = 0;
  wire          tx_axis_mac_tready;
//*************************** Test Logic ***************************
  always # (PERIOD_CLK125M/2) clk_125mhz = ~clk_125mhz;
  assign # (PERIOD_CLK125M/4) clk90_125mhz = clk_125mhz;


  initial
    begin
      #100;
        reset = 0;
        reset90 = 0;
      #1000;

      @(posedge tx_mac_aclk);
      tx_axis_mac_tvalid = 1;
      tx_axis_mac_tdata = 8'd1;
      repeat(10)
        begin
          wait (tx_axis_mac_tready);
          @(posedge tx_mac_aclk);
          tx_axis_mac_tdata = tx_axis_mac_tdata + 1;
        end
      tx_axis_mac_tlast = 1;
      wait (tx_axis_mac_tready);
        @(posedge tx_mac_aclk);
        tx_axis_mac_tvalid = 0;
        tx_axis_mac_tdata = 0;
        tx_axis_mac_tlast = 0;

      #10000;
      $stop;
    end
//***************************    Task    ***************************

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
  )ethernet_tx(
    .clk_125mhz           (clk_125mhz),
    .clk90_125mhz         (clk90_125mhz),
    .reset                (reset),
    .reset90              (reset90),
    // PHY 芯片状态指示
    .inband_link_status   (), // up(1), down(0)
    .inband_clock_speed   (), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    .inband_duplex_status (), // half-duplex(0), full-duplex(1)
    // RGMII_RX
    .rgmii_rxc            (1'b0),
    .rgmii_rx_ctl         (1'b0),
    .rgmii_rxd            (4'b0),
    // RGMII_TX
    .rgmii_txc            (rgmii_txc),
    .rgmii_tx_ctl         (rgmii_tx_ctl),
    .rgmii_txd            (rgmii_txd),
    // 用户接收数据 AXIS 接口
    .rx_mac_alck          (),
    .rx_mac_reset         (),
    .rx_axis_mac_tdata    (),
    .rx_axis_mac_tvalid   (),
    .rx_axis_mac_tlast    (),
    .rx_axis_mac_tuser    (),
    // 用户发送数据 AXIS 接口
    .tx_mac_alck          (tx_mac_alck),
    .tx_mac_reset         (tx_mac_reset),
    .tx_axis_mac_tvalid   (tx_axis_mac_tvalid),
    .tx_axis_mac_tdata    (tx_axis_mac_tdata),
    .tx_axis_mac_tlast    (tx_axis_mac_tlast),
    .tx_axis_mac_tready   (tx_axis_mac_tready)
  );

  tri_mode_ethernet_mac #(
    // 帧过滤使能, 与本地MAC地址不一致过滤
    .C_FILTER_EN   (C_FILTER_EN),
    // 本地MAC地址
    .C_LOCAL_MAC   (C_LOCAL_MAC),
    // 接收超时时间(unit: rx_mac_aclk)
    .C_TIMEOUT     (C_TIMEOUT),
    // 帧间隔(Unit: bit time, 8整倍数)
    .C_IFG         (C_IFG)
  )ethernet_rx(
    .clk_125mhz           (clk_125mhz),
    .clk90_125mhz         (clk90_125mhz),
    .reset                (reset),
    .reset90              (reset90),
    // PHY 芯片状态指示
    .inband_link_status   (), // up(1), down(0)
    .inband_clock_speed   (), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    .inband_duplex_status (), // half-duplex(0), full-duplex(1)
    // RGMII_RX
    .rgmii_rxc            (rgmii_txc),
    .rgmii_rx_ctl         (rgmii_tx_ctl),
    .rgmii_rxd            (rgmii_txd),
    // RGMII_TX
    .rgmii_txc            (),
    .rgmii_tx_ctl         (),
    .rgmii_txd            (),
    // 用户接收数据 AXIS 接口
    .rx_mac_alck          (),
    .rx_mac_reset         (),
    .rx_axis_mac_tdata    (),
    .rx_axis_mac_tvalid   (),
    .rx_axis_mac_tlast    (),
    .rx_axis_mac_tuser    (),
    // 用户发送数据 AXIS 接口
    .tx_mac_alck          (),
    .tx_mac_reset         (),
    .tx_axis_mac_tvalid   ('d0),
    .tx_axis_mac_tdata    ('d0),
    .tx_axis_mac_tlast    ('d0),
    .tx_axis_mac_tready   ()
  );


endmodule
