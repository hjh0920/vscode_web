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
  input  [9:0]  lin_baudrate, // 波特率, 单位us, 默认20Kbps（对应50us）
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
  localparam   WAIT_RCV_DATA       = 5'd16; // 等待接收响应数据
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
  reg  [9:0]   lin_baudrate_local = 10'd50; // 波特率, 单位us, 默认20Kbps（对应50us）
  reg          lin_parity_type_local = 0; // 校验类型
  reg          lin_int_termin_local = 0; // 内部终端电阻使能, 高有效
  reg  [1:0]   lin_op_type_local = 0; // 操作类型
  reg  [5:0]   lin_frame_id_local = 0; // 帧ID
  reg  [63:0]  lin_frame_data_local = 0; // 帧数据
// 状态机
  reg  [4:0]   c_state = IDLE; // 现态
  reg  [4:0]   n_state = IDLE; // 次态
// 状态机跳转标志
  wire         m_tx_req; // 主站模式发送请求
  wire         s_det_break1; // 从站模式检测到同步间隔段
  wire         s_det_break2; // 从站模式检测到同步间隔符
  wire         det_start_bit; // 检测到起始位
  wire         s_sync_done; // 从站模式同步段接收完成
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
  wire [7:0]   rx_byte_data; // 接收字节数据
// LIN 校验和计算模块
  reg          cks_rst = 0; // 校验和模块复位
  reg          cks_enable = 0; // 校验和使能
  reg  [7:0]   cks_din = 0; // 校验和计算数据
  reg  [7:0]   cks_dout = 0; // 校验和计算结果
// 其他信号
  reg  [7:0]   tcnt = 0; // 计数器
  reg  [9:0]   tcnt_us = 0; // us 计数器
  reg  [3:0]   tx_break_bit_cnt = 0; // 发送同步间隔段bit计数器
  reg  [63:0]  tx_lin_data = 0; // 发送数据寄存器, LSB
  reg  [63:0]  tx_data_srl = 0; // 发送数据移位寄存器, LSB
  reg  [3:0]   data_length= 0; // 发送/接收数据长度, 单位 Byte
  reg  [7:0]   s_rcv_pid = 0; // 从站接收PID
  reg  [7:0]   rcv_cks = 0; // 接收校验和
  reg  [2:0]   tx_byte_cnt = 0; // 发送字节计数器
  reg  [2:0]   rx_byte_cnt = 0; // 接收字节计数器
  reg  [63:0]  rx_data_srl = 0; // 接收数据移位寄存器, LSB
  reg          lin_rx_rtl_d1 = 1; // 接收数据延迟一拍
  reg          lin_rx_rtl_d2 = 1; // 接收数据延迟一拍
  reg  [3:0]   rx_dominant_bit_cnt = 0; // 连续接收显性电平bit计数器
  reg  [7:0]   timeout_cnt = 0; // 响应超时计数器
// LIN 从站响应帧路由表
  reg  [0:0]   lin_slave_wea = 0;
  reg  [5:0]   lin_slave_addra = 0;
  reg  [64:0]  lin_slave_dina = 0;
  wire [5:0]   lin_slave_addrb;
  wire [64:0]  lin_slave_doutb;
// LIN数据上传接口
  reg          lin_ready_ff = 0; // 总线准备好标志, 高有效
  reg  [7:0]   upload_lin_pid_ff = 0;
  reg  [3:0]   upload_lin_data_length_ff = 0;
  reg  [63:0]  upload_lin_data_ff = 0;
  reg  [7:0]   upload_lin_cks_ff = 0;
  
  reg  [31:0]  upload_lin_tdata_ff = 0;
  reg          upload_lin_tvalid_ff = 0;
  reg          upload_lin_tlast_ff = 0;
  reg  [1:0]   upload_lin_cnt = 0;

//------------------------------------
//             User Logic
//------------------------------------
// 参数配置使能寄存器
  always @ (posedge clk or posedge rst)
    if (rst)
      lin_config_vld_reg <= 0;
    else if (lin_config_vld && (lin_config_channel == CHANNEL_INDEX[7:0]))
      lin_config_vld_reg <= 1;
    else if (c_state == IDLE)
      lin_config_vld_reg <= 0;
// 数据帧配置使能寄存
  always @ (posedge clk or posedge rst)
    if (rst)
      lin_frame_vld_reg <= 0;
    else if (lin_frame_vld && (lin_frame_channel == CHANNEL_INDEX[7:0]))
      lin_frame_vld_reg <= 1;
    else if (c_state == IDLE)
      lin_frame_vld_reg <= 0;
