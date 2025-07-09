// SENT 参数配置模块, 解析参数并分发至相应通道
//   word 0: bit[ 7: 0] 通道索引
//           bit[31: 8] 保留
//   word 1: bit[31:24] Tick长度, 支持3~90us, 单位 us
//           bit[23:16] 低脉冲 Tick 个数, 至少 4 Ticks
//           bit[15: 8] Pause Mode
//              0x0: 不选用Pause
//              0x1: 固定长度Pause
//              0x2: 自适应长度Pause
//           bit[ 7: 0] 暂停脉冲长度[15:8]
//   word 2: bit[31:24] 暂停脉冲长度[7:0], 12~768Ticks. 当 Pause Mode 为 0x2 时, 按照(270[最大SENT帧长]+Pause Length)Ticks自适应调整
//           bit[23:16] CRC Mode
//              0x0: Legacy Mode
//              0x1: Recommend Mode
//           bit[11: 8] 状态和通信nibble
//           bit[ 7: 0] 数据长度, 支持1~6 Nibbles, 单位 Nibble
//   word 3: bit[31: 8] 发送数据内容, 数据组成{nibble1, nibble2, ..., nibble6}

module sent_config #(
  parameter     ID_SENT_PARAM = 2, // SENT参数帧ID
  parameter     CLK_FREQ = 100000000 // 模块时钟频率, Unit: Hz
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  input  [7:0]  rx_axis_udp_tuser, // 帧ID
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
  reg          rx_axis_udp_tuser_d1 = 0;
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

// 接收word计数器
  always @ (posedge clk)
    if (rst)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d1 && rx_axis_udp_tlast_d1)
      word_cnt <= 0;
    else if (rx_axis_udp_tvalid_d1)
      word_cnt <= word_cnt + 1; 
// 帧识别
  always @(posedge clk or posedge rst)
    if (rst)
      pwm_param_en <= 1'b0;
    else if (rx_axis_udp_tuser == ID_PWM_PARAM[7:0])
      pwm_param_en <= 1'b1;
    else
      pwm_param_en <= 1'b0;
// 参数解析
  // 通道索引
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 0) && rx_axis_udp_tvalid_d1) pwm_config_channel_ff <= rx_axis_udp_tdata_d1[7:0];
  // PWM输出频率
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d1) pwm_frequency <= rx_axis_udp_tdata_d1[27:0];
  // PWM输出占空比
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d1) pwm_duty <= rx_axis_udp_tdata_d1[6:0];
  // PWM输出使能
    always @ (posedge clk) if (pwm_param_en && (word_cnt == 4) && rx_axis_udp_tvalid_d1) pwm_en_ff <= rx_axis_udp_tdata_d1[0];
// 计算计数时间
  // 计算周期计数阈值使能
    always @ (posedge clk)
      if (pwm_param_en && rx_axis_udp_tvalid_d1 && rx_axis_udp_tlast_d1)
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