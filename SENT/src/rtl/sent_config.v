// SENT 参数配置模块, 解析参数并分发至相应通道
//   word 0: bit[31:16] 帧ID. 0: 表示当前帧为PWM参数帧
//           bit[15: 8] 通道索引
//           bit[ 7: 0] 保留为0
//   word 1: bit[31:24] Tick长度, 支持3~90us, 单位 us
//           bit[23:16] 低脉冲 Tick 个数, 至少 4 Ticks
//           bit[ 9: 8] Pause Mode
//              0x0: No Pause
//              0x1: Fixed Pause
//              0x2: Variable Pause
//           bit[ 7: 0] 暂停脉冲长度[15:8]
//   word 2: bit[31:24] 暂停脉冲长度[7:0], 12~768Ticks. 当 Pause Mode 为 0x2 时, 按照(270[最大SENT帧长]+Pause Length)Ticks自适应调整
//           bit[16:16] CRC Mode
//              0x0: Legacy Mode
//              0x1: Recommend Mode
//           bit[11: 8] 状态和通信nibble
//           bit[ 2: 0] 数据长度, 支持1~6 Nibbles, 单位 Nibble
//   word 3: bit[31: 8] 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}

module sent_config #(
  parameter     ID_SENT_PARAM = 2 // SENT参数帧ID
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  //输出参数
  output        sent_config_vld, // 参数配置使能
  output [7:0]  sent_config_channel, // 通道索引
  output [7:0]  sent_ctick_len, // Tick长度, 支持3~90us, 单位 us
  output [7:0]  sent_ltick_len, // 低脉冲 Tick 个数, 至少 4 Ticks
  output [1:0]  sent_pause_mode, // Pause Mode
  output [15:0] sent_pause_len, // 暂停脉冲长度, 12~768Ticks
  output        sent_crc_mode, // CRC Mode
  output [3:0]  sent_status_nibble, // 状态和通信nibble
  output [2:0]  sent_data_len, // 数据长度, 支持1~6 Nibbles, 单位 Nibble
  output [23:0] sent_data_nibble // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [31:0]  rx_axis_udp_tdata_d1 = 0; // 打拍, 减小扇出
  reg          rx_axis_udp_tvalid_d1 = 0;
  reg          rx_axis_udp_tlast_d1 = 0;
  reg  [31:0]  rx_axis_udp_tdata_d2 = 0; // 打拍, 减小扇出
  reg          rx_axis_udp_tvalid_d2 = 0;
  reg          rx_axis_udp_tlast_d2 = 0;
  reg  [7:0]   word_cnt = 0; // word计数器
  reg          sent_param_en = 0; // SENT参数帧使能

// 输出寄存器
  reg          sent_config_vld_ff = 0; // 参数配置使能
  reg  [7:0]   sent_config_channel_ff = 0; // 通道索引
  reg  [7:0]   sent_ctick_len_ff = 0; // Tick长度, 支持3~90us, 单位 us
  reg  [7:0]   sent_ltick_len_ff = 0; // 低脉冲 Tick 个数, 至少 4 Ticks
  reg  [1:0]   sent_pause_mode_ff = 0; // Pause Mode
  reg  [15:0]  sent_pause_len_ff = 0; // 暂停脉冲长度, 12~768Ticks
  reg          sent_crc_mode_ff = 0; // CRC Mode
  reg  [3:0]   sent_status_nibble_ff = 0; // 状态和通信nibble
  reg  [2:0]   sent_data_len_ff = 0; // 数据长度, 支持1~6 Nibbles, 单位 Nibble
  reg  [23:0]  sent_data_nibble_ff = 0; // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
//------------------------------------
//             User Logic
//------------------------------------
// 打拍, 减小扇出
  always @ (posedge clk) rx_axis_udp_tdata_d1 <= rx_axis_udp_tdata;
  always @ (posedge clk) rx_axis_udp_tvalid_d1 <= rx_axis_udp_tvalid;
  always @ (posedge clk) rx_axis_udp_tlast_d1 <= rx_axis_udp_tlast;
  always @ (posedge clk) rx_axis_udp_tdata_d2 <= rx_axis_udp_tdata_d1;
  always @ (posedge clk) rx_axis_udp_tvalid_d2 <= rx_axis_udp_tvalid_d1;
  always @ (posedge clk) rx_axis_udp_tlast_d2 <= rx_axis_udp_tlast_d1;

// 接收word计数器
  always @ (posedge clk)
    if (rst)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d2)
      word_cnt <= word_cnt + 1; 
// 帧识别
  always @(posedge clk or posedge rst)
    if (rst)
      sent_param_en <= 1'b0;
    else if ((word_cnt == 0) && rx_axis_udp_tvalid_d1 && (rx_axis_udp_tdata_d1[23:16] == ID_SENT_PARAM[7:0]))
      sent_param_en <= 1'b1;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      sent_param_en <= 1'b0;
// 参数解析
  // 通道索引
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 0) && rx_axis_udp_tvalid_d2) sent_config_channel_ff <= rx_axis_udp_tdata_d2[15:8];
  // Tick长度
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) sent_ctick_len_ff <= rx_axis_udp_tdata_d2[31:24];
  // 低脉冲 Tick 个数
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) sent_ltick_len_ff <= rx_axis_udp_tdata_d2[23:16];
  // Pause Mode
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) sent_pause_mode_ff <= rx_axis_udp_tdata_d2[9:8];
  // 暂停脉冲长度
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) sent_pause_len_ff[15:8] <= rx_axis_udp_tdata_d2[7:0];
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) sent_pause_len_ff[7:0] <= rx_axis_udp_tdata_d2[31:24];
  // CRC Mode
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) sent_crc_mode_ff <= rx_axis_udp_tdata_d2[16];
  // 状态和通信nibble
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) sent_status_nibble_ff <= rx_axis_udp_tdata_d2[11:8];
  // 数据长度
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) sent_data_len_ff <= rx_axis_udp_tdata_d2[2:0];
  // 发送数据内容
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 3) && rx_axis_udp_tvalid_d2) sent_data_nibble_ff <= rx_axis_udp_tdata_d2[31:8];
// 参数配置使能
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_config_vld_ff <= 1'b0;
    else if (sent_param_en && rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      sent_config_vld_ff <= 1'b1;
    else
      sent_config_vld_ff <= 1'b0;

//------------------------------------
//             Output Port
//------------------------------------
  assign sent_config_vld = sent_config_vld_ff;
  assign sent_config_channel = sent_config_channel_ff;
  assign sent_ctick_len = sent_ctick_len_ff;
  assign sent_ltick_len = sent_ltick_len_ff;
  assign sent_pause_mode = sent_pause_mode_ff;
  assign sent_pause_len = sent_pause_len_ff;
  assign sent_crc_mode = sent_crc_mode_ff;
  assign sent_status_nibble = sent_status_nibble_ff;
  assign sent_data_len = sent_data_len_ff;
  assign sent_data_nibble = sent_data_nibble_ff;

endmodule