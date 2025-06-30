// PWM 参数配置模块, 解析参数并分发至相应通道
//   word 0: bit[ 7: 0] 通道索引
//           bit[31: 8] 保留
//   word 1: bit[31: 0] PWM输出频率, 单位Hz
//   word 2: bit[ 7: 0] PWM输出占空比, 0-100%
//           bit[31: 8] 保留
//   word 3: 保留
//   word 4: bit[ 0: 0] PWM输出使能
//           bit[31: 1] 保留

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
  input  [7:0]  rx_axis_udp_tuser, // 帧类型
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
  reg  [31:0]  rx_axis_udp_tdata_d1 = 0; // 打拍, 减小扇出
  reg          rx_axis_udp_tvalid_d1 = 0;
  reg          rx_axis_udp_tlast_d1 = 0;
  reg  [7:0]   rx_axis_udp_tuser_d1 = 0;
  reg  [7:0]   word_cnt = 0; // word计数器
  reg          pwm_param_en = 0; // PWM参数帧使能


//------------------------------------
//             User Logic
//------------------------------------
// 打拍, 减小扇出
  always @ (posedge clk) rx_axis_udp_tdata_d1 <= rx_axis_udp_tdata;
  always @ (posedge clk) rx_axis_udp_tvalid_d1 <= rx_axis_udp_tvalid;
  always @ (posedge clk) rx_axis_udp_tlast_d1 <= rx_axis_udp_tlast;
  always @ (posedge clk) rx_axis_udp_tuser_d1 <= rx_axis_udp_tuser;
// 接收word计数器
  always @ (posedge clk)
    if (rst)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d1 && rx_axis_udp_tlast_d1)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d1)
      word_cnt <= word_cnt + 1; 
// 解析参数
  always @(posedge clk or posedge rst)
    if (rst)
      pwm_param_en <= 1'b0;
    else if (rx_axis_udp_tuser_d1 == PWM_PARAM_TYPE[7:0])
      pwm_param_en <= 1'b1;
    else
      pwm_param_en <= 1'b0;
// 输出参数




//------------------------------------
//             Output Port
//------------------------------------
  assign pwm = pwm_ff;

//------------------------------------
//             Instance
//------------------------------------


  endmodule