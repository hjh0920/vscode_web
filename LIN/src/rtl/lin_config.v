// LIN 参数配置模块, 解析参数并分发至相应通道
// ------------------ 0x5 参数帧 ------------------
//   word 0: bit[31:16] 帧ID. 0: 表示当前帧为PWM参数帧
//           bit[15: 8] 通道索引
//           bit[ 7: 0] 保留为0
//   word 1: bit[24:24] 工作模式
//              0x0: 从站模式
//              0x1: 主站模式
//           bit[ 9: 0] 波特率, 单位us, 默认20Kbps（对应50us）
//   word 2: bit[24:24] 校验类型
//              0x0: 标准型校验(只校验数据段)
//              0x1: 增强型校验(校验数据段和PID段)
//           bit[16:16] 内部终端电阻使能
//              0x0: 禁用
//              0x1: 使能
// ------------------ 0x6 数据帧 ------------------
//   word 0: bit[31:16] 帧ID. 0: 表示当前帧为PWM参数帧
//           bit[15: 8] 通道索引
//           bit[ 7: 0] 保留为0
//   word 1: Frame-0
//           bit[25:24] 操作类型
//              0b00: 主站模式下只发送帧头, 数据由从站响应;
//              0b01: 主站模式下发送帧头和数据;
//              0b10: 从站模式下添加响应帧;
//              0b11: 从站模式下删除响应帧
//           bit[21:16] 帧ID, 其中Bit[5:4]用于表示数据域长度（单位Byte）
//              0b00: 长度2Bytes;
//              0b01: 长度2Bytes;
//              0b10: 长度4Bytes;
//              0b11: 长度8Bytes
//   word 2: 帧数据内容1~4Bytes, LSB(低字节在前)
//   word 3: 帧数据内容5~8Bytes, LSB(低字节在前)

module lin_config #(
  parameter     ID_LIN_PARAM = 5, // LIN参数帧ID
  parameter     ID_LIN_DATA = 6 // LIN数据帧ID
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // 用户UDP数据接收接口
  input  [31:0] rx_axis_udp_tdata,
  input         rx_axis_udp_tvalid,
  input         rx_axis_udp_tlast,
  //输出参数
  output        lin_config_vld, // 参数配置使能, 高有效
  output [7:0]  lin_config_channel, // 通道索引
  output        lin_mode, // 工作模式
  output [9:0]  lin_baudrate, // 波特率, 单位us, 默认20Kbps（对应50us）
  output        lin_parity_type, // 校验类型
  output        lin_int_termin, // 内部终端电阻使能, 高有效
  output        lin_frame_vld, // 数据帧配置使能, 高有效
  output [1:0]  lin_op_type, // 操作类型
  output [5:0]  lin_frame_id, // 帧ID
  output [63:0] lin_frame_data // 帧数据
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
  reg  [2:0]   word_cnt = 0; // word计数器
  reg          lin_param_en = 0; // LIN参数帧使能
  reg          lin_data_en = 0; // LIN数据帧使能
// 输出寄存器
  reg          lin_config_vld_ff = 0; // 参数配置使能, 高有效
  reg  [7:0]   lin_config_channel_ff = 0; // 通道索引
  reg          lin_mode_ff = 0; // 工作模式
  reg  [8:0]   lin_baudrate_ff = 0; // 波特率, 单位us, 默认20Kbps（对应50us）
  reg          lin_parity_type_ff = 0; // 校验类型
  reg          lin_int_termin_ff = 0; // 内部终端电阻使能, 高有效
  reg          lin_frame_vld_ff = 0; // 数据帧配置使能, 高有效
  reg  [1:0]   lin_op_type_ff = 0; // 操作类型
  reg  [5:0]   lin_frame_id_ff = 0; // 帧ID
  reg  [63:0]  lin_frame_data_ff = 0; // 帧数据
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
      lin_param_en <= 1'b0;
    else if ((word_cnt == 0) && rx_axis_udp_tvalid_d1 && (rx_axis_udp_tdata_d1[23:16] == ID_LIN_PARAM[7:0]))
      lin_param_en <= 1'b1;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      lin_param_en <= 1'b0;
  always @(posedge clk or posedge rst)
    if (rst)
      lin_data_en <= 1'b0;
    else if ((word_cnt == 0) && rx_axis_udp_tvalid_d1 && (rx_axis_udp_tdata_d1[23:16] == ID_LIN_DATA[7:0]))
      lin_data_en <= 1'b1;
    else if (rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      lin_data_en <= 1'b0;
// 参数解析
  // 通道索引
    always @ (posedge clk) if ((lin_param_en || lin_data_en) && (word_cnt == 0) && rx_axis_udp_tvalid_d2) lin_config_channel_ff <= rx_axis_udp_tdata_d2[15:8];
  // 工作模式
    always @ (posedge clk) if (lin_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) lin_mode_ff <= rx_axis_udp_tdata_d2[24];
  // 波特率, 单位us, 默认20Kbps（对应50us）
    always @ (posedge clk) if (lin_param_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) lin_baudrate_ff <= rx_axis_udp_tdata_d2[9:0];
  // 校验类型
    always @ (posedge clk) if (lin_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) lin_parity_type_ff <= rx_axis_udp_tdata_d2[24];
  // 内部终端电阻使能
    always @ (posedge clk) if (lin_param_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) lin_int_termin_ff <= rx_axis_udp_tdata_d2[16];
  // 操作类型
    always @ (posedge clk) if (lin_data_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) lin_op_type_ff <= rx_axis_udp_tdata_d2[25:24];
  // 帧ID
    always @ (posedge clk) if (lin_data_en && (word_cnt == 1) && rx_axis_udp_tvalid_d2) lin_frame_id_ff <= rx_axis_udp_tdata_d2[21:16];
  // 帧数据
    always @ (posedge clk) if (lin_data_en && (word_cnt == 2) && rx_axis_udp_tvalid_d2) lin_frame_data_ff[63:32] <= rx_axis_udp_tdata_d2[31:0]; 
    always @ (posedge clk) if (lin_data_en && (word_cnt == 3) && rx_axis_udp_tvalid_d2) lin_frame_data_ff[31:0] <= rx_axis_udp_tdata_d2[31:0]; 
// 参数配置使能
  always @ (posedge clk or posedge rst)
    if (rst)
      lin_config_vld_ff <= 1'b0;
    else if (lin_param_en && rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      lin_config_vld_ff <= 1'b1;
    else
      lin_config_vld_ff <= 1'b0;
// 待发送帧有效指示
  always @ (posedge clk or posedge rst)
    if (rst)
      lin_frame_vld_ff <= 1'b0;
    else if (lin_data_en && rx_axis_udp_tvalid_d2 && rx_axis_udp_tlast_d2)
      lin_frame_vld_ff <= 1'b1;
    else
      lin_frame_vld_ff <= 1'b0;

//------------------------------------
//             Output Port
//------------------------------------
  assign lin_config_vld = lin_config_vld_ff;
  assign lin_config_channel = lin_config_channel_ff;
  assign lin_mode = lin_mode_ff;
  assign lin_baudrate = lin_baudrate_ff;
  assign lin_parity_type = lin_parity_type_ff;
  assign lin_int_termin = lin_int_termin_ff;
  assign lin_frame_vld = lin_frame_vld_ff;
  assign lin_op_type = lin_op_type_ff;
  assign lin_frame_id = lin_frame_id_ff;
  assign lin_frame_data = lin_frame_data_ff;
endmodule