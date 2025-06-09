// 复位管理模块

module reset_ctrl(
  // 模块时钟
  input     tx_clk, // 发送时钟
  input     rx_clk, // 接收时钟
  input     usb_clk, // USB源同步时钟
  // 全局异步复位
  input     rst_glbl,
  // 模块复位
  output    o_rst_txclk,
  output    o_rst_rxclk,
  output    o_rst_usbclk,
  output    o_rstn_txclk,
  output    o_rstn_rxclk,
  output    o_rstn_usbclk
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg [5:0] rst_cnt = 0;
  reg       rst_dly16 = 1;
  reg       rst_dly32 = 1;
  wire      rstn_dly16;
  wire      rstn_dly32;

//------------------------------------
//             User Logic
//------------------------------------

  always @ (posedge tx_clk or posedge rst_glbl)
    if (rst_glbl)
      rst_cnt <= 'd0;
    else if (rst_cnt[5])
      rst_cnt <= rst_cnt;
    else
      rst_cnt <= rst_cnt + 'd1;
  
  always @ (posedge tx_clk)
    if (rst_cnt < 'd16)
      rst_dly16 <= 1'b1;
    else
      rst_dly16 <= 1'b0;
  
  always @ (posedge tx_clk)
    if (rst_cnt[5])
      rst_dly32 <= 1'b0;
    else
      rst_dly32 <= 1'b1;

  assign rstn_dly16 = ~rst_dly16;
  assign rstn_dly32 = ~rst_dly32;

//------------------------------------
//             Instance
//------------------------------------

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(1)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rst_txclk (
    .dest_arst(o_rst_txclk),       //目的复位信号
    .dest_clk (tx_clk ),       // 目的时钟
    .src_arst (rst_dly16 )       // 源复位信号
  );   

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(1)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rst_rxclk (
    .dest_arst(o_rst_txclk),       //目的复位信号
    .dest_clk (rx_clk ),       // 目的时钟
    .src_arst (rst_dly16 )       // 源复位信号
  );   

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(1)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rst_usbclk (
    .dest_arst(o_rst_usbclk),       //目的复位信号
    .dest_clk (usb_clk ),       // 目的时钟
    .src_arst (rst_dly32 )       // 源复位信号
  );   

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(0)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rstn_txclk (
    .dest_arst(o_rstn_txclk),       //目的复位信号
    .dest_clk (tx_clk ),       // 目的时钟
    .src_arst (rstn_dly16 )       // 源复位信号
  );   

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(0)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rstn_rxclk (
    .dest_arst(o_rstn_txclk),       //目的复位信号
    .dest_clk (rx_clk ),       // 目的时钟
    .src_arst (rstn_dly16 )       // 源复位信号
  );   

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(0)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rstn_usbclk (
    .dest_arst(o_rstn_usbclk),       //目的复位信号
    .dest_clk (usb_clk ),       // 目的时钟
    .src_arst (rstn_dly32 )       // 源复位信号
  );   

endmodule