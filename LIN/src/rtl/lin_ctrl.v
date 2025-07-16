// LIN 协议处理模块

module lin_ctrl #(
  parameter CHANNEL_INDEX = 0, // 通道索引
  parameter CLK_FREQ = 100000000, // 模块时钟频率, Unit: Hz
  parameter TIMEOUT_VAL = 1000 // 响应超时阈值, Unit: us
)(
  // 模块时钟及复位
  input         clk,
  input         rst,
  // LIN收发物理接口
  input         lin_rx_rtl,
  output        lin_tx_rtl,
  //输出参数
  input         lin_config_vld, // 参数配置使能, 高有效
  input  [7:0]  lin_config_channel, // 通道索引
  input         lin_mode, // 工作模式
  input  [23:0] lin_baudrate, // 波特率, 单位us, 默认20Kbps（对应50us）
  input         lin_parity_type, // 校验类型
  input         lin_int_termin, // 内部终端电阻使能, 高有效
  input         lin_frame_vld, // 数据帧配置使能, 高有效
  input  [1:0]  lin_op_type, // 操作类型
  input  [5:0]  lin_frame_id, // 帧ID
  input  [63:0] lin_frame_data, // 帧数据
  // LIN数据上传
  output [31:0] upload_lin_tdata,
  output        upload_lin_tvalid,
  output        upload_lin_tlast,
  output        upload_lin_tready,
  output        lin_ready // 总线准备好标志, 高有效
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam   IDLE                = 5'd0; // 空闲状态, 主站模式下等待发送请求 或 从站模式下等待接收同步间隔
  localparam   S_BREAK             = 5'd1; // 从站模式: 检测同步间隔段间隔符
  localparam   S_WAIT_SYNC         = 5'd2; // 从站模式: 检测同步段
  localparam   S_SYNC              = 5'd3; // 从站模式: 接收同步段
  localparam   S_WAIT_PID          = 5'd4; // 从站模式: 检测PID段
  localparam   S_RCV_PID           = 5'd5; // 从站模式: 接收PID段
  localparam   M_BREAK             = 5'd6; // 主站模式: 发送同步间隔段(至少13位连续显性电平0 + 至少1位隐性电平1)
  localparam   M_SEND_SYNC         = 5'd7; // 主站模式: 发送同步段 0x55
  localparam   M_SYNC_DONE         = 5'd8; // 主站模式: 同步段发送完成
  localparam   M_SEND_PID          = 5'd9; // 主站模式: 发送PID段(由用户配置的6位帧ID + FPGA计算2位奇偶校验位组成)
  localparam   M_PID_DONE          = 5'd10; // 主站模式: PID段发送完成
  localparam   PID_CHECK           = 5'd11; // 判断是发送数据或等待接收响应
  localparam   SEND_DATA           = 5'd12; // 发送字节数据
  localparam   SEND_DATA_DONE      = 5'd13; // 发送字节数据完成
  localparam   SEND_CKS            = 5'd14; // 发送校验和
  localparam   SEND_CKS_DONE       = 5'd15; // 发送校验和完成
  localparam   WAIT_RCV_DATA       = 5'd16; // 等待接收响应
  localparam   RCV_DATA            = 5'd17; // 接收响应数据
  localparam   WAIT_RCV_CKS        = 5'd18; // 等待接收响应数据校验和
  localparam   RCV_CKS             = 5'd19; // 接收响应数据校验和
  localparam   CKS_CHECK           = 5'd20; // 响应校验和判断
  localparam   DELAY               = 5'd21; // 延时一拍, 等待校验和计算完成
  localparam   DONE                = 5'd22; // 完成 LIN 帧发送或接收
  localparam   ERROR               = 5'd23; // 发生错误

  localparam TIME_1US = (CLK_FREQ/1000000)-1; // 1US 对应计数器值
//------------------------------------
//             Local Signal
//------------------------------------
// 参数配置使能寄存
  reg          lin_config_vld_reg = 0;
// 数据帧配置使能寄存
  reg          lin_frame_vld_reg = 0;
// 本地参数更新
  reg          lin_mode_local = 0; // 工作模式
  reg  [23:0]  lin_baudrate_local = 24'd32; // 波特率, 单位us, 默认20Kbps（对应50us）
  reg          lin_parity_type_local = 0; // 校验类型
  reg          lin_int_termin_local = 0; // 内部终端电阻使能, 高有效
  reg          lin_frame_vld_local = 0; // 数据帧配置使能, 高有效
  reg  [1:0]   lin_op_type_local = 0; // 操作类型
  reg  [5:0]   lin_frame_id_local = 0; // 帧ID
  reg  [63:0]  lin_frame_data_local = 0; // 帧数据
// 状态机
  reg  [4:0]   c_state = IDLE; // 现态
  reg  [4:0]   n_state = IDLE; // 次态
// 状态机跳转信号
  wire         m_tx_req; // 主站模式发送请求
  wire         s_det_break1; // 从站模式检测到同步间隔段
  wire         s_det_break2; // 从站模式检测到同步间隔符
  wire         det_start_bit; // 检测到起始位
  wire         s_sync_done; // 从站模式同步段接收完成
  wire         m_tx_req; // 主站模式发送请求
  wire         m_break_done; // 主站模式同步间隔段发送完成
  wire         wait_rcv_resp; // 等待接收响应数据
  wire         tx_byte_done; // 发送字节数据完成
  wire         tx_all_done; // 发送所有数据完成
  wire         rx_byte_done; // 接收字节数据完成
  wire         rx_all_done; // 接收所有数据完成
// 错误状态标志
  wire         timeout_err; // 从机响应超时
  wire         send_err; // 发送错误(发送和接收数据不一致)
  wire         stop_err; // 停止位错误
  wire         parity_err; // 奇偶校验错误
  wire         cks_err; // 校验和错误
  reg  [4:0]   error_status = 0; // 错误状态寄存器
// LIN 发送模块
  reg          bypass = 0; // 用于控制发送同步间隔段
  reg          bypass_data = 0;
  reg          updata_point = 0; // 更新bit标志
  reg          tx_data_req = 0; // 发送数据请求信号
  reg  [7:0]   tx_data = 0; // 发送数据
// LIN 接收模块
  reg          rx_rst = 1; // 接收模块复位
  reg          sample_point = 0; // 采样bit标志
  reg  [7:0]   rx_byte_data = 0; // 接收字节数据
// LIN 校验和计算模块
  reg          cks_rst = 0; // 校验和模块复位
  reg          cks_enable = 0; // 校验和使能
  reg  [7:0]   cks_din = 0; // 校验和计算数据
  reg  [7:0]   cks_dout = 0; // 校验和计算结果





//------------------------------------
//             User Logic
//------------------------------------

//------------------------------------
//             Output Port
//------------------------------------

endmodule