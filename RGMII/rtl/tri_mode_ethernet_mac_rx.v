// 三速以太网MAC接收模块, 支持CRC校验, 输出默认不输出前导码/SFD/填充字段/FCS
// rx_axis_mac_tuser 在 rx_axis_mac_tlast 置位时有效, tuser 置位表示出现如下情况:
//   1. 残缺帧
//   2. 帧过滤使能时, 接收帧的目的MAC地址非本地MAC和广播地址
//   3. 接收帧帧类型非ARP或IP报文
//   4. 接收超时
//   5. CRC校验错误

module tri_mode_ethernet_mac_rx #(
  // 帧过滤使能, 与本地MAC地址不一致过滤
  parameter C_FILTER_EN = 1,
  // 本地MAC地址
  parameter C_LOCAL_MAC = 48'h0102_0304_0506,
  // 接收超时时间(unit: rx_mac_aclk)
  parameter C_TIMEOUT   = 3000
)(
  input  [1:0]  inband_clock_speed, // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
  // RGMII 接收数据 AXIS 接口
  input         rx_mac_aclk,
  input         rx_mac_reset,
  input  [7:0]  rx_axis_rgmii_tdata,
  input         rx_axis_rgmii_tvalid,
  // 用户接收数据 AXIS 接口
  output  [7:0] rx_axis_mac_tdata,
  output        rx_axis_mac_tvalid,
  output        rx_axis_mac_tlast,
  output        rx_axis_mac_tuser
);
  
//------------------------------------
//             Local Parameter
//------------------------------------
  localparam S_IDLE      = 4'd0; // 初始状态
  localparam S_PREAMBLE  = 4'd1; // 接收前导码+SFD
  localparam S_MAC_HEAD  = 4'd2; // 接收MAC帧头
  localparam S_FILTER    = 4'd3; // 帧过滤
  localparam S_ARP       = 4'd4; // 接收ARP数据
  localparam S_IP_HEAD   = 4'd5; // 接收IP首部
  localparam S_IP_DATA   = 4'd6; // 接收IP数据
  localparam S_FCS       = 4'd7; // 接收FCS
  localparam S_FCS_CHECK = 4'd8; // 判断FCS
//------------------------------------
//             Local Signal
//------------------------------------
  reg  [3:0]      rx_mac_state = S_IDLE; // 状态机
  reg  [3:0]      rx_mac_state_d1 = S_IDLE;
  reg  [8*14-1:0] rx_axis_rgmii_tdata_ff = 0; // 输入数据寄存
  reg             rx_axis_rgmii_tvalid_d1 = 0; // 打拍
  reg  [15:0]     rx_timeout_cnt = 0; // 接收超时计数器
  reg  [11:0]     rx_byte_cnt = 0; // 接收字节计数器
  reg  [47:0]     rx_dst_mac = 0; // 接收帧目的MAC
  reg  [15:0]     rx_eth_type = 0; // 接收帧帧类型, IP(0x0800), ARP(0x0806)
  reg  [15:0]     rx_ip_total_length = 0; // 接收IP报文总长度
  reg  [15:0]     rx_eth_fcs = 0; // 接收FCS
  reg  [7:0]      rx_last_data = 0; // 最后一个数据锁存, 等待整帧数据接收校验完成再输出

  reg          rx_preamble_flag = 0; // 接收到前导码+SFD
  reg          rx_preamble_type_flag = 0; // 前导码+SFD组成类型(因为采样位置不同会出现两种情况: SFD在高nibble(0), SFD在低nibble(1))
  reg          rx_dst_mac_match = 0; // 目的MAC匹配成功(本地MAC或者广播MAC)
  reg          rx_eth_type_match = 0; // 以太网报文帧类型匹配成功(IP报文/ARP报文)
  reg          rx_eth_head_done = 0; // 完成以太网报文帧头接收
  wire         rx_arp_data_done; // 完成ARP报文数据接收
  reg          rx_ip_head_done = 0; // 完成IP报文首部接收
  reg          rx_ip_data_done = 0; // 完成IP报文数据接收
  reg          rx_timeout_flag = 0; // 接收超时
  reg          rx_filter_success = 0; // 帧过滤成功
// CRC校验模块
  reg          rx_crc32_reset = 1;
  reg  [7:0]   rx_crc32_din = 0;
  reg          rx_crc32_enable = 0;
  reg  [31:0]  rx_crc32_result = 0;
  wire [31:0]  rx_crc32_result_temp;
