`timescale 1ns/1ns


module tb_pwm;

//*************************** Parameters ***************************
  parameter integer  PERIOD_TXCLK = 12;
  parameter integer  PERIOD_RXCLK = 12;
  parameter integer  PERIOD_USBCLK = 10;

//***************************   Signals  ***************************
  // 模块时钟
    reg                          tx_clk = 0; // 发送时钟
    reg                          rx_clk = 0; // 接收时钟

  // Test signals
    reg [FIFO_BUS_WIDTH*8-1:0]   index = 1;

//*************************** Test Logic ***************************
  always # (PERIOD_TXCLK/2) tx_clk = ~tx_clk;
  always # (PERIOD_RXCLK/2) rx_clk = ~rx_clk;
  always # (PERIOD_USBCLK/2) usb_clk = ~usb_clk;

  initial
    begin
      #100
      rst_glbl = 0;
      #1000;



      #10000;
      $stop;
    end
//***************************    Task    ***************************

//***************************  Instance  ***************************


endmodule
