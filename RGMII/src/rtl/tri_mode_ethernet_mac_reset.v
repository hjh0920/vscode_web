// 三速以太网MAC复位模块

module tri_mode_ethernet_mac_reset (
  // PHY 芯片状态指示
  input     inband_link_status, // up(1), dowm(0)
  // 时钟及复位
  input     sys_rst,
  input     rx_mac_aclk,
  input     tx_mac_aclk,
  output    rx_mac_reset,
  output    tx_mac_reset
);

//------------------------------------
//             Local Signal
//------------------------------------
// rxclk 时钟域link信号打拍, 用于检测跳变沿
  reg      link_status_rxclk_d1 = 0;
  reg      link_status_rxclk_d2 = 0;
// txclk 时钟域link信号打拍, 用于检测跳变沿
  wire     link_status_txclk;
  reg      link_status_txclk_d1 = 0;
  reg      link_status_txclk_d2 = 0;
// 复位计数器
  reg [3:0] rx_reset_cnt = 0;
  reg [3:0] tx_reset_cnt = 0;
// output register
  reg       rx_mac_reset_ff = 1;
  reg       tx_mac_reset_ff = 1;

//------------------------------------
//             User Logic
//------------------------------------
// rxclk 时钟域link信号打拍, 用于检测跳变沿
  always @ (posedge rx_mac_aclk) link_status_rxclk_d1 <= inband_link_status;
  always @ (posedge rx_mac_aclk) link_status_rxclk_d2 <= link_status_rxclk_d1;
// txclk 时钟域link信号打拍, 用于检测跳变沿
  always @ (posedge tx_mac_aclk) link_status_txclk_d1 <= link_status_txclk;
  always @ (posedge tx_mac_aclk) link_status_txclk_d2 <= link_status_txclk_d1;
// rx 复位计数器
  always @ (posedge rx_mac_aclk or posedge sys_rst)
    if (sys_rst)
      rx_reset_cnt <= 'd0;
    else if (link_status_rxclk_d1 ^ link_status_rxclk_d2)
      rx_reset_cnt <= 'd0;
    else if (!rx_reset_cnt[3])
      rx_reset_cnt <= rx_reset_cnt + 'd1;
// tx 复位计数器
  always @ (posedge tx_mac_aclk or posedge sys_rst)
    if (sys_rst)
      tx_reset_cnt <= 'd0;
    else if (link_status_txclk_d1 ^ link_status_txclk_d2)
      tx_reset_cnt <= 'd0;
    else if (!tx_reset_cnt[3])
      tx_reset_cnt <= tx_reset_cnt + 'd1;
// rx 复位
  always @ (posedge rx_mac_aclk) rx_mac_reset_ff <= ~rx_reset_cnt[3];
// tx 复位
  always @ (posedge tx_mac_aclk) tx_mac_reset_ff <= ~tx_reset_cnt[3];

//------------------------------------
//             Output Port
//------------------------------------
  assign rx_mac_reset = rx_mac_reset_ff;
  assign tx_mac_reset = tx_mac_reset_ff;

//------------------------------------
//             Instance
//------------------------------------
  xpm_cdc_single #(
    .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
  )link_status_txclk_sync(
    .dest_out(link_status_txclk), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                          // registered.
    .dest_clk(tx_mac_aclk), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(1'b0),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(inband_link_status)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
  );

  endmodule