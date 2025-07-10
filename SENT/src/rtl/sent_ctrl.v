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
  output        sent // SENT输出
);
//------------------------------------
//             Local Parameter
//------------------------------------
  localparam FIFO_DEPTH = 32; // FIFO深度
  localparam FIFO_WIDTH = 32; // FIFO宽度
  localparam FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1; // log2(FIFO_DEPTH)+1
//------------------------------------
//             Local Signal
//------------------------------------
// sent_data_fifo
  wire                  sent_fifo_wren;
  wire [FIFO_WIDTH-1:0] sent_fifo_din;
  wire                  sent_fifo_empty;
  wire                  sent_fifo_rden
  wire [FIFO_WIDTH-1:0] sent_fifo_dout;
  wire                  sent_fifo_full;



  reg  [27:0] period_cnt = 0; // 周期计数器
  reg         sent_config_vld_reg = 0; // 参数配置使能寄存器
  reg         sent_en_reg = 0; // PWM输出使能-参数寄存
  reg  [27:0] sent_period_reg = 0; // 周期计数阈值-参数寄存
  reg  [27:0] sent_hlevel_reg = 0; // 高电平计数阈值-参数寄存
  reg         sent_en_local = 0; // 本地PWM输出使能
  reg  [27:0] sent_period_local = 1; // 本地周期计数阈值
  reg  [27:0] sent_hlevel_local = 0; // 本地高电平计数阈值

  reg         sent_ff = 0; // PWM输出寄存器

//------------------------------------
//             User Logic
//------------------------------------
// 参数寄存
  always @ (posedge clk or posedge rst)
    if (sent_config_vld && (sent_config_channel == CHANNEL_INDEX[7:0]))
      begin
        sent_en_reg <= sent_en;
        sent_period_reg <= sent_period;
        sent_hlevel_reg <= sent_hlevel;
      end
// 参数配置使能寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_config_vld_reg <= 0;
    else if (sent_config_vld && (sent_config_channel == CHANNEL_INDEX[7:0]))
      sent_config_vld_reg <= 1;
    else if (period_cnt == sent_period_local - 1)
      sent_config_vld_reg <= 0;
// 更新 本地参数
  always @ (posedge clk or posedge rst)
    if (rst)
      begin
        sent_en_local <= 0;
        sent_period_local <= 1;
        sent_hlevel_local <= 0;
      end
    else if (sent_config_vld_reg && (period_cnt == sent_period_local - 1))
      begin
        sent_en_local <= sent_en_reg;
        sent_period_local <= sent_period_reg;
        sent_hlevel_local <= sent_hlevel_reg;
      end
// 周期计数器
  always @ (posedge clk or posedge rst)
    if (rst)
      period_cnt <= 0;
    else if (period_cnt == sent_period_local - 1)
      period_cnt <= 0;
    else
      period_cnt <= period_cnt + 1;
// PWM输出寄存器
  // 输出低电平条件:
    // 1. PWM输出使能为低电平
    // 2. 高电平持续计数时间等于0(即占空比为0)
    // 3. (高电平计数阈值 != 周期计数阈值) && 周期计数器等于高电平计数阈值-1
  // 输出高电平条件:
    // 1. PWM输出使能 && 占空比为100%(即单周期计数阈值=高电平持续计数时间)
    // 2. PWM输出使能 && 周期计数器等于周期计数阈值-1
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_ff <= 0;
    else if (((!sent_en_reg) && (period_cnt == sent_period_local - 1)) || (!sent_en_local) || (sent_hlevel_local == 0) || ((sent_hlevel_local != sent_period_local) && (period_cnt == (sent_hlevel_local-1))))
      sent_ff <= 0;
    else if ((sent_hlevel_local == sent_period_local) || (period_cnt == sent_period_local - 1))
      sent_ff <= 1;

//------------------------------------
//             Output Port
//------------------------------------
  assign pwm = sent_ff;
//------------------------------------
//             Instance
//------------------------------------
// xpm_fifo_sync: Synchronous FIFO
// Xilinx Parameterized Macro, version 2020.1
  xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),   // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),   // DECIMAL
    .READ_DATA_WIDTH(FIFO_WIDTH),      // DECIMAL
    .READ_MODE("std"),         // String
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

    .empty(sent_fifo_empty),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                    // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                    // initiating a read while empty is not destructive to the FIFO.

    .full(sent_fifo_full),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
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

    .prog_full(),         // 1-bit output: Programmable Full: This signal is asserted when the
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