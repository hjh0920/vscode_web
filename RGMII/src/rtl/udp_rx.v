// UDP报文接收模块

module udp_rx(
  // 用于 UDP 校验和计算
  input  [7:0]  rx_ip_proto, // 接收 IP 报文协议
  input  [31:0] rx_ip_src, // 接收 IP 报文源地址
  input  [31:0] rx_ip_dst, // 接收 IP 报文目的地址
  // 接收 IP 数据
  input         rx_mac_aclk,
  input         rx_mac_reset,
  input  [7:0]  rx_axis_ip_tdata,
  input         rx_axis_ip_tvalid,
  input         rx_axis_ip_tlast,
  input  [1:0]  rx_axis_ip_tuser, // [0]: MAC error, [1]: IP error
  input         rx_axis_ip_tdest // 0: UDP, 1: ICMP
);

//------------------------------------
//             Local Signal
//------------------------------------


//------------------------------------
//             User Logic
//------------------------------------

//------------------------------------
//             Output Port
//------------------------------------


//------------------------------------
//             Instance
//------------------------------------

endmodule