// 更新 本地参数
  always @ (posedge clk or posedge rst)
    if (rst)
      begin
        lin_mode_local        <= 0;
        lin_baudrate_local    <= 10'd50;
        lin_parity_type_local <= 0;
        lin_int_termin_local  <= 0;
      end
    else if (lin_config_vld_reg && (c_state == IDLE))
      begin
        lin_mode_local        <= lin_mode;
        lin_baudrate_local    <= lin_baudrate;
        lin_parity_type_local <= lin_parity_type;
        lin_int_termin_local  <= lin_int_termin;
      end
  always @ (posedge clk or posedge rst)
    if (rst)
      begin
        lin_op_type_local    <= 0;
        lin_frame_id_local   <= 0;
        lin_frame_data_local <= 0;
      end
    else if (lin_frame_vld_reg && (c_state == IDLE))
      begin
        lin_op_type_local    <= lin_op_type;
        lin_frame_id_local   <= lin_frame_id;
        lin_frame_data_local <= lin_frame_data;
      end
// 状态机
  always @ (posedge clk or posedge rst)
    if (rst)
      c_state <= IDLE;
    else
      c_state <= n_state;
  always @ (*)
    case (c_state)
      IDLE: // 空闲状态
        if (m_tx_req) // 主站模式发送请求
          n_state <= M_BREAK;
        else if (s_det_break1) // 从站模式检测到同步间隔段
          n_state <= S_BREAK;
      M_BREAK: // 主站模式发送同步间隔段
        if (send_err) // 发送错误
          n_state <= ERROR;
        else if (m_break_done) // 发送同步间隔段完成
          n_state <= M_SEND_SYNC;
      M_SEND_SYNC: // 主站模式发送同步段
        n_state <= M_SYNC_DONE;
      M_SYNC_DONE: // 主站模式发送同步段完成
        if (send_err) // 发送错误
          n_state <= ERROR;
        else if (tx_byte_done) // 发送同步段完成
          n_state <= M_SEND_PID;
      M_SEND_PID: // 主站模式发送PID
        n_state <= M_PID_DONE;
      M_PID_DONE: // 主站模式发送PID完成
        if (send_err) // 发送错误
          n_state <= ERROR;
        else if (tx_byte_done) // 发送PID完成
          n_state <= PID_CHECK;
      S_BREAK: // 从站模式检测到同步间隔段
        if (s_det_break2) // 检测到同步间隔符
          n_state <= S_WAIT_SYNC;
      S_WAIT_SYNC: // 从站模式等待同步段
        if (det_start_bit)
          n_state <= S_SYNC;
      S_SYNC: // 从站模式接收同步段
        if (stop_err) // 停止位错误
          n_state <= ERROR;
        else if (s_sync_done)
          n_state <= S_WAIT_PID;
      S_WAIT_PID: // 从站模式等待PID
        if (det_start_bit)
          n_state <= S_RCV_PID;
      S_RCV_PID: // 从站模式接收PID
        if (stop_err) // 停止位错误
          n_state <= ERROR;
        else if (rx_byte_done & updata_point)
          n_state <= PID_CHECK;
      PID_CHECK: // 判断是发送或等待接收响应数据
        if (parity_err) // 奇偶校验错误
          n_state <= ERROR;
        else if (wait_rcv_resp) // 等待接收响应数据
          n_state <= WAIT_RCV_DATA;
        else // 发送响应数据
          n_state <= SEND_DATA;
      SEND_DATA: // 发送数据
        n_state <= SEND_DATA_DONE;
      SEND_DATA_DONE: // 发送数据完成
        if (send_err) // 发送错误
          n_state <= ERROR;
        else if (tx_byte_done & tx_all_done)
          n_state <= SEND_CKS;
        else if (tx_byte_done) // 发送下一字节
          n_state <= SEND_DATA;
      SEND_CKS: // 发送校验位
        n_state <= SEND_CKS_DONE;
      SEND_CKS_DONE: // 发送校验位完成
        if (send_err) // 发送错误
          n_state <= ERROR;
        else if (tx_byte_done)
          n_state <= DONE;
      WAIT_RCV_DATA: // 等待接收响应数据
        if (timeout_err) // 超时错误
          n_state <= ERROR;
        else if (!lin_rx_rtl_d2) // 检测到起始位
          n_state <= RCV_DATA;
      RCV_DATA: // 接收响应数据
        if (stop_err) // 停止位错误
          n_state <= ERROR;
        else if (rx_byte_done & rx_all_done)
          n_state <= WAIT_RCV_CKS;
        else if (rx_byte_done) // 接收下一字节
          n_state <= WAIT_RCV_DATA;
      WAIT_RCV_CKS: // 等待接收校验和
        if (timeout_err) // 从机响应超时错误
          n_state <= ERROR;
        else if (det_start_bit) // 检测到起始位
          n_state <= RCV_CKS;
      RCV_CKS: // 接收校验和
        if (stop_err) // 停止位错误
          n_state <= ERROR;
        else if (rx_byte_done)
          n_state <= DELAY;
      DELAY: // 延时一拍, 等待校验和计算完成
        n_state <= CKS_CHECK;
      CKS_CHECK: // 校验和判断
        if (cks_err) // 校验和错误
          n_state <= ERROR;
        else
          n_state <= DONE;
      DONE: // 完成 LIN 帧发送或接收
        n_state <= IDLE;
      default:
        n_state <= IDLE;
    endcase
