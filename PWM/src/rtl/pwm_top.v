// PWM 控制器顶层模块, 支持通道数配置, PWM默认输出低电平, 只有在单周期结束才会更新PWM参数
// PWM输出频率大于等于1Hz, PWM输出占空比0-100%

module pwm_top #(
  parameter     PWM_NUM = 1, // PWM通道数
  parameter     ID_PWM_PARAM = 0, // PWM参数帧ID
  parameter     CLK_FREQ = 100000000 // 模块时钟频率, Unit: Hz
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  // PWM输出
  output [PWM_NUM-1:0] pwm
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire        pwm_config_vld; // 参数配置使能
  wire [7:0]  pwm_config_channel; // 通道索引
  wire        pwm_en; // PWM输出使能
  wire [27:0] pwm_period; // 周期计数阈值
  wire [27:0] pwm_hlevel; // 高电平计数阈值

//------------------------------------
//             Instance
//------------------------------------
// PWM 参数配置模块
  pwm_config #(
    .ID_PWM_PARAM       (ID_PWM_PARAM      ), // PWM参数帧ID
    .CLK_FREQ           (CLK_FREQ          )  // 模块时钟频率, Unit: Hz
  )u_pwm_config(
    // 模块时钟及复位
    .clk                (clk               ),
    .rst                (rst               ),
    // 用户UDP数据接收接口
    .rx_axis_udp_tdata  (rx_axis_udp_tdata ),
    .rx_axis_udp_tvalid (rx_axis_udp_tvalid),
    .rx_axis_udp_tlast  (rx_axis_udp_tlast ),
    //输出参数
    .pwm_config_vld     (pwm_config_vld    ), // 参数配置使能
    .pwm_config_channel (pwm_config_channel), // 通道索引
    .pwm_en             (pwm_en            ), // PWM输出使能
    .pwm_period         (pwm_period        ), // 周期计数阈值
    .pwm_hlevel         (pwm_hlevel        )  // 高电平计数阈值
  );
// PWM 控制器
  genvar pwm_ch;
  generate
    for (pwm_ch = 0; pwm_ch < PWM_NUM; pwm_ch = pwm_ch + 1)
      begin
        pwm_ctrl #(
            .CHANNEL_INDEX       (pwm_ch) // 通道索引
          )u_pwm_ctrl(
            .clk                 (clk               ),
            .rst                 (rst               ),
            .pwm_config_vld      (pwm_config_vld    ), // 参数配置使能
            .pwm_config_channel  (pwm_config_channel), // 通道索引
            .pwm_en              (pwm_en            ), // PWM输出使能
            .pwm_period          (pwm_period        ), // 周期计数阈值
            .pwm_hlevel          (pwm_hlevel        ), // 高电平计数阈值
            .pwm                 (pwm[pwm_ch]       )  // PWM输出
          );
      end
  endgenerate

endmodule