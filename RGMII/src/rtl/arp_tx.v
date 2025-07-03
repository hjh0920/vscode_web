// ARP报文发送模块

module arp_tx (
  parameter LOCAL_MAC = 48'h01_02_03_04_05_06, // 本机 MAC 地址, 默认为 01:02:03:04:05:06
  parameter LOCAL_IP  = 32'hC0_A8_01_01 // 本机 IP 地址, 默认为 192.168.1.1
)(
  // 用于 ARP 应答 (rx_mac_aclk)
  input         rx_arp_req, // ARP 请求信号
  input  [47:0] rx_arp_smac, // ARP 报文源 MAC 地址
  input  [31:0] rx_arp_sip, // ARP 报文源 IP 地址
  // 发送 ARP 数据
  input         tx_mac_aclk,
  input         tx_mac_reset,
  output [7:0]  tx_axis_arp_tdata,
  output        tx_axis_arp_tvalid,
  output        tx_axis_arp_tlast,
  input         tx_axis_arp_tready
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire        arp_req; // ARP 请求信号
  reg         arp_req_d1 = 0;
  reg  [47:0] arp_dmac = 0; // ARP 报文目的 MAC 地址
  reg  [31:0] arp_dip = 0; // ARP 报文目的 IP 地址
  reg  [10:0] tx_byte_cnt = 0; // 发送字节计数器
  reg  [7:0]  tx_axis_arp_tdata_ff = 0;
  reg         tx_axis_arp_tvalid_ff = 0;
  reg         tx_axis_arp_tlast_ff = 0;
//------------------------------------
//             User Logic
//------------------------------------
// ARP 报文目的 MAC 地址
  always @ (posedge tx_mac_aclk)  if (arp_req) arp_dmac <= rx_arp_smac;
// ARP 报文目的 IP 地址
  always @ (posedge tx_mac_aclk)  if (arp_req) arp_dip <= rx_arp_sip;
  always @ (posedge tx_mac_aclk)  arp_req_d1 <= arp_req;
// 接收字节计数器
  always @ (posedge tx_mac_aclk or posedge tx_mac_reset)
    if (tx_mac_reset)
      tx_byte_cnt <= 11'b0;
    else if (arp_req && (tx_byte_cnt == 0))
      tx_byte_cnt <= 11'b1;
    else if (tx_axis_arp_tlast_ff)
      tx_byte_cnt <= 11'b0;
    else if (tx_axis_arp_tvalid_ff && tx_axis_arp_tready)
      tx_byte_cnt <= tx_byte_cnt + 11'b1;
// 
  always @ (posedge tx_mac_aclk)
    case (tx_byte_cnt)
      11'd1: tx_axis_arp_tdata_ff <= arp_dmac[47:40];
      11'd2: tx_axis_arp_tdata_ff <= arp_dmac[39:32];
      11'd3: tx_axis_arp_tdata_ff <= arp_dmac[31:24];
      11'd4: tx_axis_arp_tdata_ff <= arp_dmac[23:16];
      11'd5: tx_axis_arp_tdata_ff <= arp_dmac[15:8];
      11'd6: tx_axis_arp_tdata_ff <= arp_dmac[7:0];
      11'd7: tx_axis_arp_tdata_ff <= LOCAL_MAC[47:40];
      11'd8: tx_axis_arp_tdata_ff <= LOCAL_MAC[39:32];
      11'd9: tx_axis_arp_tdata_ff <= LOCAL_MAC[31:24];
      11'd10: tx_axis_arp_tdata_ff <= LOCAL_MAC[23:16];
      11'd11: tx_axis_arp_tdata_ff <= LOCAL_MAC[15:8];
      11'd12: tx_axis_arp_tdata_ff <= LOCAL_MAC[7:0];
      


//------------------------------------
//             Output Port
//------------------------------------

//------------------------------------
//             Instance
//------------------------------------
  xpm_cdc_single #(
    .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
  )rx_arp_req_sync(
    .dest_out(arp_req), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                          // registered.

    .dest_clk(tx_mac_aclk), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(1'b0),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(rx_arp_req)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
  );

endmodule
