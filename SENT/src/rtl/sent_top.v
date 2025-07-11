// SENT 帧生成顶层模块, 支持通道数配置, 默认输出为高电平

module sent_top #(
  parameter     SENT_NUM = 1, // SENT通道数
  parameter     ID_SENT_PARAM = 2, // SENT参数帧ID
  parameter     ID_SENT_DATA = 3, // SENT数据帧ID
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
  output [SENT_NUM-1:0] sent_fifo_empty, // SENT FIFO空标志
  output [SENT_NUM-1:0] sent_fifo_full, // SENT FIFO满标志
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
  wire        sent_frame_vld; // 待发送帧有效指示, 高有效
  wire [31:0] sent_frame_data; // 待发送帧数据信息

//------------------------------------
//             Instance
//------------------------------------
// SENT 参数配置模块
  sent_config #(
    .ID_SENT_PARAM      (ID_SENT_PARAM      ), // SENT参数帧ID
    .ID_SENT_DATA       (ID_SENT_DATA       )  // SENT数据帧ID
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
    .sent_frame_vld     (sent_frame_vld     ), // 待发送帧有效指示, 高有效
    .sent_frame_data    (sent_frame_data    )  // 待发送帧数据信息
  );
// SENT 帧生成模块
  genvar sent_ch;
  generate
    for (sent_ch = 0; sent_ch < SENT_NUM; sent_ch = sent_ch + 1)
      begin
        sent_ctrl #(
            .CHANNEL_INDEX  (sent_ch), // 通道索引
            .CLK_FREQ       (CLK_FREQ) // 模块时钟频率, Unit: Hz
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
            .sent_frame_vld      (sent_frame_vld     ), // 待发送帧有效指示, 高有效
            .sent_frame_data     (sent_frame_data    ), // 待发送帧数据信息
            .sent_fifo_empty     (sent_fifo_empty[sent_ch]), // SENT FIFO空标志
            .sent_fifo_full      (sent_fifo_full[sent_ch] ), // SENT FIFO满标志
            .sent                (sent[sent_ch]           )  // SENT输出
          );
      end
  endgenerate

endmodule