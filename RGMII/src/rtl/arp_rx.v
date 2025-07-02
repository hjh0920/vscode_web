// IP报文接收模块

module ip_rx(
  // PHY 芯片状态指示
  output      inband_link_status, // up(1), down(0)
  output [1:0]inband_clock_speed, // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
  output      inband_duplex_status, // half-duplex(0), full-duplex(1)
  // RGMII_RX
  input        rgmii_rxc,
  input        rgmii_rx_ctl,
  input  [3:0] rgmii_rxd,
  // User interface
  output       rx_mac_aclk,
  output [7:0] rx_axis_rgmii_tdata,
  output       rx_axis_rgmii_tvalid
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

endmodule
