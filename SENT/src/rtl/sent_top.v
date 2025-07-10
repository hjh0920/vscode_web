// SENT 帧生成顶层模块, 支持通道数配置, 默认输出为高电平

module sent_top #(
  parameter     SENT_NUM = 1, // SENT通道数
  parameter     ID_SENT_PARAM = 2, // SENT参数帧ID
  parameter     CLK_FREQ = 100000000 // 模块时钟频率, Unit: Hz
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  // SENT输出
  output [SENT_NUM-1:0] sent
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire        sent_config_vld; // 参数配置使能
  wire [7:0]  sent_config_channel; // 通道索引
  wire [7:0]  sent_ctick_len; // Tick长度, 支持3~90us, 单位 us
  wire [7:0]  sent_ltick_len; // 低脉冲 Tick 个数, 至少 4 Ticks
  wire [1:0]  sent_pause_mode; // Pause Mode
  wire [15:0] sent_pause_len; // 暂停脉冲长度, 12~768Ticks
  wire        sent_crc_mode; // CRC Mode
  wire [3:0]  sent_status_nibble; // 状态和通信nibble
  wire [2:0]  sent_data_len; // 数据长度, 支持1~6 Nibbles, 单位 Nibble
  wire [23:0] sent_data_nibble; // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}

//------------------------------------
//             Instance
//------------------------------------
// SENT 参数配置模块
  sent_config #(
    .ID_SENT_PARAM      (ID_SENT_PARAM      ), // SENT参数帧ID
    .CLK_FREQ           (CLK_FREQ          )  // 模块时钟频率, Unit: Hz
  )u_sent_config(
    // 模块时钟及复位
    .clk                (clk               ),
    .rst                (rst               ),
    // 用户UDP数据接收接口
    .rx_axis_udp_tdata  (rx_axis_udp_tdata ),
    .rx_axis_udp_tvalid (rx_axis_udp_tvalid),
    .rx_axis_udp_tlast  (rx_axis_udp_tlast ),
    //输出参数
    .sent_config_vld    (sent_config_vld    ), // 参数配置使能
    .sent_config_channel(sent_config_channel), // 通道索引
    .sent_ctick_len     (sent_ctick_len     ), // Tick长度, 支持3~90us, 单位 us
    .sent_ltick_len     (sent_ltick_len     ), // 低脉冲 Tick 个数, 至少 4 Ticks
    .sent_pause_mode    (sent_pause_mode    ), // Pause Mode
    .sent_pause_len     (sent_pause_len     ), // 暂停脉冲长度, 12~768Ticks
    .sent_crc_mode      (sent_crc_mode      ), // CRC Mode
    .sent_status_nibble (sent_status_nibble ), // 状态和通信nibble
    .sent_data_len      (sent_data_len      ), // 数据长度, 支持1~6 Nibbles, 单位 Nibble
    .sent_data_nibble   (sent_data_nibble   )  // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
  );
// SENT 帧生成模块
  genvar sent_ch;
  generate
    for (sent_ch = 0; sent_ch < SENT_NUM; sent_ch = sent_ch + 1)
      begin
        sent_ctrl #(
            .CHANNEL_INDEX  (sent_ch), // 通道索引
            .CLK_FREQ       (CLK_FREQ), // 模块时钟频率, Unit: Hz
          )u_sent_ctrl(
            .clk                 (clk                ),
            .rst                 (rst                ),
            .sent_config_vld     (sent_config_vld    ), // 参数配置使能
            .sent_config_channel (sent_config_channel), // 通道索引
            .sent_ctick_len      (sent_ctick_len     ), // Tick长度, 支持3~90us, 单位 us
            .sent_ltick_len      (sent_ltick_len     ), // 低脉冲 Tick 个数, 至少 4 Ticks
            .sent_pause_mode     (sent_pause_mode    ), // Pause Mode
            .sent_pause_len      (sent_pause_len     ), // 暂停脉冲长度, 12~768Ticks
            .sent_crc_mode       (sent_crc_mode      ), // CRC Mode
            .sent_status_nibble  (sent_status_nibble ), // 状态和通信nibble
            .sent_data_len       (sent_data_len      ), // 数据长度, 支持1~6 Nibbles, 单位 Nibble
            .sent_data_nibble    (sent_data_nibble   ), // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
            .sent                (sent[sent_ch]      )  // SENT输出
          );
      end
  endgenerate

endmodule