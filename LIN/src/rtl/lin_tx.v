// LIN 接口发送模块, 支持发送回读错误检测

module lin_tx (
  input         clk,
  input         rst,
  // LIN收发物理接口
  input         lin_rx_rtl, // 用于检测发送是否正确
  output        lin_tx_rtl, // 发送数据
  // 控制信号
  input         bypass, // 用于控制发送同步间隔段
  input         bypass_data,
  input         updata_point, // 更新bit标志
  // 发送数据
  input         tx_data_req, // 发送数据请求信号
  input  [7:0]  tx_data, // 发送数据
  output        tx_data_ack, // 发送数据应答信号
  output        tx_data_err // 发送数据错误信号
);
//------------------------------------
//             Local Signal
//------------------------------------
  reg  [3:0]   tx_bit_cnt = 0; // 发送bit计数器
  reg  [7:0]   tx_data_srl = 0; // 发送数据移位寄存器
  reg          tx_data_ack_ff = 0; // 发送数据应答信号
  reg          tx_data_err_ff = 0; // 发送数据错误信号
  reg          lin_tx_ff = 1; // 发送数据寄存器
  reg          lin_tx_reg = 1; // 寄存上一位发送数据, 用于回读错误检测
  reg          lin_rx_d1 = 1; // 接收数据寄存器
  
//------------------------------------
//             User Logic
//------------------------------------
// 发送bit计数器
  always @ (posedge clk or posedge rst)
    if (rst)
      tx_bit_cnt <= 4'd0;
    else if (tx_data_req)
      tx_bit_cnt <= 4'd0;
    else if (updata_point && tx_bit_cnt < 9)
      tx_bit_cnt <= tx_bit_cnt + 1;
// 发送数据移位寄存器
  always @ (posedge clk)
    if (tx_data_req)
      tx_data_srl <= tx_data;
    else if (updata_point)
      tx_data_srl <= {1'b1,tx_data_srl[7:1]};
// 发送数据应答信号
  always @ (posedge clk or posedge rst)
    if (rst)
      tx_data_ack_ff <= 0;
    else if (tx_data_req)
      tx_data_ack_ff <= 0;
    else if (updata_point && tx_bit_cnt == 9)
      tx_data_ack_ff <= 1;
// 发送数据错误信号
  always @ (posedge clk or posedge rst)
    if (rst)
      tx_data_err_ff <= 0;
    else if (updata_point && (lin_tx_reg ^ lin_rx_d1))
      tx_data_err_ff <= 1;
    else
      tx_data_err_ff <= 0;
// 发送数据寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      lin_tx_ff <= 1;
    else if (bypass)
      lin_tx_ff <= bypass_data;
    else if (tx_data_req)
      lin_tx_ff <= 0;
    else if (updata_point)
      lin_tx_ff <= tx_data_srl[0];
// 接收数据寄存器
  always @ (posedge clk) lin_rx_d1 <= lin_rx_rtl;
// 寄存上一位发送数据, 用于回读错误检测
  always @ (posedge clk) if (updata_point) lin_tx_reg <= lin_tx_ff;

//------------------------------------
//             Output Port
//------------------------------------
  assign lin_tx_rtl  = lin_tx_ff;
  assign tx_data_ack = tx_data_ack_ff;
  assign tx_data_err = tx_data_err_ff;
endmodule