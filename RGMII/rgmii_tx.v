// ��ģ��Ϊ��̫��RGMII����ģ��, ֧����������Ӧ

module rgmii_tx (
  input         clk_125mhz,
  input         clk90_125mhz,
  input         reset,
  input         reset90,
  // PHY оƬ״ָ̬ʾ
  input         phy_link_status, // up(1), down(0)
  input  [1:0]  phy_speed_status, // 10Mbps(0), 100Mbps(1), 1000Mbps(2)
  // RGMII_TX
  output        rgmii_txc,
  output        rgmii_tx_ctl,
  output [3:0]  rgmii_txd,
  // User interface
  input  [7:0]  tx_axis_rgmii_tdata,
  input         tx_axis_rgmii_tvalid,
  output        tx_axis_rgmii_tready
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire          phy_link_status_txclk;
  wire [1:0]    phy_speed_status_txclk;
  reg  [7:0]    tx_axis_rgmii_tdata_ff = 0; // �Ĵ��ź�
  reg           tx_axis_rgmii_handshake = 0; // ���ֳɹ�ָʾ
  reg  [5:0]    clk_cnt = 0; // ��Ƶʱ�Ӽ�����
  reg           clk_div5_50 = 1; // 10/100Mbps�� 5/50����Ƶ�ź�
  reg           clk90_div5_50 = 0; // 10/100Mbps�� 5/50����Ƶ�źŲ�����90���ź�
  reg           tx_data_en = 0; // ����������Чָʾ
  reg           tx_data_error = 0; // �������ݴ���ָʾ
  reg           tx_axis_rgmii_tready_ff = 0; // RGMII����׼���ź�
  reg  [3:0]    tx_data_msb = 0; // RGMII �������ݸ� 4-bit
  reg  [3:0]    tx_data_lsb = 4'b1101; // RGMII �������ݵ� 4-bit
  reg           tx_nibble_sw = 0; // 10/100Mbps�� RGMII ���Ͱ��ֽ��л�ָʾ
  reg           tx_nibble_sw_d1 = 0; // �ӳ�һ��
  reg           msb_lsb_flag = 0; // 10/100Mbps�µ�ǰ RGMII  ���͸ߵ�nibbleָʾ, H-nibble(1), L-nibble(0)
  reg           bus_status = 0; // ��������״̬, ����(0), æµ(1)
  reg           tx10_100_data_en = 0; // 10/100Mbps��Ч���ݷ����ڼ�ָʾ

//------------------------------------
//             User Logic
//------------------------------------
// ��Ƶʱ�Ӽ�����
  always @ (posedge clk_125mhz)
    if (reset | (~phy_link_status_txclk))
      clk_cnt <= 6'd0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      clk_cnt <= 6'd0;
    else if (phy_speed_status_txclk[0]) // 100Mbps
      begin
        if (clk_cnt == 6'd4)
          clk_cnt <= 6'd0;
        else
          clk_cnt <= clk_cnt + 6'd1;
      end
    else // 10Mbps
      begin
        if (clk_cnt == 6'd49)
          clk_cnt <= 6'd0;
        else
          clk_cnt <= clk_cnt + 6'd1;
      end

// 10/1000Mbps��5/50����Ƶ�ź�
  always @ (posedge clk_125mhz)
    if (reset | (~phy_link_status_txclk))
      clk_div5_50 <= 1'b1;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      clk_div5_50 <= 1'b1;
    else if (phy_speed_status_txclk[0]) // 100Mbps
      begin
        if (clk_cnt == 6'd4 || clk_cnt == 6'd0)
          clk_div5_50 <= 1'b1;
        else
          clk_div5_50 <= 1'b0;
      end
    else // 10Mbps
      begin
        if (clk_cnt == 6'd49 || clk_cnt < 6'd24)
          clk_div5_50 <= 1'b1;
        else
          clk_div5_50 <= 1'b0;
      end

// RGMII ��������AXIS�ӿ����ֳɹ�ָʾ
  always @ (posedge clk_125mhz)
    if (reset)
      tx_axis_rgmii_handshake <= 1'b0;
    else if (tx_axis_rgmii_tvalid & tx_axis_rgmii_tready_ff) // ���ֳɹ�
      tx_axis_rgmii_handshake <= 1'b1;
    else
      tx_axis_rgmii_handshake <= 1'b0;

// RGMII�������ݼĴ�
  always @ (posedge clk_125mhz)
    if (reset)
      tx_axis_rgmii_tdata_ff <= {4'b0,4'b1101};
    else if (tx_axis_rgmii_tvalid & tx_axis_rgmii_tready_ff) // ���·�������
      tx_axis_rgmii_tdata_ff <= tx_axis_rgmii_tdata;
    else if (tx_nibble_sw) // 10/100Mbps ���͸ߵ�nibble
      tx_axis_rgmii_tdata_ff <= {4'b0,tx_axis_rgmii_tdataff[7:4]};
    else if (!tx10_100_data_en) // Ĭ�ϴ�������
      tx_axis_rgmii_tdata_ff <= {4'b0,1'b1,phy_speed_status_txclk,1'b1};
    else
      tx_axis_rgmii_tdata_ff <= tx_axis_rgmii_tdata_ff;

// ��������״̬, ����(0), æµ(1)
  always @ (posedge clk_125mhz)
    if (reset)
      bus_status <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      bus_status <= 1'b1;
    else // 10/100Mbps
      begin
        if (tx_axis_rgmii_handshake) // ��������
          bus_status <= 1'b1;
        else if (msb_lsb_flag && ((phy_speed_status_txclk[0] && clk_cnt == 6'd3) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd48))) // �����굱ǰ����, ��û�������ݴ�����
          bus_status <= 1'b0;
      end

// RGMII����׼���ź�
  always @ (posedge clk_125mhz)
    if (reset || (~phy_link_status_txclk))
      tx_axis_rgmii_tready_ff <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      tx_axis_rgmii_tready_ff <= 1'b1;
    else // 10/100Mbps
      begin
        if (tx_axis_rgmii_tvalid && ((!bus_status) | msb_lsb_flag) && ((phy_speed_status_txclk[0] && clk_cnt == 6'd2) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd47))) // 10/100Mbps�·��������뷢�����ݻ����굱ǰ����, �һ������ݴ�����
          tx_axis_rgmii_tready_ff <= 1'b1;
        else
          tx_axis_rgmii_tready_ff <= 1'b0;
      end

// ����������Чָʾ
  always @ (posedge clk_125mhz)
    if (reset)
      tx_data_en <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      tx_data_en <= tx_axis_rgmii_handshake;
    else // 10/100Mbps
      begin
        if (tx_axis_rgmii_handshake | tx_nibble_sw_d1) // �������� �� �������nibble, ׼�����͸�nibble
          tx_data_en <= 1'b1;
        else if ((phy_speed_status_txclk[0] && clk_cnt == 6'd4) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd49)) // ����������ʹ���ź�, ���ŷ��Ͱ�����ڴ���ָʾ�ź�
          tx_data_en <= 1'b0;
      end

// �������ݴ���ָʾ
  always @ (posedge clk_125mhz)
    if (reset)
      tx_data_error <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      tx_data_error <= 1'b0;
    else // 10/100Mbps
      begin
        if (tx_axis_rgmii_handshake | tx_nibble_sw_d1) // �������� �� �������nibble, ׼�����͸�nibble
          tx_data_error <= 1'b1;
        else if ((phy_speed_status_txclk[0] && clk_cnt == 6'd2) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd24)) // ����������ʹ���ź�, ���ŷ��Ͱ�����ڴ���ָʾ�ź�
          tx_data_error <= 1'b0;
      end

// 10/100Mbps�� RGMII ���Ͱ��ֽ��л�ָʾ
  always @ (posedge clk_125mhz)
    if (reset)
      tx_nibble_sw <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      tx_nibble_sw <= 1'b0;
    else if (bus_status && (!msb_lsb_flag))
      begin
        if (phy_speed_status_txclk[0] && clk_cnt == 6'd2) // 100Mbps
          tx_nibble_sw <= 1'b1;
        else if ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd47) // 10Mbps
          tx_nibble_sw <= 1'b1;
        else
          tx_nibble_sw <= 1'b0;
      end
    else
      tx_nibble_sw <= 1'b0;

// �ӳ�һ��
  always @ (posedge clk_125mhz) tx_nibble_sw_d1 <= tx_nibble_sw;

// 10/100Mbps�µ�ǰ RGMII  ���͸ߵ�nibbleָʾ, H-nibble(1), L-nibble(0)
  always @ (posedge clk_125mhz)
    if (reset)
      msb_lsb_flag <= 1'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps
      msb_lsb_flag <= 1'b0;
    else if (bus_status) // 10/100Mbps
      begin
        if ((phy_speed_status_txclk[0] && clk_cnt == 6'd4) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd49))
          msb_lsb_flag <= ~msb_lsb_flag;
      end
    else
      msb_lsb_flag <= 1'b0;

// 10/100Mbps��Ч���ݷ����ڼ�ָʾ
  always @ (posedge clk_125mhz)
    if (reset)
      tx10_100_data_en <= 1'b0;
    else if (!phy_speed_status_txclk[1]) // 10/100Mbps
      begin
        if (tx_axis_rgmii_tready_ff | tx_nibble_sw) // �������� �� �������nibble, ׼�����͸�nibble
        else if ((phy_speed_status_txclk[0] && clk_cnt == 6'd3) || ((!phy_speed_status_txclk[0]) && clk_cnt == 6'd48))
          tx10_100_data_en <= 1'b0;
      end
    else
      tx10_100_data_en <= 1'b0;

// �������ݸ�nibble
  always @ (posedge clk_125mhz)
    if (reset)
      tx_data_msb <= 4'b0;
    else if (phy_speed_status_txclk[1]) // 1000Mbps ��˫�ش���
      tx_data_msb <= tx_axis_rgmii_tdata_ff[7:4];
    else // 10/100Mbps �µ��ش���
      tx_data_msb <= tx_axis_rgmii_tdata_ff[3:0];

// �������ݵ�nibble
  always @ (posedge clk_125mhz)
    if (reset || (!phy_link_status_txclk))
      tx_data_lsb <= 4'b1101;
    else
      tx_data_lsb <= tx_axis_rgmii_tdata_ff[3:0];

//------------------------------------
//             Output Port
//------------------------------------
  assign tx_axis_rgmii_tready = tx_axis_rgmii_tready_ff;

//------------------------------------
//             Instance
//------------------------------------

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
    .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
    .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
  ) oddr_rgmii_txc (
    .Q(rgmii_txc),   // 1-bit DDR output
    .C(clk_125mhz),   // 1-bit clock input
    .CE(1'b1), // 1-bit clock enable input
    .D1(clk_div5_50), // 1-bit data input (positive edge)
    .D2(clk90_div5_50), // 1-bit data input (negative edge)
    .R(reset),   // 1-bit reset
    .S(1'b0)    // 1-bit set
  );

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
    .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
    .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
  ) oddr_rgmii_tx_ctl (
    .Q(rgmii_tx_ctl),   // 1-bit DDR output
    .C(clk_125mhz),   // 1-bit clock input
    .CE(1'b1), // 1-bit clock enable input
    .D1(tx_data_en), // 1-bit data input (positive edge)
    .D2(tx_data_en), // 1-bit data input (negative edge)
    // .D2(tx_data_error), // 1-bit data input (negative edge)
    .R(reset),   // 1-bit reset
    .S(1'b0)    // 1-bit set
  );

genvar i;
generate
  for (i = 0; i < 4; i= i + 1)
    begin
      ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
        .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
      ) oddr_rgmii_txd (
        .Q(rgmii_txd[i]),   // 1-bit DDR output
        .C(clk_125mhz),   // 1-bit clock input
        .CE(1'b1), // 1-bit clock enable input
        .D1(tx_data_lsb[i]), // 1-bit data input (positive edge)
        .D2(tx_data_msb[i]), // 1-bit data input (negative edge)
        .R(reset),   // 1-bit reset
        .S(1'b0)    // 1-bit set
      );
    end
endgenerate

  xpm_cdc_array_single #(
    .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0),  // DECIMAL; 0=do not register input, 1=register input
    .WIDTH(2)           // DECIMAL; range: 1-1024
  )phy_speed_status_txclk(
    .dest_out(phy_speed_status_txclk), // WIDTH-bit output: src_in synchronized to the destination clock domain. This
                          // output is registered.

    .dest_clk(clk_125mhz), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(1'b0),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(phy_speed_status)      // WIDTH-bit input: Input single-bit array to be synchronized to destination clock
                          // domain. It is assumed that each bit of the array is unrelated to the others. This
                          // is reflected in the constraints applied to this macro. To transfer a binary value
                          // losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.

  );

  xpm_cdc_single #(
    .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
  )phy_link_status_txclk(
    .dest_out(phy_link_status_txclk), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                          // registered.

    .dest_clk(clk_125mhz), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(1'b0),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(phy_link_status)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
  );


endmodule
