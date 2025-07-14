// SENT CRC计算模块

module sent_crc (
  input         clk,
  input         rst,
  input         sent_crc_mode, // CRC Mode
  input         sent_crc_req, // CRC校验请求, 高有效
  input  [2:0]  sent_frame_len, // 待发送帧nibble长度
  input  [23:0] sent_frame_data, // 待发送帧数据信息
  output        sent_crc_ack, // CRC校验完成标志, 高有效
  output [3:0]  sent_crc // CRC校验结果
);
//------------------------------------
//             Local Signal
//------------------------------------
  reg         sent_crc_req_d1 = 0;
  reg  [2:0]  sent_frame_len_reg = 0; // 待发送帧nibble长度
  reg  [23:0] sent_frame_len_srl = 0; // 待发送帧数据信息
  reg  [3:0]  crc_cal_cnt = 0; // CRC计算计数器
  reg         crc4_rst = 1; // CRC4复位信号
  reg         crc4_enable = 0; // CRC4使能信号
  reg  [3:0]  crc4_din = 0; // CRC4输入
  wire [3:0]  crc4_dout; // CRC4输出
  reg         sent_crc_ack_ff = 0; // CRC校验完成标志, 高有效
  reg  [3:0]  sent_crc_ff = 0; // CRC校验结果
//------------------------------------
//             User Logic
//------------------------------------
  always @ (posedge clk) sent_crc_req_d1 <= sent_crc_req;
// 待发送帧nibble长度
  always @ (posedge clk) if (sent_crc_req) sent_frame_len_reg <= sent_frame_len;
// 待发送帧数据信息
  always @ (posedge clk)
    if (sent_crc_req)
      sent_frame_len_srl <= sent_frame_data;
    else
      sent_frame_len_srl <= sent_frame_len_srl << 4;
// CRC4复位信号
  always @ (posedge clk or posedge rst)
    if (rst)
      crc4_rst <= 1'b1;
    else if (sent_crc_req)
      crc4_rst <= 1'b1;
    else
      crc4_rst <= 1'b0;
// CRC计算使能信号
  always @ (posedge clk or posedge rst)
    if (rst)
      crc4_enable <= 1'b0;
    else if (sent_crc_req_d1)
      crc4_enable <= 1'b1;
    else if (sent_crc_ack_ff)
      crc4_enable <= 1'b0;
// CRC4输入
  always @ (posedge clk) crc4_din <= sent_frame_len_srl[23:20];
// CRC计算计数器
  always @ (posedge clk)
    if (sent_crc_req_d1)
      crc_cal_cnt <= 4'd0;
    else if (crc_cal_cnt < (sent_frame_len_reg + 1))
      crc_cal_cnt <= crc_cal_cnt + 1;
// CRC校验完成标志, 高有效
  always @ (posedge clk or posedge rst)
    if (rst)
      sent_crc_ack_ff <= 1'b0;
    else if (crc_cal_cnt == sent_frame_len_reg)
      sent_crc_ack_ff <= 1'b1;
    else
      sent_crc_ack_ff <= 1'b0;
// CRC校验结果
  always @ (posedge clk) sent_crc_ff <= crc4_dout;

//------------------------------------
//             Output Port
//------------------------------------
  assign sent_crc_ack = sent_crc_ack_ff;
  assign sent_crc = sent_crc_ff;
//------------------------------------
//             Instance
//------------------------------------
  crc4 u_crc4(
    .clk       (clk),
    .reset     (crc4_rst),
    .din       (crc4_din),
    .enable    (crc4_enable),
    .dout      (crc4_dout)
  );
endmodule