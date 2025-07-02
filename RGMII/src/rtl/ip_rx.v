// IP报文接收模块, 默认接收IP首部长度 20 Bytes

module ip_rx(
  // 接收 MAC 数据
  input         rx_mac_aclk,
  input         rx_mac_reset,
  input  [7:0]  rx_axis_mac_tdata,
  input         rx_axis_mac_tvalid,
  input         rx_axis_mac_tlast,
  input         rx_axis_mac_tuser,
  // 用于 UDP 校验和计算
  output [7:0]  rx_ip_proto, // 接收 IP 报文协议
  output [31:0] rx_ip_src, // 接收 IP 报文源地址
  output [31:0] rx_ip_dst, // 接收 IP 报文目的地址
  // 接收 IP 数据
  output [7:0]  rx_axis_ip_tdata,
  output        rx_axis_ip_tvalid,
  output        rx_axis_ip_tlast,
  output [1:0]  rx_axis_ip_tuser, // [0]: MAC error, [1]: IP error
  output        rx_axis_ip_tdest // 0: UDP, 1: ICMP
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [7:0]  rx_axis_mac_tdata_d1 = 0; // 打拍, 用于数据解析
  reg  [7:0]  rx_axis_mac_tdata_d2 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d3 = 0;
  reg  [7:0]  rx_axis_mac_tdata_d4 = 0;
  reg  [10:0] rx_byte_cnt = 0; // 接收字节计数器
  reg  [15:0] rx_eth_type = 0; // 接收以太网类型
  reg  [7:0]  rx_ip_proto_ff = 0; // 接收 IP 报文协议
  reg  [15:0] rx_ip_csum = 0; // 接收 IP 报文校验和
  reg  [31:0] rx_ip_src_ff = 0; // 接收 IP 报文源地址
  reg  [31:0] rx_ip_dst_ff = 0; // 接收 IP 报文目的地址
  reg  [19:0] rx_ip_csum_calc = 0; // 计算 IP 报文校验和
  reg  [15:0] rx_ip_csum_result = 0; // 计算得到的 IP 报文校验和
  reg  [7:0]  rx_axis_ip_tdata_ff = 0;
  reg         rx_axis_ip_tvalid_ff = 0;
  reg         rx_axis_ip_tlast_ff = 0;
  reg  [1:0]  rx_axis_ip_tuser_ff = 0; // [0]: MAC error, [1]: IP error
  reg         rx_axis_ip_tdest_ff = 0; // 0: UDP, 1: ICMP
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
// 接收 IP 报文协议
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd24) rx_ip_proto_ff <= rx_axis_mac_tdata_d1;
// 接收 IP 报文校验和
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd26) rx_ip_csum <= {rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 IP 报文源地址
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd30) rx_ip_src_ff <= {rx_axis_mac_tdata_d4,rx_axis_mac_tdata_d3,rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 接收 IP 报文目的地址
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd34) rx_ip_dst_ff <= {rx_axis_mac_tdata_d4,rx_axis_mac_tdata_d3,rx_axis_mac_tdata_d2,rx_axis_mac_tdata_d1};
// 计算 IP 报文校验和
  always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
    if (rx_mac_reset)
      rx_ip_csum_calc <= 20'b0;
    else if (rx_axis_mac_tvalid && rx_axis_mac_tlast)
      rx_ip_csum_calc <= 20'b0;
    else if (rx_axis_mac_tvalid && (rx_byte_cnt >= 11'd12) && (rx_byte_cnt < 11'd32) && (rx_byte_cnt != 11'd25))
      begin
        if (rx_byte_cnt[0])
          rx_ip_csum_calc <= rx_ip_csum_calc + {12'b0,rx_axis_mac_tdata};
        else
          rx_ip_csum_calc <= rx_ip_csum_calc + {4'b0,rx_axis_mac_tdata,8'b0};
      end
// 计算得到的 IP 报文校验和
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 11'd32) rx_ip_csum_result <= ~(rx_ip_csum_calc[15:0] + {12'b0,rx_ip_csum_calc[19:16]});
// 接收 IP 数据
  always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
    if (rx_mac_reset)
      rx_axis_ip_tvalid_ff <= 1'b0;
    else if ((rx_eth_type == 16'h0800) && ((rx_ip_proto_ff == 8'h01) || (rx_ip_proto_ff == 8'h11)) && (rx_byte_cnt >= 11'd34))
      rx_axis_ip_tvalid_ff <= rx_axis_mac_tvalid;
    else
      rx_axis_ip_tvalid_ff <= 1'b0;

  always @ (posedge rx_mac_aclk)
    if (rx_axis_mac_tlast && (rx_ip_csum_result != rx_ip_csum))
      rx_axis_ip_tuser_ff <= {1'b1,rx_axis_mac_tuser};
    else
      rx_axis_ip_tuser_ff <= {1'b0,rx_axis_mac_tuser};
      
  always @ (posedge rx_mac_aclk) rx_axis_ip_tdata_ff <= rx_axis_mac_tdata;
  always @ (posedge rx_mac_aclk) rx_axis_ip_tlast_ff <= rx_axis_mac_tlast;
  always @ (posedge rx_mac_aclk) rx_axis_ip_tdest_ff <= (rx_ip_proto_ff == 8'h01); // 0: UDP, 1: ICMP
//------------------------------------
//             Output Port
//------------------------------------
  assign rx_ip_proto       = rx_ip_proto_ff;
  assign rx_ip_src         = rx_ip_src_ff;
  assign rx_ip_dst         = rx_ip_dst_ff;
  assign rx_axis_ip_tdata  = rx_axis_ip_tdata_ff;
  assign rx_axis_ip_tvalid = rx_axis_ip_tvalid_ff;
  assign rx_axis_ip_tlast  = rx_axis_ip_tlast_ff;
  assign rx_axis_ip_tuser  = rx_axis_ip_tuser_ff;
  assign rx_axis_ip_tdest  = rx_axis_ip_tdest_ff;

endmodule
