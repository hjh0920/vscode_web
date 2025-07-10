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
  input  [3:0]  sent_status_nibble, // 状态和通信nibble
  input  [2:0]  sent_data_len, // 数据长度, 支持1~6 Nibbles, 单位 Nibble
  input  [23:0] sent_data_nibble // 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}
  output        sent // SENT输出
);

//------------------------------------
//             Local Signal
//------------------------------------
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

endmodule