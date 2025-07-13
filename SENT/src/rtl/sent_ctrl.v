// SENT 帧生成模块, 默认输出为高电平

module sent_ctrl #(
  parameter CHANNEL_INDEX = 0, // 通道索引
  parameter CLK_FREQ = 100000000 // 
)(
  input         clk,
  input         rst,
  input         sent_config_vld, // 参数配置使能
  input  [7:0]  sent_config_channel, // 通道索引
  input  [7:0]  sent_ctick_len, // Tick长度, 支持3~90us, 单位 us
  input  [7:0]  sent_ltick_len, // 低脉冲 Tick 个数, 至少 4 Ticks
  input  [1:0]  sent_pause_mode, // Pause Mode
  input  [15:0] sent_pause_len, // 暂停脉冲长度, 12~768Ticks
  input         sent_crc_mode, // CRC Mode
  input         sent_frame_vld, // 待发送帧有效指示, 高有效
  input  [31:0] sent_frame_data, // 待发送帧数据信息
                                 // bit[30:28] 数据长度, 支持1~6 Nibbles, 单位 Nibble
                                 // bit[27:24] 状态和通信nibble
                                 // bit[23:20] 数据nibble1
                                 // bit[19:16] 数据nibble2
                                 // bit[15:12] 数据nibble3
                                 // bit[11: 8] 数据nibble4
                                 // bit[ 7: 4] 数据nibble5
                                 // bit[ 3: 0] 数据nibble6
  output        sent_ready, // SENT 准备好标志, 置位时才可以改变参数
  output        sent_fifo_pfull, // SENT FIFO满标志, 置位时不能在下发数据
  output        sent // SENT输出
);
//------------------------------------
//             Local Parameter
//------------------------------------
  localparam FIFO_DEPTH = 64; // FIFO深度
  localparam FIFO_PFULL_THESHOLD = FIFO_DEPTH-18; // 预留18帧的数据空间
  localparam FIFO_WIDTH = 32; // FIFO宽度
  localparam FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1; // log2(FIFO_DEPTH)+1
  localparam TIME_1US = (CLK_FREQ/1000000)-1; // 1US 对应计数器值
//------------------------------------
//             Local Signal
//------------------------------------
// 参数配置使能寄存
  reg         sent_config_vld_reg = 0;
// 本地参数更新
  reg  [7:0]  sent_ctick_len_local = 3; // Tick长度, 支持3~90us, 单位 us
  reg  [7:0]  sent_ltick_len_local = 4; // 低脉冲 Tick 个数, 至少 4 Ticks
  reg  [1:0]  sent_pause_mode_local = 0; // Pause Mode
  reg  [15:0] sent_pause_len_local = 12; // 暂停脉冲长度, 12~768Ticks
  reg         sent_crc_mode_local = 0; // CRC Mode
// 其他信号
  reg  [10:0] sent_frame_ticks = 0; // 最大帧Ticks长度, sent_pause_mode = 2 时使用
  reg  [7:0]  tcnt_1us = 0; // 1us计数器
  wire        tcnt_1us_flag; // 1us计数器标志
  reg  [7:0]  tcnt_1tick = 0; // 1tick计数器
  wire        tcnt_1tick_flag; // 1tick计数器标志
  reg  [10:0] frame_tick_cnt = 0; // 1 frame Tick计数器, sent_pause_mode = 2 时使用
  reg  [9:0]  nibble_tick_cnt = 0; // 1 nibble Tick计数器
  reg         sync_en = 0; // 发送同步脉冲使能
  reg         sync_en_d1 = 0;
  reg         data_en = 0; // 发送数据nibble使能
  reg         crc_en = 0; // 发送CRC使能
  reg         pause_en = 0; // 发送暂停脉冲使能
  reg         pause_en_d1 = 0;
  wire        sent_busy; // SENT忙标志
  reg  [9:0]  nibble_tick = 0; // 当前 nibble 对应 Tick 数
  reg  [2:0]  nibble_cnt = 0; // 发送 nibble 计数器
  reg  [2:0]  sent_frame_len_reg = 0; // 发送帧长度寄存器
  reg  [27:0] sent_frame_data_srl = 0; // 发送帧数据移位寄存器
  reg         sent_crc_req = 0; // CRC校验请求, 高有效
  wire        sent_crc_ack; // CRC校验完成标志, 高有效
  wire [3:0]  sent_crc; // CRC校验结果
  reg  [3:0]  sent_frame_crc = 0; // 发送帧CRC寄存器
