// ARP报文接收模块

module arp_rx (
  parameter LOCAL_IP = 32'hC0_A8_01_01 // 本机 IP 地址, 默认为 192.168.1.1
)(
  // 接收 MAC 数据
  input         rx_mac_aclk,
  input         rx_mac_reset,
  input  [7:0]  rx_axis_mac_tdata,
  input         rx_axis_mac_tvalid,
  input         rx_axis_mac_tlast,
  input         rx_axis_mac_tuser,
  // 用于 ARP 应答
  output        rx_arp_req, // ARP 请求信号
  output [47:0] rx_arp_smac, // ARP 报文源 MAC 地址
  output [31:0] rx_arp_sip // ARP 报文源 IP 地址
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [7:0]  rx_axis_mac_tdata_d1 = 0; // 打拍, 用于数据解析
  reg  [7:0]  rx_axis_mac_tdata_d2 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d3 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d4 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d5 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d6 = 0;
  reg  [10:0] rx_byte_cnt = 0; // 接收字节计数器
  reg  [15:0] rx_eth_type = 0; // 接收以太网类型
  reg  [15:0] rx_arp_opcode = 0; // 接收 ARP 报文操作码
  reg  [31:0] rx_arp_dip = 0; // 接收 ARP 报文目的 IP 地址
  reg  [47:0] rx_arp_smac_ff = 0; // 接收 ARP 报文源 MAC 地址
  reg  [31:0] rx_arp_sip_ff = 0; // 接收 ARP 报文源 IP 地址
  reg         rx_arp_req_ff = 0; // ARP 请求信号
//------------------------------------
//             User Logic
//------------------------------------
// 打拍, 用于数据解析
  always @ (posedge rx_mac_aclk)
    if (rx_axis_mac_tvalid)
      begin
        rx_axis_mac_tdata_d1 <= rx_axis_mac_tdata;
        rx_axis_mac_tdata_d2 <= rx_axis_mac_tdata_d1;
        rx_axis_mac_tdata_d3 <= rx_axis_mac_tdata_d2;
        rx_axis_mac_tdata_d4 <= rx_axis_mac_tdata_d3;
        rx_axis_mac_tdata_d5 <= rx_axis_mac_tdata_d4;
        rx_axis_mac_tdata_d6 <= rx_axis_mac_tdata_d5;
      end
// 接收字节计数器
  always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
    if (rx_mac_reset)
      rx_byte_cnt <= 11'b0;
    else if (rx_axis_mac_tvalid && rx_axis_mac_tlast)
      rx_byte_cnt <= 11'b0;
    else if (rx_axis_mac_tvalid)
      rx_byte_cnt <= rx_byte_cnt + 11'b1;
// 接收以太网类型
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd14) rx_eth_type <= {rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 ARP 报文操作码
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd22) rx_arp_opcode <= {rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 ARP 报文源 MAC 地址
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd28) rx_arp_smac_ff <= {rx_axis_mac_tdata_d6,rx_axis_mac_tdata_d5,rx_axis_mac_tdata_d4,rx_axis_mac_tdata_d3,rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 ARP 报文源 IP 地址
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd32) rx_arp_sip_ff <= {rx_axis_mac_tdata_d4,rx_axis_mac_tdata_d3,rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 ARP 报文目的 IP 地址
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd42) rx_arp_dip <= {rx_axis_mac_tdata_d4,rx_axis_mac_tdata_d3,rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// ARP 请求信号: 接收到ARP请求报文 && 报文无错误 && 目的 IP 为本机 IP
  always @ (posedge rx_mac_aclk)
    if ((rx_eth_type == 16'h0806) && (rx_arp_opcode == 16'h0001) && (rx_axis_mac_tvalid && rx_axis_mac_tlast && (!rx_axis_mac_tuser)) && (rx_arp_dip == LOCAL_IP[31:0]))
      rx_arp_req_ff <= 1'b1;
    else
      rx_arp_req_ff <= 1'b0;

//------------------------------------
//             Output Port
//------------------------------------
  assign rx_arp_req  = rx_arp_req_ff;
  assign rx_arp_smac = rx_arp_smac_ff;
  assign rx_arp_sip  = rx_arp_sip_ff;

endmodule
