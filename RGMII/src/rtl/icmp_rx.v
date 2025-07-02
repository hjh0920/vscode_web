// ICMP报文接收模块

module icmp_rx(
  input  [7:0]  rx_ip_proto, // 接收 IP 报文协议
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
