// PWM 参数配置模块, 解析参数并分发至相应通道
//   word 0: bit[31:16] 帧ID. 0: 表示当前帧为PWM参数帧
//           bit[15: 8] 通道索引
//           bit[ 7: 0] 保留为0
//   word 1: bit[31: 0] PWM输出频率(>=1Hz), 单位Hz
//   word 2: bit[31:24] PWM输出占空比, 0-100%
//           bit[23: 0] 保留为0
//   word 3: bit[24:24] PWM输出使能, 高有效

module pwm_config #(
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
  //输出参数
  output        pwm_config_vld, // 参数配置使能
  output [7:0]  pwm_config_channel, // 通道索引
  output        pwm_en, // PWM输出使能
  output [27:0] pwm_period, // 周期计数阈值
  output [27:0] pwm_hlevel // 高电平计数阈值
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [31:0]  rx_axis_udp_tdata_d1 = 0; // 打拍, 减小扇出
  reg          rx_axis_udp_tvalid_d1 = 0;
  reg          rx_axis_udp_tlast_d1 = 0;
  reg  [31:0]  rx_axis_udp_tdata_d2 = 0; // 打拍, 减小扇出
  reg          rx_axis_udp_tvalid_d2 = 0;
  reg          rx_axis_udp_tlast_d2 = 0;
  reg  [7:0]   word_cnt = 0; // word计数器
  reg          pwm_param_en = 0; // PWM参数帧使能
  reg  [27:0]  pwm_frequency = 0; // PWM输出频率
  reg  [6:0]   pwm_duty = 0; // PWM输出占空比
  reg          cal_period_en = 0; // 计算周期计数阈值使能
  reg          cal_period_en_d1 = 0; // 延迟一拍
// 除法器 IP 信号
  reg          s_axis_divisor_tvalid = 0;
  reg  [31:0]  s_axis_divisor_tdata = 0;
  reg          s_axis_dividend_tvalid = 0;
  reg  [31:0]  s_axis_dividend_tdata = 0;
  wire         m_axis_dout_tvalid;
  wire [63:0]  m_axis_dout_tdata; // [63:32] quotient, [31:0] remainder
// 乘法器 IP 信号
  wire [6:0]   pwm_mul_a;
  wire [20:0]  pwm_mul_b;
  wire [27:0]  pwm_mul_p;
// 输出寄存器
  reg          pwm_config_vld_ff = 0; // 参数配置使能
  reg  [7:0]   pwm_config_channel_ff = 0; // 通道索引
  reg          pwm_en_ff = 0; // PWM输出使能
  reg  [27:0]  pwm_period_ff = 0; // 周期计数阈值
  reg  [27:0]  pwm_hlevel_ff = 0; // 高电平计数阈值
//------------------------------------
//             User Logic
//------------------------------------
// 打拍, 减小扇出
  always @ (posedge clk) rx_axis_udp_tdata_d1 <= rx_axis_udp_tdata;
  always @ (posedge clk) rx_axis_udp_tvalid_d1 <= rx_axis_udp_tvalid;
  always @ (posedge clk) rx_axis_udp_tlast_d1 <= rx_axis_udp_tlast;
  always @ (posedge clk) rx_axis_udp_tdata_d2 <= rx_axis_udp_tdata_d1;
  always @ (posedge clk) rx_axis_udp_tvalid_d2 <= rx_axis_udp_tvalid_d1;
  always @ (posedge clk) rx_axis_udp_tlast_d2 <= rx_axis_udp_tlast_d1;

// 接收word计数器
  always @ (posedge clk)
    if (rst)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d2)
      word_cnt <= word_cnt + 1; 
// 帧识别
  always @(posedge clk or posedge rst)
    if (rst)
      pwm_param_en <= 1'b0;
    else if ((word_cnt == 0) && rx_axis_udp_tvalid_d1 && (rx_axis_udp_tdata_d1[23:16] == ID_PWM_PARAM[7:0]))
      pwm_param_en <= 1'b1;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      pwm_param_en <= 1'b0;
