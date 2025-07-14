// LIN 接口接收模块, 支持停止位错误检测

module lin_rx (
  input         clk,
  input         rst,
  // LIN收发物理接口
  input         lin_rx_rtl,
  // 控制信号
  input         sample_point, // 采样bit标志
  // 接收数据
  output        rx_data_vld, // 接收数据有效信号
  output [7:0]  rx_data, // 接收数据
  output        rx_data_err // 接收数据错误信号(停止位错误)
);
//------------------------------------
//             Local Signal
//------------------------------------
  reg  [3:0]   rx_bit_cnt = 0; // 接收bit计数器
  reg  [8:0]   rx_data_srl = 0; // 接收数据移位寄存器
  reg          rx_data_vld_ff = 0; // 接收数据有效信号
  reg          rx_data_err_ff = 0; // 接收数据错误信号(停止位错误)  
//------------------------------------
//             User Logic
//------------------------------------
// 接收bit计数器
  always @ (posedge clk or posedge rst)
    if (rst)
      rx_bit_cnt <= 4'd0;
    else if (sample_point && rx_bit_cnt < 10)
      rx_bit_cnt <= rx_bit_cnt + 1;
// 接收数据移位寄存器
  always @ (posedge clk) if (sample_point) rx_data_srl <= {lin_rx_rtl, rx_data_srl[8:1]};
// 接收数据有效信号
  always @ (posedge clk or posedge rst)
    if (rst)
      rx_data_vld_ff <= 0;
    else if (sample_point && rx_bit_cnt == 9)
      rx_data_vld_ff <= 1;
    else
      rx_data_vld_ff <= 0;
// 接收数据错误信号(停止位错误)
  always @ (posedge clk or posedge rst)
    if (rst)
      rx_data_err_ff <= 0;
    else if (sample_point && (rx_bit_cnt == 9) && (!lin_rx_rtl))
      rx_data_err_ff <= 1;
    else
      rx_data_err_ff <= 0;

//------------------------------------
//             Output Port
//------------------------------------
  assign rx_data_vld = rx_data_vld_ff;
  assign rx_data     = rx_data_srl[7:0];
  assign rx_data_err = rx_data_err_ff;
endmodule