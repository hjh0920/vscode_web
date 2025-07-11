`timescale 1ns/1ns


module tb_pwm;

//*************************** Parameters ***************************
  parameter  PERIOD_CLK = 10;
  parameter  PWM_NUM = 5; // PWM通道数
  parameter  ID_PWM_PARAM = 0; // PWM参数帧ID
  parameter  CLK_FREQ = 100000000; // 模块时钟频率, Unit: Hz
//***************************   Signals  ***************************
    // 模块时钟及复位
    reg        clk = 0;
    reg        rst = 1;
    // 用户UDP数据接收接口
    reg [31:0] rx_axis_udp_tdata = 0;
    reg        rx_axis_udp_tvalid = 0;
    reg        rx_axis_udp_tlast = 0;

//*************************** Test Logic ***************************
  always # (PERIOD_CLK/2) clk = ~clk;

  initial
    begin
      #100
      rst = 0;
      #1000;
        pwm_config(0, 100000, 100, 1); #10000;
        pwm_config(1, 100000, 80,  1); #10000;
        pwm_config(2, 100000, 50,  1); #10000;
        pwm_config(3, 100000, 20,  1); #10000;
        pwm_config(4, 100000, 0,   1); #10000;
        
        pwm_config(0, 55000, 100, 1); #100000
        pwm_config(1, 55000, 80,  1); #100000
        pwm_config(2, 55000, 50,  1); #100000
        pwm_config(3, 55000, 20,  1); #100000
        pwm_config(4, 55000, 0,   1); #100000
        
        pwm_config(0, 55000, 100, 0); #100000
        pwm_config(1, 55000, 80,  0); #100000
        pwm_config(2, 55000, 50,  0); #100000
        pwm_config(3, 55000, 20,  0); #100000
        pwm_config(4, 55000, 0,   0); #100000
      
      $stop;
    end
//***************************    Task    ***************************
  task pwm_config;
    input [7:0]  pwm_config_channel; // 通道索引
    input [31:0] pwm_frequency; // PWM输出频率
    input [7:0]  pwm_duty; // PWM输出占空比
    input        pwm_en; // PWM输出使能
    begin
      @(posedge clk);
        rx_axis_udp_tdata = {ID_PWM_PARAM[15:0], pwm_config_channel, 8'b0};
        rx_axis_udp_tvalid = 1;
        rx_axis_udp_tlast = 0;
      @(posedge clk);
        rx_axis_udp_tdata = pwm_frequency;
      @(posedge clk);
        rx_axis_udp_tdata = {pwm_duty,24'b0};
      @(posedge clk);
        rx_axis_udp_tdata = {7'b0, pwm_en, 24'b0};
        rx_axis_udp_tlast = 1;
      @(posedge clk);
        rx_axis_udp_tdata = 32'b0;
        rx_axis_udp_tvalid = 0;
        rx_axis_udp_tlast = 0;
    end
    endtask
//***************************  Instance  ***************************
  pwm_top #(
    .PWM_NUM     (PWM_NUM     ), // PWM通道数
    .ID_PWM_PARAM(ID_PWM_PARAM), // PWM参数帧ID
    .CLK_FREQ    (CLK_FREQ    )  // 模块时钟频率, Unit: Hz
  )u_pwm_top(
    // 模块时钟及复位
    .clk                (clk               ),
    .rst                (rst               ),
    // 用户UDP数据接收接口
    .rx_axis_udp_tdata  (rx_axis_udp_tdata ),
    .rx_axis_udp_tvalid (rx_axis_udp_tvalid),
    .rx_axis_udp_tlast  (rx_axis_udp_tlast ),
    // PWM输出
    .pwm()
  );

endmodule