// 参数解析
  // 通道索引
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 0) && rx_axis_udp_tvalid_d2) pwm_config_channel_ff <= rx_axis_udp_tdata_d2[15:8];
  // PWM输出频率
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) pwm_frequency <= rx_axis_udp_tdata_d2[27:0];
  // PWM输出占空比
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) pwm_duty <= rx_axis_udp_tdata_d2[30:24];
  // PWM输出使能
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 3) && rx_axis_udp_tvalid_d2) pwm_en_ff <= rx_axis_udp_tdata_d2[24];
// 计算计数时间
  // 计算周期计数阈值使能
    always @ (posedge clk)
      if (pwm_param_en && rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
        cal_period_en <= 1'b1;
      else if (m_axis_dout_tvalid)
        cal_period_en <= 1'b0;
    always @ (posedge clk) cal_period_en_d1 <= cal_period_en;
  // 除法器输入
    always @ (posedge clk)
      if ((!cal_period_en_d1) && cal_period_en) // 计算周期计数阈值
        begin
          s_axis_divisor_tvalid <= 1'b1;
          s_axis_divisor_tdata  <= {4'b0,pwm_frequency};
          s_axis_dividend_tvalid <= 1'b1;
          s_axis_dividend_tdata <= (CLK_FREQ[31:0] + {5'b0,pwm_frequency[27:1]}); // 四舍五入
        end
      else if (m_axis_dout_tvalid && cal_period_en) // 计算高电平计数阈值
        begin
          s_axis_divisor_tvalid <= 1'b1;
          s_axis_divisor_tdata  <= {4'b0,pwm_frequency};
          s_axis_dividend_tvalid <= 1'b1;
          s_axis_dividend_tdata <= ({4'b0,pwm_mul_p} + {5'b0,pwm_frequency[27:1]}); // 四舍五入
        end
      else
        begin
          s_axis_divisor_tvalid <= 1'b0;
          s_axis_dividend_tvalid <= 1'b0;
        end
  // 乘法器输入
    assign pwm_mul_a = pwm_duty;
    assign pwm_mul_b = (CLK_FREQ/100);
  // 周期计数阈值 赋值
    always @ (posedge clk or posedge rst)
      if (rst)
        pwm_period_ff <= 0;
      else if (cal_period_en && m_axis_dout_tvalid)
        pwm_period_ff <= m_axis_dout_tdata[32 +: 28];
  // 高电平计数阈值 赋值
    always @ (posedge clk or posedge rst)
      if (rst)
        pwm_hlevel_ff <= 0;
      else if ((!cal_period_en) && m_axis_dout_tvalid)
        begin
          if (pwm_duty == 0)
            pwm_hlevel_ff <= 0;
          else if (pwm_duty == 7'd100)
            pwm_hlevel_ff <= pwm_period_ff;
          else
            pwm_hlevel_ff <= m_axis_dout_tdata[32 +: 28];
        end
// 参数配置使能
  always @ (posedge clk or posedge rst)
    if (rst)
      pwm_config_vld_ff <= 1'b0;
    else if ((!cal_period_en) && m_axis_dout_tvalid)
      pwm_config_vld_ff <= 1'b1;
    else
      pwm_config_vld_ff <= 1'b0;

//------------------------------------
//             Output Port
//------------------------------------
  assign pwm_config_vld     = pwm_config_vld_ff;
  assign pwm_config_channel = pwm_config_channel_ff;
  assign pwm_en             = pwm_en_ff;
  assign pwm_period         = pwm_period_ff;
  assign pwm_hlevel         = pwm_hlevel_ff;

//------------------------------------
//             Instance
//------------------------------------
// Xilinx Divider Generate IP
  // Radix2, Unsigned 28bits / Unsigned 28bits, Remainder, Latency = 30 clocks
  div_gen_u28_u28 pwm_div(
    .aclk                  (clk),
    // 除数
    .s_axis_divisor_tvalid (s_axis_divisor_tvalid),
    .s_axis_divisor_tdata  (s_axis_divisor_tdata),
    // 被除数
    .s_axis_dividend_tvalid(s_axis_dividend_tvalid),
    .s_axis_dividend_tdata (s_axis_dividend_tdata),
    // 商+余数
    .m_axis_dout_tvalid    (m_axis_dout_tvalid),
    .m_axis_dout_tdata     (m_axis_dout_tdata)
  );
// Xilinx Multiplier IP
  mult_gen_u7_u21 pwm_mul(
    .CLK(clk),
    .A  (pwm_mul_a),
    .B  (pwm_mul_b),
    .P  (pwm_mul_p)
  );
  endmodule