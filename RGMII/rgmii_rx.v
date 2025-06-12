// ��ģ��Ϊ��̫�� RGMII ����ģ��, ֧����·״̬����, ֧�ִ������ݹ���

module rgmii_rx(
  // PHY оƬ״ָ̬ʾ
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
  reg        link_status = 0; // up(1), down(0)
  reg  [1:0] clock_speed = 0; // 125MHz(10), 25MHz(01), 2.5MHz(00), reserved(11)
  reg        duplex_status = 0; // half-duplex(0), full-duplex(1)
  
  reg        nibble_flag = 0; // 10&100Mbps��ÿ�����ڷ�תһ��, ����ƴ������
  reg        gmii_rx_no_error = 0; // ����������ȷ��־
  reg  [7:0] gmii_rxd_ff1 = 0; // ��ȷ���ݼĴ���1
  reg  [7:0] gmii_rxd_ff2 = 0; // ��ȷ���ݼĴ���2
  reg  [7:0] rx_axis_rgmii_tdata_ff = 0;
  reg        rx_axis_rgmii_tvalid_ff = 0;
  
  // Instant Module Signal
  wire       rgmii_rxc_bufio;
  wire       rgmii_rxc_bufr;
  wire       gmii_rx_dv;
  wire       gmii_rx_er;
  wire [7:0] gmii_rxd;

//------------------------------------
//             User Logic
//------------------------------------
// RGMII 2.0 ֧��ֱ��ͨ�� RX_DV & RX_ER & RXD[3:0] ���ж���·״̬
  // �� RX_DV = 0 && RX_ER = 0 ʱ, ͨ�� RXD[0] �ж���·����״̬
  always @ (posedge rgmii_rxc_bufr)
    if ((gmii_rx_dv | gmii_rx_er) == 1'b0)
      link_status <= gmii_rxd[0];

  // �� RX_DV = 0 && RX_ER = 0 ʱ, ͨ�� RXD[2:1] �ж���·ʱ��״̬
  always @ (posedge rgmii_rxc_bufr)
    if ((gmii_rx_dv | gmii_rx_er) == 1'b0)
      clock_speed <= gmii_rxd[2:1];

  // �� RX_DV = 0 && RX_ER = 0 ʱ, ͨ�� RXD[3] �ж���·��˫��״̬
  always @ (posedge rgmii_rxc_bufr)
    if ((gmii_rx_dv | gmii_rx_er) == 1'b0)
      duplex_status <= gmii_rxd[3];

// ����������ȷ��־
  always @ (posedge rgmii_rxc_bufr)
    if (gmii_rx_dv)
    // if (gmii_rx_dv & (~gmii_rx_er))
      gmii_rx_no_error <= 1'b1;
    else
      gmii_rx_no_error <= 1'b0;

// �Ĵ���ȷ������
  always @ (posedge rgmii_rxc_bufr)
    if (gmii_rx_dv)
    // if (gmii_rx_dv & (~gmii_rx_er))
      begin
        gmii_rxd_ff1 <= gmii_rxd;
        gmii_rxd_ff2 <= gmii_rxd_ff1;
      end

// 10&100Mbps��ÿ�����ڷ�תһ��, ����ƴ������
  always @ (posedge rgmii_rxc_bufr)
    if (gmii_rx_no_error)
      nibble_flag <= ~nibble_flag;

// �������ݼ���Ч����ź�����
  always @ (posedge rgmii_rxc_bufr)
    if (link_status & gmii_rx_no_error)
      begin
        if (clock_speed == 2'b10) // ����ʱ��Ϊ 125MHz, ��Ӧ��·���� 1Gbps
          begin
            rx_axis_rgmii_tdata_ff <= gmii_rxd_ff1;
            rx_axis_rgmii_tvalid_ff <= 1'b1;
          end
        else if (nibble_flag) // ����ʱ��Ϊ 2.5/25MHz, ��Ӧ��·���� 10/100Mbps, ���ѽ�����ǰ���ֽ�����
          begin
            rx_axis_rgmii_tdata_ff <= {gmii_rxd_ff2[3:0],gmii_rxd_ff1[3:0]};
            rx_axis_rgmii_tvalid_ff <= 1'b1;
          end
        else
          begin
            rx_axis_rgmii_tdata_ff <= 8'b0;
            rx_axis_rgmii_tvalid_ff <= 1'b0;
          end
      end
    else // ��·�Ͽ� �� �������ݴ���
      begin
        rx_axis_rgmii_tdata_ff <= 8'b0;
        rx_axis_rgmii_tvalid_ff <= 1'b0;
      end

//------------------------------------
//             Output Port
//------------------------------------
  assign rx_mac_aclk = rgmii_rxc_bufr;
  assign inband_link_status = link_status;
  assign inband_clock_speed = clock_speed;
  assign inband_duplex_status = duplex_status;
  assign rx_axis_rgmii_tdata = rx_axis_rgmii_tdata_ff;
  assign rx_axis_rgmii_tvalid = rx_axis_rgmii_tvalid_ff;

//------------------------------------
//             Instance
//------------------------------------
  BUFIO bufio_rgmii_rxc(
    .O(rgmii_rxc_bufio), // 1-bit output: Clock output (connect to I/O clock loads).
    .I(rgmii_rxc) // 1-bit input: Clock input (connect to an IBUF or BUFMR).
  );

  BUFR #(
    .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES" 
  ) bufr_rgmii_rxc (
    .O(rgmii_rxc_bufr),     // 1-bit output: Clock output port
    .CE(1'b1),   // 1-bit input: Active high, clock enable (Divided modes only)
    .CLR(1'b0), // 1-bit input: Active high, asynchronous clear (Divided modes only)
    .I(rgmii_rxc)      // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
  );

  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                    //    or "SAME_EDGE_PIPELINED" 
    .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
    .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
    .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
  ) iddr_rgmii_rx_ctl (
    .Q1(gmii_rx_dv), // 1-bit output for positive edge of clock
    .Q2(gmii_rx_er), // 1-bit output for negative edge of clock
    .C(rgmii_rxc_bufio),   // 1-bit clock input
    .CE(1'b1), // 1-bit clock enable input
    .D(rgmii_rx_ctl),   // 1-bit DDR data input
    .R(1'b0),   // 1-bit reset, active high
    .S(1'b0)    // 1-bit set, active high
  );
  
genvar i;
generate
  for (i = 0; i < 4; i = i + 1) begin
    IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                            //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
    ) iddr_rgmii_rxd (
      .Q1(gmii_rxd[i]), // 1-bit output for positive edge of clock
      .Q2(gmii_rxd[i+4]), // 1-bit output for negative edge of clock
      .C(rgmii_rxc_bufio),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(rgmii_rxd[i]),   // 1-bit DDR data input
      .R(1'b0),   // 1-bit reset, active high
      .S(1'b0)    // 1-bit set, active high
    );
  end
endgenerate

endmodule