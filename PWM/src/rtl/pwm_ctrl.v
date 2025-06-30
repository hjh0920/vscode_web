// PWM 控制器, 默认输出为低电平, 周期更新

module pwm_ctrl (
  input        clk,
  input        rst,
  input        para_config_vld, // 参数配置使能
  input [27:0] period_limit, // 单周期计数时间
  input [27:0] high_limit, // 高电平持续计数时间
  output       pwm // PWM输出
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [27:0] period_cnt = 0; // 周期计数器
  reg         para_config_vld_reg = 0; // 参数配置使能寄存器
  reg  [27:0] period_limit_local = 0; // 本地周期计数阈值
  reg  [27:0] high_limit_local = 0; // 本地高电平计数阈值

  reg         pwm_ff = 0; // PWM输出寄存器

//------------------------------------
//             User Logic
//------------------------------------
// 周期计数器
  always @ (posedge clk or posedge rst)
    if (rst)
      period_cnt <= 0;
    else if (period_cnt == period_limit_local)
      period_cnt <= 0;
    else
      period_cnt <= period_cnt + 1;
// 参数配置使能寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      para_config_vld_reg <= 0;
    else if (para_config_vld)
      para_config_vld_reg <= 1;
    else if (period_cnt == period_limit_local)
      para_config_vld_reg <= 0;
// 更新 本地周期计数阈值
  always @ (posedge clk or posedge rst)
    if (rst)
      period_limit_local <= 0;
    else if (para_config_vld_reg)
      period_limit_local <= period_limit;
// 更新 本地高电平计数阈值
  always @ (posedge clk or posedge rst)
    if (rst)
      high_limit_local <= 0;
    else if (para_config_vld_reg)
      high_limit_local <= high_limit;
// PWM输出寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      pwm_ff <= 0;
    else if (period_cnt == period_limit_local)
      begin
        if (high_limit_local == 0)
          pwm_ff <= 0;
        else if (period_cnt < high_limit_local)
          pwm_ff <= 1;
      end

//------------------------------------
//             Output Port
//------------------------------------
  assign pwm = pwm_ff;

//------------------------------------
//             Instance
//------------------------------------


  endmodule