// 输出寄存器
  reg  [7:0]   rx_axis_mac_tdata_ff = 0;
  reg          rx_axis_mac_tvalid_ff = 0;
  reg          rx_axis_mac_tlast_ff = 0;
  reg          rx_axis_mac_tuser_ff = 0;

//------------------------------------
//             User Logic
//------------------------------------
// 输入数据寄存
  always @ (posedge rx_mac_aclk)
    if (rx_mac_reset)
      rx_axis_rgmii_tdata_ff <= 'd0;
    else if (rx_axis_rgmii_tvalid)
      rx_axis_rgmii_tdata_ff <= {rx_axis_rgmii_tdata_ff[8*13-1:0],rx_axis_rgmii_tdata};
// 输入打拍
  always @ (posedge rx_mac_aclk)
    if (rx_mac_reset)
      rx_axis_rgmii_tvalid_d1 <= 1'b0;
    else
      rx_axis_rgmii_tvalid_d1 <= rx_axis_rgmii_tvalid;
// 状态机
  always @ (posedge rx_mac_aclk)
    if (rx_mac_reset)
      rx_mac_state <= S_IDLE;
    else
      case(rx_mac_state)
        S_IDLE: 
          if (rx_axis_rgmii_tvalid) rx_mac_state <= S_PREAMBLE;
        S_PREAMBLE:
          if (rx_preamble_flag) rx_mac_state <= S_MAC_HEAD;
        S_MAC_HEAD:
          if (rx_timeout_flag)
            rx_mac_state <= S_IDLE;
          else if (rx_eth_head_done)
            rx_mac_state <= S_FILTER;
        S_FILTER:
          if ((!C_FILTER_EN[0] || rx_dst_mac_match) && (rx_eth_type == 16'h0800)) // IP报文
            rx_mac_state <= S_IP_HEAD;
          else if ((!C_FILTER_EN[0] || rx_dst_mac_match) && (rx_eth_type == 16'h0806)) // ARP报文
            rx_mac_state <= S_ARP;
          else
            rx_mac_state <= S_IDLE;
        S_ARP:
          if (rx_timeout_flag)
            rx_mac_state <= S_IDLE;
          else if (rx_arp_data_done)
            rx_mac_state <= S_FCS;
        S_IP_HEAD:
          if (rx_timeout_flag)
            rx_mac_state <= S_IDLE;
          else if (rx_ip_head_done)
            rx_mac_state <= S_IP_DATA;
        S_IP_DATA:
          if (rx_timeout_flag)
            rx_mac_state <= S_IDLE;
          else if (rx_ip_data_done)
            rx_mac_state <= S_FCS;
        S_FCS:
          rx_mac_state <= S_FCS_CHECK;
        S_FCS_CHECK:
          rx_mac_state <= S_IDLE;
        default: rx_mac_state <= S_IDLE;
      endcase
// 接收字节计数器
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_IDLE)
      rx_byte_cnt <= 12'd0;
    else if (rx_mac_state == S_PREAMBLE)
      begin
        if (rx_preamble_flag && rx_axis_rgmii_tvalid)
          rx_byte_cnt <= 12'd1;
        else
          rx_byte_cnt <= 12'd0;
      end
    else if (rx_axis_rgmii_tvalid)
      rx_byte_cnt <= rx_byte_cnt + 12'd1;
// 接收前导码+SFD
  always @ (posedge rx_mac_aclk)
    if ((inband_clock_speed == 2'b10) && rx_axis_rgmii_tvalid && ({rx_axis_rgmii_tdata_ff[8*7-1:0],rx_axis_rgmii_tdata} == 64'h5555_5555_5555_55D5))
      rx_preamble_flag <= 1'b1;
    else if ((inband_clock_speed[1] == 1'b0) && rx_axis_rgmii_tvalid && (({rx_axis_rgmii_tdata_ff[8*7-1:0],rx_axis_rgmii_tdata} == 64'h5555_5555_5555_555D) || ({rx_axis_rgmii_tdata_ff[8*7+3:0],rx_axis_rgmii_tdata[7:4]} == 64'h5555_5555_5555_555D)))
      rx_preamble_flag <= 1'b1;
    else
      rx_preamble_flag <= 1'b0;
// 接收帧目的MAC
  always @ (posedge rx_mac_aclk)
    if ((rx_byte_cnt == 12'd6) && (rx_axis_rgmii_tvalid))
      begin
        if (inband_clock_speed[1])
          rx_dst_mac <= rx_axis_rgmii_tdata_ff[47:0];
        else if (rx_preamble_type_flag)
          rx_dst_mac <= {rx_axis_rgmii_tdata_ff[43:40],rx_axis_rgmii_tdata_ff[47:44],rx_axis_rgmii_tdata_ff[35:32],rx_axis_rgmii_tdata_ff[39:36],
                         rx_axis_rgmii_tdata_ff[27:24],rx_axis_rgmii_tdata_ff[31:28],rx_axis_rgmii_tdata_ff[19:16],rx_axis_rgmii_tdata_ff[23:20],
                         rx_axis_rgmii_tdata_ff[11: 8],rx_axis_rgmii_tdata_ff[15:12],rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4]};
        else
          rx_dst_mac <= {rx_axis_rgmii_tdata_ff[47:44],rx_axis_rgmii_tdata_ff[51:48],rx_axis_rgmii_tdata_ff[39:36],rx_axis_rgmii_tdata_ff[43:40],
                         rx_axis_rgmii_tdata_ff[31:28],rx_axis_rgmii_tdata_ff[35:32],rx_axis_rgmii_tdata_ff[23:20],rx_axis_rgmii_tdata_ff[27:24],
                         rx_axis_rgmii_tdata_ff[15:12],rx_axis_rgmii_tdata_ff[19:16],rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8]};  
      end
// 接收帧类型
  always @ (posedge rx_mac_aclk)
    if ((rx_byte_cnt == 12'd13) && (rx_axis_rgmii_tvalid))
      begin
        if (inband_clock_speed[1])
          rx_eth_type <= {rx_axis_rgmii_tdata_ff[7:0],rx_axis_rgmii_tdata};
        else if (rx_preamble_type_flag)
          rx_eth_type <= {rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata[ 3: 0],rx_axis_rgmii_tdata[ 7: 4]};
        else
          rx_eth_type <= {rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8],rx_axis_rgmii_tdata[ 7: 4],rx_axis_rgmii_tdata_ff[ 3: 0]};
      end
// 接收IP报文总长度
  always @ (posedge rx_mac_aclk)
    if ((rx_byte_cnt == 12'd17) && (rx_axis_rgmii_tvalid))
      begin
        if (inband_clock_speed[1])
          rx_ip_total_length <= {rx_axis_rgmii_tdata_ff[7:0],rx_axis_rgmii_tdata};
        else if (rx_preamble_type_flag)
          rx_ip_total_length <= {rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata[ 3: 0],rx_axis_rgmii_tdata[ 7: 4]};
        else
          rx_ip_total_length <= {rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8],rx_axis_rgmii_tdata[ 7: 4],rx_axis_rgmii_tdata_ff[ 3: 0]};
      end
// 接收FCS
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_FCS)
      rx_eth_fcs <= rx_axis_rgmii_tdata_ff[31:0];
    else if (rx_preamble_type_flag)
      rx_eth_fcs <= {rx_axis_rgmii_tdata_ff[27:24],rx_axis_rgmii_tdata_ff[31:28],rx_axis_rgmii_tdata_ff[19:16],rx_axis_rgmii_tdata_ff[23:20],
                      rx_axis_rgmii_tdata_ff[11: 8],rx_axis_rgmii_tdata_ff[15:12],rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4]};
    else
      rx_eth_fcs <= {rx_axis_rgmii_tdata_ff[31:28],rx_axis_rgmii_tdata_ff[35:32],rx_axis_rgmii_tdata_ff[23:20],rx_axis_rgmii_tdata_ff[27:24],
                      rx_axis_rgmii_tdata_ff[15:12],rx_axis_rgmii_tdata_ff[19:16],rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8]};  
// 目的MAC匹配成功(本地MAC或者广播MAC)
  always @ (posedge rx_mac_aclk)
    if (rx_dst_mac == C_LOCAL_MAC || rx_dst_mac == 48'hFFFF_FFFF_FFFF)
      rx_dst_mac_match <= 1'b1;
    else
      rx_dst_mac_match <= 1'b0;
// 以太网报文帧类型匹配成功(IP报文/ARP报文)
  always @ (posedge rx_mac_aclk)
    if ((rx_eth_type == 16'h0800) || (rx_eth_type == 16'h0806))
      rx_eth_type_match <= 1'b1;
    else
      rx_eth_type_match <= 1'b0;
// 完成以太网报文帧头接收
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 12'd13 && rx_axis_rgmii_tvalid)
      rx_eth_head_done <= 1'b1;
    else
      rx_eth_head_done <= 1'b0;
// 完成ARP报文数据接收
  assign rx_arp_data_done = (rx_byte_cnt == 12'd63 && rx_axis_rgmii_tvalid);
// 完成IP报文首部接收
  always @ (posedge rx_mac_aclk)
    if (rx_byte_cnt == 12'd33 && rx_axis_rgmii_tvalid)
      rx_ip_head_done <= 1'b1;
    else
      rx_ip_head_done <= 1'b0;
// 完成IP报文数据接收
  always @(posedge rx_mac_aclk)
    if ((rx_mac_state == S_IP_DATA) && rx_axis_rgmii_tvalid && (
       ((rx_ip_total_length < 16'd46) && (rx_byte_cnt == 12'd63)) ||
       ((rx_ip_total_length > 16'd45) && (rx_byte_cnt == (12'd17 + rx_ip_total_length[11:0])))
       ))
      rx_ip_data_done <= 1'b1;
    else
      rx_ip_data_done <= 1'b0;
// 接收超时计数器
  always @ (posedge rx_mac_aclk) rx_mac_state_d1 <= rx_mac_state;
  always @ (posedge rx_mac_aclk)
    if ((rx_mac_state == S_IDLE) || (rx_mac_state == S_PREAMBLE) || (rx_mac_state == rx_mac_state_d1))
      rx_timeout_cnt <= 16'd0;
    else
      rx_timeout_cnt <= rx_timeout_cnt + 16'd1;
// 接收超时
  always @ (posedge rx_mac_aclk)
    if (rx_timeout_cnt == C_TIMEOUT[15:0])
      rx_timeout_flag <= 1'b1;
    else 
      rx_timeout_flag <= 1'b0;
// 帧过滤成功
  always @(posedge rx_mac_aclk)
    if ((rx_mac_state == S_FILTER) && ((!rx_eth_type_match) || (C_FILTER_EN[0] && (!rx_dst_mac_match))))
      rx_filter_success <= 1'b1;
    else
      rx_filter_success <= 1'b0;
// CRC校验模块复位
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_PREAMBLE)
      rx_crc32_reset <= 1'b1;
    else
      rx_crc32_reset <= 1'b0;
// CRC校验模块使能
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_PREAMBLE)
      rx_crc32_enable <= 1'b0;
    else if (rx_mac_state == S_MAC_HEAD) // 以太网帧类型还没解析完成
      rx_crc32_enable <= rx_axis_rgmii_tvalid_d1;
    else if ((rx_eth_type == 16'h0806) || ((rx_eth_type == 16'h0800) && rx_ip_total_length < 16'd46)) // 以太网帧长小于64字节
      begin
        if (rx_byte_cnt > 12'd60)
          rx_crc32_enable <= 1'b0;
        else if (rx_byte_cnt > 12'd0)
          rx_crc32_enable <= rx_axis_rgmii_tvalid_d1;
      end
    else if (rx_eth_type == 16'h0800) // 以太网帧长大于64字节
      begin
        if (rx_byte_cnt > (12'd14 + rx_ip_total_length[11:0]))
          rx_crc32_enable <= 1'b0;
        else if (rx_byte_cnt > 12'd0)
          rx_crc32_enable <= rx_axis_rgmii_tvalid_d1;
      end
// CRC校验模块输入数据
  always @ (posedge rx_mac_aclk)
    if (inband_clock_speed[1])
      rx_crc32_din <= rx_axis_rgmii_tdata_ff[7:0];
    else if (rx_preamble_type_flag)
      rx_crc32_din <= {rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4]};
    else
      rx_crc32_din <= {rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8]};
// CRC校验模块输出结果锁存
  always @ (posedge rx_mac_aclk)
    if (rx_arp_data_done | rx_ip_data_done)
      rx_crc32_result <= {~rx_crc32_result_temp[24],~rx_crc32_result_temp[25],~rx_crc32_result_temp[26],~rx_crc32_result_temp[27],~rx_crc32_result_temp[28],~rx_crc32_result_temp[29],~rx_crc32_result_temp[30],~rx_crc32_result_temp[31],
                       ~rx_crc32_result_temp[16],~rx_crc32_result_temp[17],~rx_crc32_result_temp[18],~rx_crc32_result_temp[19],~rx_crc32_result_temp[20],~rx_crc32_result_temp[21],~rx_crc32_result_temp[22],~rx_crc32_result_temp[23],
                       ~rx_crc32_result_temp[ 8],~rx_crc32_result_temp[ 9],~rx_crc32_result_temp[10],~rx_crc32_result_temp[11],~rx_crc32_result_temp[12],~rx_crc32_result_temp[13],~rx_crc32_result_temp[14],~rx_crc32_result_temp[15],
                       ~rx_crc32_result_temp[ 0],~rx_crc32_result_temp[ 1],~rx_crc32_result_temp[ 2],~rx_crc32_result_temp[ 3],~rx_crc32_result_temp[ 4],~rx_crc32_result_temp[ 5],~rx_crc32_result_temp[ 6],~rx_crc32_result_temp[ 7]};
// 最后一个数据锁存, 等待整帧数据接收校验完成再输出
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_IDLE)
      rx_last_data <= 8'h00;
    else if (((rx_eth_type == 16'h0806) && (rx_byte_cnt == 12'd42)) || ((rx_eth_type == 16'h0800) && (rx_byte_cnt == (12'd14 + rx_ip_total_length[11:0]))))
      begin
        if (inband_clock_speed[1])
          rx_last_data <= rx_axis_rgmii_tdata_ff[7:0];
        else if (rx_preamble_type_flag)
          rx_last_data <= {rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4]};
        else
          rx_last_data <= {rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8]};
      end
// 用户接收数据AXIS接口寄存器
  always @ (posedge rx_mac_aclk)
    if (rx_mac_state == S_FCS_CHECK)
      rx_axis_mac_tdata_ff <= rx_last_data;
    else if (rx_byte_cnt > 12'd0)
      begin
        if (inband_clock_speed[1])
          rx_axis_mac_tdata_ff <= rx_axis_rgmii_tdata_ff[7:0];
        else if (rx_preamble_type_flag)
          rx_axis_mac_tdata_ff <= {rx_axis_rgmii_tdata_ff[ 3: 0],rx_axis_rgmii_tdata_ff[ 7: 4]};
        else
          rx_axis_mac_tdata_ff <= {rx_axis_rgmii_tdata_ff[ 7: 4],rx_axis_rgmii_tdata_ff[11: 8]};
      end
  always @ (posedge rx_mac_aclk)
    if (rx_mac_reset)
      rx_axis_mac_tvalid_ff <= 1'b0;
    else if (rx_timeout_flag || (rx_mac_state == S_FCS_CHECK) || rx_filter_success)
      rx_axis_mac_tvalid_ff <= 1'b1;
    else if ((rx_mac_state == S_IP_HEAD) || ((rx_eth_type == 16'h0806) && (rx_byte_cnt < 12'd42)) || ((rx_eth_type == 16'h0800) && (rx_byte_cnt < (12'd14 + rx_ip_total_length[11:0]))))
      rx_axis_mac_tvalid_ff <= rx_axis_rgmii_tvalid_d1;
    else
      rx_axis_mac_tvalid_ff <= 1'b0;
  always @ (posedge rx_mac_aclk)
    if (rx_timeout_flag || (rx_mac_state == S_FCS_CHECK) || rx_filter_success)
      rx_axis_mac_tlast_ff <= 1'b1;
    else
      rx_axis_mac_tlast_ff <= 1'b0;
  always @ (posedge rx_mac_aclk)
    if (rx_timeout_flag || ((rx_mac_state == S_FCS_CHECK) && (rx_crc32_result != rx_eth_fcs)) || rx_filter_success)
      rx_axis_mac_tuser_ff <= 1'b1;
    else
      rx_axis_mac_tuser_ff <= 1'b0;
    
//------------------------------------
//             Output Port
//------------------------------------
  assign rx_axis_mac_tdata = rx_axis_mac_tdata_ff;
  assign rx_axis_mac_tvalid = rx_axis_mac_tvalid_ff;
  assign rx_axis_mac_tlast = rx_axis_mac_tlast_ff;
  assign rx_axis_mac_tuser = rx_axis_mac_tuser_ff;
//------------------------------------
//             Instance
//------------------------------------
// CRC校验模块
  crc32 eth_rx_crc32(
    .clk            (rx_mac_aclk),
    .reset          (rx_crc32_reset),
    .din            (rx_crc32_din),
    .enable         (rx_crc32_enable),
    .crc32          (rx_crc32_result_temp),
    .crc32_next  ()
  );

endmodule