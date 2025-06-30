// PWM 参数配置模块, 解析参数并分发至相应通道

module pwm_config #(
  parameter   PWM_PARAM_TYPE = 0
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  input         rx_axis_udp_tuser, // 帧类型
  //输出参数
  output        pwm_config_vld, // 参数配置使能
  output [7:0]  pwm_config_channel, // 通道索引
  output        pwm_en, // PWM输出使能
  output [27:0] pwm_period, // 单周期计数时间
  output [27:0] pwm_hlevel // 高电平持续计数时间
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [7:0] word_cnt = 0; // word计数器



//------------------------------------
//             User Logic
//------------------------------------
// 接收word计数器







  always @ (posedge clk or posedge rst)
    if (pwm_config_vld && (pwm_config_channel == CHANNEL_INDEX[7:0]))
      begin
        pwm_en_reg <= pwm_en;
        pwm_period_reg <= pwm_period;
        pwm_hlevel_reg <= pwm_hlevel;
      end
  always @ (posedge clk or posedge rst)
    if (rst)
      pwm_config_vld_reg <= 0;
    else if (pwm_config_vld && (pwm_config_channel == CHANNEL_INDEX[7:0]))
      pwm_config_vld_reg <= 1;
    else if (period_cnt == pwm_period_local)
      pwm_config_vld_reg <= 0;
    if (rst)
      begin
        pwm_en_local <= 0;
        pwm_period_local <= 0;
        pwm_hlevel_local <= 0;
      end
    else if (pwm_config_vld_reg)
      begin
        pwm_en_local <= pwm_en_reg;
        pwm_period_local <= pwm_period_reg;
        pwm_hlevel_local <= pwm_hlevel_reg;
      end
    if (rst)
       <= 0;
    else
      period_cnt <= period_cnt + 1;
    if (rst)
      pwm_ff <= 0;
        else if (period_cnt < pwm_hlevel_local)
          pwm_ff <= 1;
//------------------------------------
//             Output Port
//------------------------------------
  assign pwm = pwm_ff;

//------------------------------------
//             Instance
//------------------------------------


  endmodule