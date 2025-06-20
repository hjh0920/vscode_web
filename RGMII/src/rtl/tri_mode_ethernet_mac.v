// 三速以太网MAC模块顶层
//  1. 支持10/100/1000Mbps速率自适应
//  2. MAC接收端: 支持CRC校验, 输出Stream流不包含前导码/SFD/填充字段/FCS
//     rx_axis_mac_tuser 在 rx_axis_mac_tlast 为置位时有效, rx_axis_mac_tuser 置位表示出现如下错误情况:
//       1) 残缺帧
//       2) 帧过滤使能时, 接收帧的目的MAC地址非本地MAC地址和广播地址
//       3) 接收帧类型非ARP或IP报文
//       4) 接收超时
//       5) CRC校验错误
//  3. MAC发送端: 支持填充前导码 & SFD & 填充字段 & FCS 以及不足64字节长度填充

module tri_mode_ethernet_mac #(
  // 帧过滤使能, 与本地MAC地址不一致过滤
  parameter C_FILTER_EN = 1,
  // 本地MAC地址
  parameter C_LOCAL_MAC = 48'h0102_0304_0506,
  // 接收超时时间(unit: rx_mac_aclk)
  parameter C_TIMEOUT   = 3000,
  // 帧间隔(Unit: bit time, 8整倍数)
  parameter C_IFG = 96
)(
  input         clk_125mhz,
  input         clk90_125mhz,
  input         reset,
  input         reset90,
  // PHY 芯片状态指示
  output        inband_link_status, // up(1), down(0)
  output [1:0]  inband_clock_speed, // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
  output        inband_duplex_status, // half-duplex(0), full-duplex(1)
   // RGMII_RX
  input         rgmii_rxc,
  input         rgmii_rx_ctl,
  input  [3:0]  rgmii_rxd,
  // RGMII_TX
  output        rgmii_txc,
  output        rgmii_tx_ctl,
  output [3:0]  rgmii_txd,
  // 用户接收数据 AXIS 接口
  output        rx_mac_aclk,
  output        rx_mac_reset,
  output  [7:0] rx_axis_mac_tdata,
  output        rx_axis_mac_tvalid,
  output        rx_axis_mac_tlast,
  output        rx_axis_mac_tuser,
  // 用户发送数据 AXIS 接口
  output        tx_mac_aclk,
  output        tx_mac_reset,
  input         tx_axis_mac_tvalid,
  input [7:0]   tx_axis_mac_tdata,
  input         tx_axis_mac_tlast,
  output        tx_axis_mac_tready
);

//------------------------------------
//             Local Signal
//------------------------------------  
// RGMII接收模块
  // PHY 芯片状态指示
  wire        inband_link_status_temp; // up(1), down(0)
  wire [1:0]  inband_clock_speed_temp; // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
  wire        inband_duplex_status_temp; // half-duplex(0), full-duplex(1)
  // User interface
  wire        rx_mac_aclk_temp;
  wire [7:0]  rx_axis_rgmii_tdata;
  wire        rx_axis_rgmii_tvalid;
// RGMII发送模块
  // User interface
  wire [7:0]  tx_axis_rgmii_tdata;
  wire        tx_axis_rgmii_tvalid;
  wire        tx_axis_rgmii_tready;
// 复位模块
  wire        rx_mac_reset_temp;
  wire        tx_mac_reset_temp;

//------------------------------------
//             Output
//------------------------------------
  assign inband_link_status   = inband_link_status_temp;
  assign inband_clock_speed   = inband_clock_speed_temp;
  assign inband_duplex_status = inband_duplex_status_temp;
  assign rx_mac_aclk          = rx_mac_aclk_temp;
  assign tx_mac_aclk          = clk_125mhz;
  assign rx_mac_reset         = rx_mac_reset_temp;
  assign tx_mac_reset         = tx_mac_reset_temp;

//------------------------------------
//             Instance
//------------------------------------
// RGMII接收模块
  rgmii_rx u_rgmii_rx (
  // PHY 芯片状态指示
    .inband_link_status    (inband_link_status_temp), // up(1), down(0)
    .inband_clock_speed    (inband_clock_speed_temp), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    .inband_duplex_status  (inband_duplex_status_temp), // half-duplex(0), full-duplex(1)
    // RGMII_RX
    .rgmii_rxc             (rgmii_rxc),
    .rgmii_rx_ctl          (rgmii_rx_ctl),
    .rgmii_rxd             (rgmii_rxd),
    // User interface
    .rx_mac_aclk           (rx_mac_aclk_temp),
    .rx_axis_rgmii_tdata   (rx_axis_rgmii_tdata),
    .rx_axis_rgmii_tvalid  (rx_axis_rgmii_tvalid)
  );
