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
  output [31:0] tx_axis_arp_tdata,
  output        tx_axis_arp_tvalid,
  output        tx_axis_arp_tlast,
  input         tx_axis_arp_tready
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire        arp_req; // ARP 请求信号
  reg  [47:0] arp_dmac = 0; // ARP 报文目的 MAC 地址
  reg  [31:0] arp_dip = 0; // ARP 报文目的 IP 地址
  reg  [3:0]  tx_byte_cnt = 0; // 发送字节计数器
  reg  [31:0] tx_axis_arp_tdata_ff = 0; // 发送数据
  reg         tx_axis_arp_tvalid_ff = 0; // 发送数据有效信号
  reg         tx_axis_arp_tlast_ff = 0; // 发送最后一个数据

//------------------------------------
//             User Logic
//------------------------------------
// ARP 报文目的 MAC 地址
  always @ (posedge tx_mac_aclk)  if (arp_req) arp_dmac <= rx_arp_smac;
// ARP 报文目的 IP 地址
  always @ (posedge tx_mac_aclk)  if (arp_req) arp_dip <= rx_arp_sip;
// 接收字节计数器
  always @ (posedge tx_mac_aclk or posedge tx_mac_reset)
    if (tx_mac_reset)
      tx_byte_cnt <= 4'b0;
    else if (arp_req && (tx_byte_cnt == 0))
      tx_byte_cnt <= 4'b1;
    else if (tx_axis_arp_tlast_ff)
      tx_byte_cnt <= 4'b0;
    else if (tx_axis_arp_tvalid_ff && tx_axis_arp_tready)
      tx_byte_cnt <= tx_byte_cnt + 4'b1;
// 发送 ARP 数据
  always @ (posedge tx_mac_aclk)
    case (tx_byte_cnt)
      4'd1:    tx_axis_arp_tdata_ff <= arp_dmac[47:16];
      4'd2:    tx_axis_arp_tdata_ff <= {arp_dmac[15:0],LOCAL_MAC[47:32]};
      4'd3:    tx_axis_arp_tdata_ff <= LOCAL_MAC[31:0];
      4'd4:    tx_axis_arp_tdata_ff <= {16'h0806,16'h0001};
      4'd5:    tx_axis_arp_tdata_ff <= {16'h0800,16'h0604};
      4'd6:    tx_axis_arp_tdata_ff <= {16'h0002,LOCAL_MAC[47:32]}
      4'd7:    tx_axis_arp_tdata_ff <= LOCAL_MAC[31:0];
      4'd8:    tx_axis_arp_tdata_ff <= LOCAL_IP[31:0];
      4'd9:    tx_axis_arp_tdata_ff <= arp_dmac[47:16];
      4'd10:   tx_axis_arp_tdata_ff <= {arp_dmac[15:0],arp_dip[31:16]};
      4'd11:   tx_axis_arp_tdata_ff <= {arp_dip[15:0],16'h0000};
      default: tx_axis_arp_tdata_ff <= 32'h0000_0000;
    endcase
// 发送数据有效信号
  always @ (posedge tx_mac_aclk or posedge tx_mac_reset)
    if (tx_mac_reset)
      tx_axis_arp_tvalid_ff <= 1'b0;
    else if ((tx_byte_cnt == 11) && tx_axis_arp_tready)
      tx_axis_arp_tvalid_ff <= 1'b0;
    else if (tx_byte_cnt == 1)
      tx_axis_arp_tvalid_ff <= 1'b1;
// 发送最后一个数据
  always @ (posedge tx_mac_aclk or posedge tx_mac_reset)
    if (tx_mac_reset)
      tx_axis_arp_tlast_ff <= 1'b0;
    else if ((tx_byte_cnt == 10) && tx_axis_arp_tready)
      tx_axis_arp_tlast_ff <= 1'b1;
    else if (tx_axis_arp_tready)
      tx_axis_arp_tlast_ff <= 1'b0;
  
//------------------------------------
//             Output Port
//------------------------------------
  assign tx_axis_arp_tdata  = tx_axis_arp_tdata_ff;
  assign tx_axis_arp_tvalid = tx_axis_arp_tvalid_ff;
  assign tx_axis_arp_tlast  = tx_axis_arp_tlast_ff;
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