// FIFO信号
  reg                   sent_fifo_wren = 0;
  reg  [FIFO_WIDTH-1:0] sent_fifo_din = 0;
  wire                  sent_fifo_empty_temp;
  wire                  sent_fifo_rden;
  wire [FIFO_WIDTH-1:0] sent_fifo_dout;
  wire                  sent_fifo_pfull_temp;
// PWM输出寄存器
  reg         sent_ready_ff = 1;
  reg         sent_fifo_pfull_ff  = 0;
  reg         sent_ff = 1;
//------------------------------------
//             User Logic
//------------------------------------
// 参数配置使能寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_config_vld_reg <= 0;
    else if (sent_config_vld && (sent_config_channel == CHANNEL_INDEX[7:0]))
      sent_config_vld_reg <= 1;
    else if (!sent_busy && sent_fifo_empty_temp)
      sent_config_vld_reg <= 0;
// 更新 本地参数
  always @ (posedge clk or posedge rst)
    if (rst)
      begin
        sent_ctick_len_local  <= 8'd3;
        sent_ltick_len_local  <= 8'd4;
        sent_pause_mode_local <= 2'd0;
        sent_pause_len_local  <= 16'd0;
        sent_crc_mode_local   <= 1'b0;
      end
    else if (sent_config_vld_reg && (!sent_busy) && sent_fifo_empty_temp)
      begin
        sent_ctick_len_local  <= sent_ctick_len;
        sent_ltick_len_local  <= sent_ltick_len;
        sent_pause_mode_local <= sent_pause_mode;
        sent_pause_len_local  <= sent_pause_len;
        sent_crc_mode_local   <= sent_crc_mode;
      end
  // 最大帧Ticks长度, sent_pause_mode = 2 时使用
    always @ (posedge clk) if (sent_pause_mode_local == 2'd2) sent_frame_ticks <= (sent_pause_len_local[10:0] + 11'd269);
// 计数器
  // 1us计数器
    always @ (posedge clk or posedge rst)
      if (rst)
        tcnt_1us <= 8'd0;
      else if (sent_ready_ff || tcnt_1us == TIME_1US)
        tcnt_1us <= 8'd0;
      else
        tcnt_1us <= tcnt_1us + 8'd1;
    assign tcnt_1us_flag = (tcnt_1us == TIME_1US);
  // 1tick计数器
    always @ (posedge clk or posedge rst)
      if (rst)
        tcnt_1tick <= 8'd0;
      else if (!sent_busy && sent_fifo_empty_temp)
        tcnt_1tick <= 8'd0;
      else if (tcnt_1us_flag)
        begin
          if (tcnt_1tick == (sent_ctick_len_local-1))
            tcnt_1tick <= 8'd0;
          else
            tcnt_1tick <= tcnt_1tick + 8'd1;
        end
    assign tcnt_1tick_flag = (tcnt_1us_flag && tcnt_1tick == (sent_ctick_len_local-1));
  // 1 frame Tick计数器, sent_pause_mode_local = 2 时有效
    always @ (posedge clk or posedge rst)
      if (rst)
        frame_tick_cnt <= 11'd0;
      else if (!sent_busy && sent_fifo_empty_temp)
        frame_tick_cnt <= 11'd0;
      else if (tcnt_1tick_flag)
        begin
          if (frame_tick_cnt == sent_frame_ticks)
            frame_tick_cnt <= 11'd0;
          else
            frame_tick_cnt <= frame_tick_cnt + 11'd1;
        end
  // 1 nibble Tick计数器
    always @ (posedge clk or posedge rst)
      if (rst)
        nibble_tick_cnt <= 10'd0;
      else if (!sent_busy && sent_fifo_empty_temp)
        nibble_tick_cnt <= 10'd0;
      else if (tcnt_1tick_flag)
        begin
          if ((nibble_tick_cnt == nibble_tick) || (sent_pause_mode_local[1] && (frame_tick_cnt == sent_frame_ticks)))
            nibble_tick_cnt <= 10'd0;
          else
            nibble_tick_cnt <= nibble_tick_cnt + 10'd1;
        end
  // 发送 nibble 计数器
    always @ (posedge clk or posedge rst)
      if (rst)
        nibble_cnt <= 3'd0;
      else if (!data_en)
        nibble_cnt <= 3'd0;
      else if (tcnt_1tick_flag && (nibble_tick_cnt == nibble_tick))
        nibble_cnt <= nibble_cnt + 3'd1;