// RGMII发送模块
  rgmii_tx u_rgmii_tx (
    .clk_125mhz            (clk_125mhz),
    .clk90_125mhz          (clk90_125mhz),
    .reset                 (reset),
    .reset90               (reset90),
    // PHY 芯片状态指示
    .phy_link_status       (inband_link_status_temp), // up(1), down(0)
    .phy_speed_status      (inband_clock_speed_temp), // 10Mbps(0), 100Mbps(1), 1000Mbps(2)
    // RGMII_TX
    .rgmii_txc             (rgmii_txc),
    .rgmii_tx_ctl          (rgmii_tx_ctl),
    .rgmii_txd             (rgmii_txd),
    // User interface
    .tx_axis_rgmii_tdata   (tx_axis_rgmii_tdata),
    .tx_axis_rgmii_tvalid  (tx_axis_rgmii_tvalid),
    .tx_axis_rgmii_tready  (tx_axis_rgmii_tready)
  );
// 三速以太网MAC复位模块
  tri_mode_ethernet_mac_reset u_tri_mode_ethernet_mac_reset(
    // PHY 芯片状态指示
    .inband_link_status (inband_link_status_temp), // up(1), dowm(0)
    // 时钟及复位
    .sys_rst            (reset),
    .rx_mac_aclk        (rx_mac_aclk_temp),
    .tx_mac_aclk        (clk_125mhz),
    .rx_mac_reset       (rx_mac_reset_temp),
    .tx_mac_reset       (tx_mac_reset_temp)
  );
// 三速以太网MAC接收模块
  tri_mode_ethernet_mac_rx #(
    // 帧过滤使能, 与本地MAC地址不一致过滤
    .C_FILTER_EN           (C_FILTER_EN),
    // 本地MAC地址
    .C_LOCAL_MAC           (C_LOCAL_MAC),
    // 接收超时时间(unit: rx_mac_aclk)
    .C_TIMEOUT             (C_TIMEOUT)
  )U_tri_mode_ethernet_mac_rx(
    .inband_clock_speed    (inband_clock_speed_temp), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    // RGMII 接收数据 AXIS 接口
    .rx_mac_aclk           (rx_mac_aclk_temp),
    .rx_mac_reset          (rx_mac_reset_temp),
    .rx_axis_rgmii_tdata   (rx_axis_rgmii_tdata),
    .rx_axis_rgmii_tvalid  (rx_axis_rgmii_tvalid),
    // 用户接收数据 AXIS 接口
    .rx_axis_mac_tdata     (rx_axis_mac_tdata),
    .rx_axis_mac_tvalid    (rx_axis_mac_tvalid),
    .rx_axis_mac_tlast     (rx_axis_mac_tlast),
    .rx_axis_mac_tuser     (rx_axis_mac_tuser)
  );
// 三速以太网MAC发送模块
  tri_mode_ethernet_mac_tx #(
    // 帧间隔(Unit: bit time, 8整倍数)
    .C_IFG                 (C_IFG)
  )U_tri_mode_ethernet_mac_tx(
    .inband_clock_speed    (inband_clock_speed_temp),   // 125MHz, 25MHz, 2.5MHz
    // RGMII 发送数据 AXIS 接口
    .tx_mac_aclk           (tx_mac_aclk),
    .tx_mac_reset          (tx_mac_reset_temp),
    .tx_axis_rgmii_tdata   (tx_axis_rgmii_tdata),
    .tx_axis_rgmii_tvalid  (tx_axis_rgmii_tvalid),
    .tx_axis_rgmii_tready  (tx_axis_rgmii_tready),
    // 用户发送数据 AXIS 接口
    .tx_axis_mac_tvalid    (tx_axis_mac_tvalid),
    .tx_axis_mac_tdata     (tx_axis_mac_tdata),
    .tx_axis_mac_tlast     (tx_axis_mac_tlast),
    .tx_axis_mac_tready    (tx_axis_mac_tready)
  );

  endmodule