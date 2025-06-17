// 三速以太网MAC接收模块, 支持填充前导码 & SFD & 填充字段 & FCS 以及不足64字节长度填充

module tri_mode_ethernet_mac_tx #(
  // 帧间隔(Unit: bit time, 8整倍数)
  parameter C_IFG = 96
)(
  input [1:0]   inband_clock_speed,   // 125MHz, 25MHz, 2.5MHz
  // RGMII 发送数据 AXIS 接口
  input         tx_mac_alck,
  input         tx_mac_reset,
  output [7:0]  tx_axis_rgmii_tdata,
  output        tx_axis_rgmii_tvalid,
  input         tx_axis_rgmii_tready,
  // 用户发送数据 AXIS 接口
  input         tx_axis_mac_tvalid,
  input [7:0]   tx_axis_mac_tdata,
  input         tx_axis_mac_tlast,
  output        tx_axis_mac_tready
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam  C_IFG_1000M_CNT = (C_IFG/8-4);
  localparam  C_IFG_100M_CNT = (C_IFG/8*10-4);
  localparam  C_IFG_10M_CNT = (C_IFG/8*100-4);

//------------------------------------
//             Local Signal
//------------------------------------  
  wire [1:0]   inband_clock_speed_txclk;
  reg          tx_mac_en = 0; // 发送帧使能
  reg  [11:0]  tx_byte_cnt = 0; // 发送字节计数器
  reg  [11:0]  tx_total_byte = 0; // 发送总字节计数器
  reg          tx_55d5_flag = 1; // 前导码+SFD填充标志 
  reg          tx_stuff_flag = 1; // 不足64字节填充标志 
  reg          tx_data_flag = 1; // 发送帧数据标志 
  reg          tx_fcs_flag = 1; // 发送FCS标志 
  reg          tx_fcs_flag_d1 = 1; 
  reg  [1:0]   tx_fcs_byte_cnt = 0; // 发送fcs字节计数器
  reg          tx_mac_done = 0; // 完成一帧MAC帧发送
  reg          tx_mac_done_d1 = 0; 
  reg          tx_ifg_flag = 0; // 发送帧间隔标志 
  reg          tx_ifg_flag_d1 = 0;
  reg  [31:0]  tx_ifg_cnt = 0; // 发送帧间隔计数器
// CRC校验模块
  reg          tx_crc32_reset = 1;
  reg  [7:0]   tx_crc32_din = 0;
  reg          tx_crc32_enable = 0;
  reg  [31:0]  tx_crc32_result = 0;
// 输出寄存器
  reg  [7:0]   tx_axis_rgmii_tdata_ff = 8'h55;
  reg          tx_axis_rgmii_tvalid_ff = 0;

//------------------------------------
//             User Logic
//------------------------------------  
// 发送帧使能
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_mac_en <= 1'b0;
    else if (tx_axis_mac_tvalid)
      tx_mac_en <= 1'b1;
    else if (tx_mac_done)
      tx_mac_en <= 1'b0;
// 发送字节计数器
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_byte_cnt <= 12'd0;
    else if (tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_byte_cnt <= tx_byte_cnt + 12'd1;
// 发送总字节计数器
    always @(posedge tx_mac_aclk)
      if (tx_mac_reset)
        tx_total_byte <= 0;
      else if (tx_axis_mac_tvalid && tx_axis_mac_tready && tx_axis_mac_tlast) && (tx_byte_cnt < 12'd67)
        tx_total_byte <= 12'd71;
      else if (tx_axis_mac_tvalid && tx_axis_mac_tready && tx_axis_mac_tlast)
        tx_total_byte <= tx_byte_cnt + 12'd5;
// 前导码+SFD填充标志
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_55d5_flag <= 1'b1;
    else if ((tx_byte_cnt == 12'd6) && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_55d5_flag <= 1'b0;
    else if (tx_mac_done)
      tx_55d5_flag <= 1'b1;
// 不足64字节填充标志
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_stuff_flag <= 1'b1;
    else if ((tx_byte_cnt < 12'd67) && tx_axis_mac_tvalid && tx_axis_mac_tready && tx_axis_mac_tlast)
      tx_stuff_flag <= 1'b1;
    else if (tx_mac_done)
      tx_stuff_flag <= 1'b0;
// 发送帧数据标志
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_data_flag <= 1'b1;
    else if (tx_axis_mac_tvalid && tx_axis_mac_tready && tx_axis_mac_tlast)
      tx_data_flag <= 1'b0;
    else if (tx_ifg_flag && (!tx_ifg_flag_d1))
      tx_data_flag <= 1'b1;
// 发送FCS标志
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_fcs_flag <= 1'b0;
    else if ((tx_fcs_byte_cnt = 2'd3) && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_fcs_flag <= 1'b0;
    else if (((tx_byte_cnt == 12'd66) && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready && tx_stuff_flag) 
           || ((tx_byte_cnt > 12'd66) && tx_axis_mac_tvalid && tx_axis_mac_tready && tx_axis_mac_tlast))
      tx_fcs_flag <= 1'b1;
// 发送fcs字节计数器
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_fcs_byte_cnt <= 2'd0;
    else if (!tx_fcs_flag)
      tx_fcs_byte_cnt <= 2'd0;
    else if (tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_fcs_byte_cnt <= tx_fcs_byte_cnt + 2'd1;
// 完成一帧MAC帧发送
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_mac_done <= 1'b0;
    else if (tx_stuff_flag)
      begin 
        if ((tx_byte_cnt == 12'd71) && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
          tx_mac_done <= 1'b1;
        else
          tx_mac_done <= 1'b0;
      end
    else if ((tx_byte_cnt == tx_total_byte) && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready && tx_fcs_flag_d1)
      tx_mac_done <= 1'b1;
    else
      tx_mac_done <= 1'b0;
  always @ (posedge tx_mac_aclk) tx_mac_done_d1 <= tx_mac_done;
// 发送帧间隔标志
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_ifg_flag <= 1'b0;
    else if (tx_mac_done)
      tx_ifg_flag <= 1'b1;
    else if (((inband_clock_speed_txclk == 2'b10) && (tx_ifg_cnt == C_IFG_1000M_CNT))
        || ((inband_clock_speed_txclk == 2'b01) && (tx_ifg_cnt == C_IFG_100M_CNT))
        || ((inband_clock_speed_txclk == 2'b00) && (tx_ifg_cnt == C_IFG_10M_CNT)))
      tx_ifg_flag <= 1'b0;
  always @ (posedge tx_mac_aclk) tx_fcs_flag_d1 <= tx_fcs_flag;
// 发送帧间隔计数器
  always @(posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_ifg_cnt <= 32'd0;
    else if (tx_ifg_flag)
      tx_ifg_cnt <= tx_ifg_cnt + 32'd1;
    else
      tx_ifg_cnt <= 32'd0;
// 输出寄存器
  always @ (posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_axis_rgmii_tdata_ff <= 8'h55;
    else if (tx_mac_done_d1)
      tx_axis_rgmii_tdata_ff <= 8'h55;
    else if (tx_fcs_flag && tx_axis_rgmii_tready) // 发送FCS
      case (tx_fcs_byte_cnt)
        2'd0: tx_axis_rgmii_tdata_ff <= {~tx_crc32_result[0],~tx_crc32_result[1],~tx_crc32_result[2],~tx_crc32_result[3],~tx_crc32_result[4],~tx_crc32_result[5],~tx_crc32_result[6],~tx_crc32_result[7]};
        2'd1: tx_axis_rgmii_tdata_ff <= {~tx_crc32_result[8],~tx_crc32_result[9],~tx_crc32_result[10],~tx_crc32_result[11],~tx_crc32_result[12],~tx_crc32_result[13],~tx_crc32_result[14],~tx_crc32_result[15]};
        2'd2: tx_axis_rgmii_tdata_ff <= {~tx_crc32_result[16],~tx_crc32_result[17],~tx_crc32_result[18],~tx_crc32_result[19],~tx_crc32_result[20],~tx_crc32_result[21],~tx_crc32_result[22],~tx_crc32_result[23]};
        default: tx_axis_rgmii_tdata_ff <= {~tx_crc32_result[24],~tx_crc32_result[25],~tx_crc32_result[26],~tx_crc32_result[27],~tx_crc32_result[28],~tx_crc32_result[29],~tx_crc32_result[30],~tx_crc32_result[31]}; 
      endcase
    else if (tx_stuff_flag && tx_axis_rgmii_tready) // 发送填充字节
      tx_axis_rgmii_tdata_ff <= 8'h00;
    else if (tx_axis_rgmii_tvalid && tx_axis_rgmii_tready) // 发送前导码+SFD+数据
      case (tx_byte_cnt)
        12'd0,12'd1,12'd2,12'd3,12'd4,12'd5: tx_axis_rgmii_tdata_ff <= 8'h55;
        12'd6: tx_axis_rgmii_tdata_ff <= 8'hD5;
        default: tx_axis_rgmii_tdata_ff <= tx_axis_mac_tdata;
      endcase
  always @ (posedge tx_mac_aclk)
    if (tx_mac_reset)
      tx_axis_rgmii_tvalid_ff <= 1'b0;
    else if (tx_ifg_flag)
      tx_axis_rgmii_tvalid_ff <= 1'b0;
    else if (tx_fcs_flag)
      tx_axis_rgmii_tvalid_ff <= 1'b1;
    else if ((tx_byte_cnt < 12'd71) && tx_stuff_flag && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_axis_rgmii_tvalid_ff <= 1'b1;
    else (tx_data_flag)
      tx_axis_rgmii_tvalid_ff <= tx_axis_mac_tvalid;
    else if (tx_axis_rgmii_tvalid_ff && tx_axis_rgmii_tvalid && tx_axis_rgmii_tready)
      tx_axis_rgmii_tvalid_ff <= 1'b0;


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
  assign tx_crc32_reset = (tx_ifg_flag | tx_mac_reset);
  assign tx_crc32_din = tx_stuff_flag ? 8'h00 : tx_axis_mac_tdata;
  assign tx_crc32_enable = (tx_axis_mac_tvalid && tx_axis_mac_tready) || (tx_axis_rgmii_tready && tx_stuff_flag && (tx_byte_cnt < 12'd67));
  crc32 eth_tx_crc32(
    .clk         (tx_mac_aclk),
    .reset       (tx_crc32_reset),
    .din         (tx_crc32_din),
    .enable      (tx_crc32_enable),
    .crc32       (tx_crc32_result),
    .crc32_next  ()
  );
// 跨时钟域处理
  xpm_cdc_array_single #(
    .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0),  // DECIMAL; 0=do not register input, 1=register input
    .WIDTH(2)           // DECIMAL; range: 1-1024
  )inband_clock_speed_txclk_sync(
    .dest_out(inband_clock_speed_txclk), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
                          // output is registered.

    .dest_clk(tx_mac_aclk), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(1'b0),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(inband_clock_speed)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
                          // domain. It is assumed that each bit of the array is unrelated to the others. This
                          // is reflected in the constraints applied to this macro. To transfer a binary value
                          // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
  );
  endmodule