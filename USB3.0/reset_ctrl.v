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




//------------------------------------
//             User Logic
//------------------------------------



//------------------------------------
//             Output Port
//------------------------------------



//------------------------------------
//             Instance
//------------------------------------

  xpm_cdc_async_rst #(
    .DEST_SYNC_FF   (4),    // 设置用于同步的寄存器级数
    .INIT_SYNC_FF   (0),    // 仿真初始化参数使能
    .RST_ACTIVE_HIGH(0)    // DECIMAL; 0=active low reset, 1=active high reset
  )xpm_cdc_async_rst_inst (
    .dest_arst(dest_arst),       //目的复位信号
    .dest_clk (dest_clk ),       // 目的时钟
    .src_arst (src_arst )       // 源复位信号
  );   


endmodule