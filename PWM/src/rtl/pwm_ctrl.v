// PWM 控制器, 默认输出为低电平, 只有在单周期结束才会更新PWM参数

module pwm_ctrl #(
  // 通道索引
  parameter CHANNEL_INDEX = 0
)(
  input        clk,
  input        rst,
  input        pwm_config_vld, // 参数配置使能
  input [7:0]  pwm_config_channel, // 通道索引
  input        pwm_en, // PWM输出使能
  input [27:0] pwm_period, // 单周期计数时间
  input [27:0] pwm_hlevel, // 高电平持续计数时间
  output       pwm // PWM输出
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [27:0] period_cnt = 0; // 周期计数器
  reg         pwm_config_vld_reg = 0; // 参数配置使能寄存器
  reg         pwm_en_reg = 0; // PWM输出使能-参数寄存
  reg  [27:0] pwm_period_reg = 0; // 周期计数阈值-参数寄存
  reg  [27:0] pwm_hlevel_reg = 0; // 高电平计数阈值-参数寄存
  reg         pwm_en_local = 0; // 本地PWM输出使能
  reg  [27:0] pwm_period_local = 0; // 本地周期计数阈值
  reg  [27:0] pwm_hlevel_local = 0; // 本地高电平计数阈值

  reg         pwm_ff = 0; // PWM输出寄存器

//------------------------------------
//             User Logic
//------------------------------------
// 参数寄存
  always @ (posedge clk or posedge rst)
    if (pwm_config_vld && (pwm_config_channel == CHANNEL_INDEX[7:0]))
      begin
        pwm_en_reg <= pwm_en;
        pwm_period_reg <= pwm_period;
        pwm_hlevel_reg <= pwm_hlevel;
      end
// 参数配置使能寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      pwm_config_vld_reg <= 0;
    else if (pwm_config_vld && (pwm_config_channel == CHANNEL_INDEX[7:0]))
      pwm_config_vld_reg <= 1;
    else if ((pwm_period_local == 0) || (period_cnt == pwm_period_local - 1))
      pwm_config_vld_reg <= 0;
// 更新 本地参数
  always @ (posedge clk or posedge rst)
    if (rst)
      begin
        pwm_en_local <= 0;
        pwm_period_local <= 0;
        pwm_hlevel_local <= 0;
      end
    else if (pwm_config_vld_reg && ((pwm_period_local == 0) || (period_cnt == pwm_period_local - 1)))
      begin
        pwm_en_local <= pwm_en_reg;
        pwm_period_local <= pwm_period_reg;
        pwm_hlevel_local <= pwm_hlevel_reg;
      end
// 周期计数器
  always @ (posedge clk or posedge rst)
    if (rst)
      period_cnt <= 0;
    else if ((pwm_period_local == 0) || (period_cnt == pwm_period_local - 1))
      period_cnt <= 0;
    else
      period_cnt <= period_cnt + 1;
// PWM输出寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      pwm_ff <= 0;
    else if ((!pwm_en_local) || ((pwm_hlevel_local == 0) && (pwm_period_local != 0)) || (period_cnt == (pwm_hlevel_local-1)))
      pwm_ff <= 0;
    else if ((pwm_period_local == 0) || (period_cnt == pwm_period_local - 1))
      pwm_ff <= 1;

//------------------------------------
//             Output Port
//------------------------------------
  assign pwm = pwm_ff;

endmodule