// 发送同步脉冲使能
  always @ (posedge clk or posedge rst)
    if (rst)
      sync_en <= 1'b0;
    else if (sync_en && tcnt_1tick_flag && (nibble_tick_cnt == 10'd55))
      sync_en <= 1'b0;
    else if (!sent_fifo_empty_temp && ((!sent_busy) || 
      ((pause_en && tcnt_1tick_flag && ((!sent_pause_mode_local[1] && (nibble_tick_cnt == nibble_tick)) || (sent_pause_mode_local[1] && (frame_tick_cnt == sent_frame_ticks)))))))
      sync_en <= 1'b1;
  always @ (posedge clk) sync_en_d1 <= sync_en;
// 发送数据使能
  always @ (posedge clk or posedge rst)
    if (rst)
      data_en <= 1'b0;
    else if (tcnt_1tick_flag && (nibble_tick_cnt == nibble_tick) && (nibble_cnt == sent_frame_len_reg))
      data_en <= 1'b0;
    else if (sync_en && tcnt_1tick_flag && (nibble_tick_cnt == 10'd55))
      data_en <= 1'b1;
// 发送CRC使能
  always @ (posedge clk or posedge rst)
    if (rst)
      crc_en <= 1'b0;
    else if (data_en && tcnt_1tick_flag && (nibble_tick_cnt == nibble_tick) && (nibble_cnt == sent_frame_len_reg))
      crc_en <= 1'b1;
    else if (tcnt_1tick_flag && (nibble_tick_cnt == nibble_tick))
      crc_en <= 1'b0;
// 发送暂停脉冲使能
  always @ (posedge clk or posedge rst)
    if (rst)
      pause_en <= 1'b0;
    else if (crc_en && tcnt_1tick_flag && (nibble_tick_cnt == nibble_tick))
      pause_en <= 1'b1;
    else if (tcnt_1tick_flag && ((!sent_pause_mode_local[1] && (nibble_tick_cnt == nibble_tick)) || (sent_pause_mode_local[1] && (frame_tick_cnt == sent_frame_ticks))))
      pause_en <= 1'b0;
  always @ (posedge clk) pause_en_d1 <= pause_en;
// SENT忙标志
  assign sent_busy = (sync_en | data_en | crc_en | pause_en);
// 发送帧长度寄存器
  always @ (posedge clk) sent_frame_len_reg <= sent_fifo_dout[30:28];
// 发送帧数据移位寄存器
  always @ (posedge clk)
    if (sync_en)
      sent_frame_data_srl <= sent_fifo_dout[27:0];
    else if (data_en && tcnt_1tick_flag && (nibble_tick == nibble_tick_cnt))
      sent_frame_data_srl <= sent_frame_data_srl << 4;
// CRC校验请求, 高有效
  always @ (posedge clk) sent_crc_req <= (!sync_en_d1 && sync_en);
// 发送帧CRC寄存器
  always @ (posedge clk) if (sent_crc_ack) sent_frame_crc <= sent_crc;
// 当前 nibble 对应 Tick 数
  always @ (posedge clk)
    case ({sync_en,data_en,crc_en,pause_en})
      4'b1000: nibble_tick <= 10'd55;
      4'b0100: nibble_tick <= {6'b0,sent_frame_data_srl[27:24]} + 10'd11;
      4'b0010: nibble_tick <= {6'b0,sent_frame_crc[3:0]} + 10'd11;
      4'b0001: 
        begin
          case(sent_pause_mode_local)
            2'd1: nibble_tick <= (sent_pause_len_local[9:0]-1);
            2'd2: nibble_tick <= 10'd1023;
            default: nibble_tick <= 10'd11;
          endcase
        end
      default: nibble_tick <= 10'd11;
    endcase
// sent_data_fifo
  always @ (posedge clk)
    if (sent_frame_vld && (sent_config_channel == CHANNEL_INDEX[7:0]))
      sent_fifo_wren <= 1'b1;
    else
      sent_fifo_wren <= 1'b0;
  always @ (posedge clk) sent_fifo_din <= sent_frame_data;
  assign sent_fifo_rden = (!pause_en_d1 && pause_en);

// 输出寄存器
  always @ (posedge clk) sent_ready_ff <= (!sent_busy && sent_fifo_empty_temp);
  always @ (posedge clk) sent_fifo_pfull_ff <= sent_fifo_pfull_temp;
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_ff <= 1'b1;
    else if (sent_busy && (nibble_tick_cnt < sent_ltick_len_local))
      sent_ff <= 1'b0;
    else
      sent_ff <= 1'b1;
//------------------------------------
//             Output Port
//------------------------------------
  assign sent_ready = sent_ready_ff;
  assign sent_fifo_pfull = sent_fifo_pfull_ff;
  assign sent = sent_ff;
//------------------------------------
//             Instance
//------------------------------------
// SENT CRC计算模块
  sent_crc u_sent_crc(
    .clk             (clk),
    .rst             (rst),
    .sent_crc_mode   (sent_crc_mode_local), // CRC Mode
    .sent_crc_req    (sent_crc_req), // CRC校验请求, 高有效
    .sent_frame_len  (sent_fifo_dout[30:28]), // 待发送帧nibble长度
    .sent_frame_data (sent_fifo_dout[23:0]), // 待发送帧数据信息
    .sent_crc_ack    (sent_crc_ack), // CRC校验完成标志, 高有效
    .sent_crc        (sent_crc) // CRC校验结果
  );
// xpm_fifo_sync: Synchronous FIFO
// Xilinx Parameterized Macro, version 2020.1
  xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(0),     // DECIMAL
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),   // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(FIFO_PFULL_THESHOLD),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),   // DECIMAL
    .READ_DATA_WIDTH(FIFO_WIDTH),      // DECIMAL
    .READ_MODE("fwft"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("0707"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(FIFO_WIDTH),     // DECIMAL
    .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH)    // DECIMAL
  ) sent_data_fifo (
    .almost_empty(),   // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                    // only one more read can be performed before the FIFO goes to empty.

    .almost_full(),     // 1-bit output: Almost Full: When asserted, this signal indicates that
                                    // only one more write can be performed before the FIFO is full.

    .data_valid(),       // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                    // that valid data is available on the output bus (dout).

    .dbiterr(),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                    // a double-bit error and data in the FIFO core is corrupted.

    .dout(sent_fifo_dout),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                    // when reading the FIFO.

    .empty(sent_fifo_empty_temp),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                    // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                    // initiating a read while empty is not destructive to the FIFO.

    .full(),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                    // FIFO is full. Write requests are ignored when the FIFO is full,
                                    // initiating a write when the FIFO is full is not destructive to the
                                    // contents of the FIFO.

    .overflow(),           // 1-bit output: Overflow: This signal indicates that a write request
                                    // (wren) during the prior clock cycle was rejected, because the FIFO is
                                    // full. Overflowing the FIFO is not destructive to the contents of the
                                    // FIFO.

    .prog_empty(),       // 1-bit output: Programmable Empty: This signal is asserted when the
                                    // number of words in the FIFO is less than or equal to the programmable
                                    // empty threshold value. It is de-asserted when the number of words in
                                    // the FIFO exceeds the programmable empty threshold value.

    .prog_full(sent_fifo_pfull_temp),         // 1-bit output: Programmable Full: This signal is asserted when the
                                    // number of words in the FIFO is greater than or equal to the
                                    // programmable full threshold value. It is de-asserted when the number of
                                    // words in the FIFO is less than the programmable full threshold value.

    .rd_data_count(), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                    // number of words read from the FIFO.

    .rd_rst_busy(),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                    // domain is currently in a reset state.

    .sbiterr(),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                    // and fixed a single-bit error.

    .underflow(),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                    // the previous clock cycle was rejected because the FIFO is empty. Under
                                    // flowing the FIFO is not destructive to the FIFO.

    .wr_ack(),               // 1-bit output: Write Acknowledge: This signal indicates that a write
                                    // request (wr_en) during the prior clock cycle is succeeded.

    .wr_data_count(), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                    // the number of words written into the FIFO.

    .wr_rst_busy(),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                    // write domain is currently in a reset state.

    .din(sent_fifo_din),                     // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                    // writing the FIFO.

    .injectdbiterr(), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                    // the ECC feature is used on block RAMs or UltraRAM macros.

    .injectsbiterr(), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                    // the ECC feature is used on block RAMs or UltraRAM macros.

    .rd_en(sent_fifo_rden),                 // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                    // signal causes data (on dout) to be read from the FIFO. Must be held
                                    // active-low when rd_rst_busy is active high.

    .rst(rst),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                    // unstable at the time of applying reset, but reset must be released only
                                    // after the clock(s) is/are stable.

    .sleep(1'b0),                 // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                    // block is in power saving mode.

    .wr_clk(clk),               // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                    // free running clock.

    .wr_en(sent_fifo_wren)                  // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                    // signal causes data (on din) to be written to the FIFO Must be held
                                    // active-low when rst or wr_rst_busy or rd_rst_busy is active high
  );
endmodule