// 状态机跳转标志
  assign m_tx_req = lin_mode_local & lin_frame_vld_reg;
  assign s_det_break1 = (rx_dominant_bit_cnt == 13) && updata_point;
  assign s_det_break2 = (c_state == S_BREAK) && (sample_point & lin_rx_rtl_d1);
  assign det_start_bit = (lin_rx_rtl_d2 && (!lin_rx_rtl_d1));
  assign s_sync_done = (c_state == S_SYNC) && rx_byte_done && (rx_byte_data == 8'h55);
  assign m_break_done = (tx_break_bit_cnt == 13) && updata_point;
  assign wait_rcv_resp = (lin_mode_local && (lin_op_type_local == 2'b00)) || (!(lin_mode_local | lin_slave_doutb[64]));
// 错误状态标志
  assign timeout_err = (tcnt_us == TIMEOUT_VAL);
  assign parity_err = (!lin_mode_local && (c_state == PID_CHECK) && 
                       ({(~(s_rcv_pid[1] ^ s_rcv_pid[3] ^ s_rcv_pid[4] ^ s_rcv_pid[5])),(s_rcv_pid[0] ^ s_rcv_pid[1] ^ s_rcv_pid[2] ^ s_rcv_pid[4])} != s_rcv_pid[7:6]));
  assign cks_err = (c_state == CKS_CHECK) && ( cks_dout != 8'hFF);
  always @ (posedge clk)
    error_status <= {timeout_err, send_err, stop_err, parity_err, cks_err};
// LIN 发送模块
  always @ (posedge clk)
    bypass <= (c_state == M_BREAK) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    bypass_data <= (tx_break_bit_cnt == 13) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    updata_point <= ((tcnt == TIME_1US) && (tcnt_us == lin_baudrate_local-1)) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    tx_data_req <= ((c_state == M_SEND_SYNC) || (c_state == M_SEND_PID) || (c_state == SEND_DATA) || (c_state == SEND_CKS)) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    case (c_state)
      M_SEND_SYNC: tx_data <= 8'h55;
      M_SEND_PID: tx_data <= lin_pid_local;
      SEND_DATA: tx_data <= tx_data_srl[63:56];
      SEND_CKS: tx_data <= ~cks_dout;
      default: tx_data <= tx_data;
    endcase
// LIN 接收模块
  always @ (posedge clk)
    rx_rst <= ((c_state == S_SYNC) || (c_state == S_RCV_PID) || (c_state == RCV_DATA) || (c_state == RCV_CKS)) ? 1'b0 : 1'b1;
  always @ (posedge clk)
    sample_point <= ((tcnt == 0) && (tcnt_us == {1'b0,lin_baudrate_local[9:1]})) ? 1'b1 : 1'b0;
// LIN 校验和计算模块
  always @ (posedge clk)
    cks_rst <= (c_state == IDLE) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    cks_enable <= ((c_state == PID_CHECK) && lin_parity_type_local) || 
                  ((c_state == SEND_DATA_DONE) && tx_data_req) ||
                  (((c_state == RCV_DATA) || (c_state == RCV_CKS)) && rx_byte_done) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    case (c_state)
      PID_CHECK:
        cks_din <= lin_mode_local ? lin_pid_local : s_rcv_pid;
      SEND_DATA_DONE:
        if (tx_data_req) cks_din <= tx_data;
      RCV_DATA, RCV_CKS:
        if (rx_byte_done) cks_din <= rx_byte_data;
      default: cks_din <= 8'd0;
    endcase
// LIN 从站响应帧路由表
  always @ (posedge clk)
    lin_slave_wea <= ((c_state == IDLE) && lin_frame_vld_reg && lin_op_type_local[1]) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    lin_slave_addra <= lin_frame_id_local;
  always @ (posedge clk)
    lin_slave_dina <= ((c_state == IDLE) && lin_frame_vld_reg && (lin_op_type_local == 2'b10)) ? {1'b1, lin_frame_data_local} : 65'b0;
  assign lin_slave_addrb = s_rcv_pid;
// LIN数据上传接口
  always @ (posedge clk)
    lin_ready_ff <= (c_state == IDLE) ? 1'b1 : 1'b0;
  always @ (posedge clk)
    if ((c_state == PID_CHECK) && lin_mode_local)
      upload_lin_pid_ff <= lin_pid_local;
    else if ((c_state == PID_CHECK) && (!lin_mode_local))
      upload_lin_pid_ff <= s_rcv_pid;
  always @ (posedge clk)
    if (((c_state == DONE) || (c_state == ERROR)) && wait_rcv_resp)
      case (data_length)
        4'd2   : upload_lin_data_ff <= {rx_data_srl[15:0], 48'd0};
        4'd4   : upload_lin_data_ff <= {rx_data_srl[31:0], 32'd0};
        default: upload_lin_data_ff <= rx_data_srl;
      endcase
    else if ((c_state == DONE) || (c_state == ERROR))
      upload_lin_data_ff <= tx_lin_data;
  always @ (posedge clk)
    if ((c_state == DONE) || (c_state == ERROR))
      upload_lin_cks_ff <= wait_rcv_resp ? rcv_cks : (~cks_dout);
    
  
  

// 计数器
  always @ (posedge clk)
    if (c_state != n_state)
      tcnt <= 8'd0;
    else if (tcnt == TIME_1US)
      tcnt <= 8'd0;
    else
      tcnt <= tcnt + 8'd1;
  always @ (posedge clk)
    if (c_state != n_state)
      tcnt_us <= 8'd0;
    else if (tcnt == TIME_1US)
      begin
        if (tcnt_us == lin_baudrate_local-1)
          tcnt_us <= 8'd0;
        else
          tcnt_us <= tcnt_us + 8'd1;
      end
// 






        
        
        
//------------------------------------
//             Output Port
//------------------------------------
        
//------------------------------------
//             Instance
//------------------------------------
// LIN 发送模块
  lin_tx u_lin_tx (
    .clk          (clk),
    .rst          (rst),
    // LIN收发物理接口
    .lin_rx_rtl   (lin_rx_rtl), // 用于检测发送是否正确
    .lin_tx_rtl   (lin_tx_rtl), // 发送数据
    // 控制信号
    .bypass       (bypass), // 用于控制发送同步间隔段
    .bypass_data  (bypass_data),
    .updata_point (updata_point), // 更新bit标志
    // 发送数据
    .tx_data_req  (tx_data_req), // 发送数据请求信号
    .tx_data      (tx_data), // 发送数据
    .tx_data_ack  (tx_byte_done), // 发送数据应答信号
    .tx_data_err  (send_err) // 发送数据错误信号
  );
// LIN 接收模块
  lin_rx u_lin_rx (
    .clk          (clk),
    .rst          (rx_rst),
    // LIN收发物理接口
    .lin_rx_rtl   (lin_rx_rtl),
    // 控制信号
    .sample_point (sample_point), // 采样bit标志
    // 接收数据
    .rx_data_vld  (rx_byte_done), // 接收数据有效信号
    .rx_data      (rx_byte_data), // 接收数据
    .rx_data_err  (stop_err) // 接收数据错误信号(停止位错误)
  );
// LIN 校验和计算模块
  lin_cks u_lin_cks (
    .clk    (clk),
    .reset  (cks_rst),
    .enable (cks_enable),
    .din    (cks_din),
    .dout   (cks_dout)
  );
// LIN 从站响应帧路由表
   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.1
   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(6),               // DECIMAL
      .ADDR_WIDTH_B(6),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(64),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(65),         // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(65),        // DECIMAL
      .WRITE_MODE_B("no_change")      // String
   ) xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(lin_slave_doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(lin_slave_addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(lin_slave_addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(lin_slave_dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(1'b1),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(lin_slave_wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.
   );




endmodule