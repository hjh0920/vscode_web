`timescale 1ns/1ns


module tb_tri_mode_ethernet_mac;

//*************************** Parameters ***************************
  parameter integer  PERIOD_CLK125M = 8;

  // 帧过滤使能, 与本地MAC地址不一致过滤
  parameter C_FILTER_EN = 1;
  // 本地MAC地址
  parameter C_LOCAL_MAC = 48'h0102_0304_0506;
  // 接收超时时间(unit: rx_mac_aclk)
  parameter C_TIMEOUT   = 3000;
  // 帧间隔(Unit: bit time, 8整倍数)
  parameter C_IFG = 96;

  localparam [1:0] SPEED_1000M = 2'b10;
  localparam [1:0] SPEED_100M = 2'b01;
  localparam [1:0] SPEED_10M = 2'b00;
  localparam [15:0] ARP_REPLY = 16'h02;
  localparam [15:0] ARP_REQUEST = 16'h01;
  localparam [7:0]  IP_PROTO_ICMP = 8'h01;
  localparam [7:0]  IP_PROTO_UDP = 8'h11;
  localparam [7:0]  ICMP_ECHO_REPLY = 8'h00;
  localparam [7:0]  ICMP_ECHO_REQUEST = 8'h08;
  localparam [47:0] DMAC = 48'h06_05_04_03_02_01;
  localparam [47:0] SMAC = 48'h01_02_03_04_05_06;
  localparam [31:0] DIP = 32'h0102_0304;
  localparam [31:0] SIP = 32'h0403_0201;
  localparam [15:0] UDP_SRC_PORT = 16'h0102;
  localparam [15:0] UDP_DST_PORT = 16'h0201;

//***************************   Signals  ***************************
  reg           clk_125mhz = 0;
  wire          clk90_125mhz;
  reg           reset = 1;
  reg           reset90 = 1;
  reg           rgmii_rxc = 0;
  reg           rgmii_rx_ctl = 0;
  reg  [3:0]    rgmii_rxd = 0;
  wire          tx_mac_aclk;
  wire          tx_mac_reset;
  reg           tx_axis_mac_tvalid = 0;
  reg  [7:0]    tx_axis_mac_tdata = 0;
  reg           tx_axis_mac_tlast = 0;
  wire          tx_axis_mac_tready;
//*************************** Test Logic ***************************
  always # (PERIOD_CLK125M/2) clk_125mhz = ~clk_125mhz;
  assign # (PERIOD_CLK125M/4) clk90_125mhz = clk_125mhz;
  always # (PERIOD_CLK125M/2) rgmii_rxc = ~rgmii_rxc;


  initial
    begin
      #100;
        reset = 0;
        reset90 = 0;
      #1000;

      T_LINK_UP(50,SPEED_1000M);
      T_RX_ARP(ARP_REQUEST,SMAC,SIP,DIP);

      T_LINK_UP(50,SPEED_1000M);
      T_RX_ARP(ARP_REPLY,SMAC,SIP,DIP);

      T_LINK_UP(50,SPEED_1000M);
      T_RX_IP(IP_PROTO_ICMP,SMAC,DMAC,SIP,DIP,40,UDP_SRC_PORT,UDP_DST_PORT,ICMP_ECHO_REQUEST);

      T_LINK_UP(50,SPEED_1000M);
      T_RX_IP(IP_PROTO_ICMP,SMAC,DMAC,SIP,DIP,40,UDP_SRC_PORT,UDP_DST_PORT,ICMP_ECHO_REPLY);

      T_LINK_UP(50,SPEED_1000M);
      T_RX_IP(IP_PROTO_UDP,SMAC,DMAC,SIP,DIP,40,UDP_SRC_PORT,UDP_DST_PORT,ICMP_ECHO_REQUEST);
      
      T_LINK_UP(50,SPEED_1000M);
      T_RX_IP(IP_PROTO_UDP,SMAC,DMAC,SIP,DIP,40,UDP_SRC_PORT,UDP_DST_PORT,ICMP_ECHO_REPLY);
      
      T_LINK_UP(100,SPEED_1000M);
      T_LINK_DOWM(5);


      // T_LINK_UP(5,SPEED_1000M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);
      // T_LINK_UP(5,SPEED_1000M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);

      // T_LINK_UP(5,SPEED_100M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);
      // T_LINK_UP(5,SPEED_100M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);

      // T_LINK_UP(5,SPEED_10M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);
      // T_LINK_UP(5,SPEED_10M);
      // T_RX_DATA(10,8'h5A);
      // T_RX_ERR_DATA(10,8'hAF);
      // T_RX_DATA(10,8'h5A);
      // T_LINK_DOWM(5);

      #1000;
      $stop;
    end
//***************************    Task    ***************************
  task T_LINK_DOWM;
    input integer keep_time;
    begin
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = 4'b1100;
        end
    end
  endtask
  task T_LINK_UP;
    input integer keep_time;
    input [1:0]   speed_status;
    begin
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = {1'b1,speed_status,1'b1};
        end
    end
  endtask
  task T_RX_DATA;
    input integer keep_time;
    input [7:0]   rx_data;
    reg   [7:0]   rx_data_ff;
    begin
      rx_data_ff = rx_data;
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[3:0];
          @(negedge rgmii_rxc)
            rgmii_rx_ctl = 0;
            rgmii_rxd = rx_data_ff[7:4];
            rx_data_ff = rx_data_ff + 1;
        end
    end
  endtask
  task T_RX_ERR_DATA;
    input integer keep_time;
    input [7:0]   rx_data;
    reg   [7:0]   rx_data_ff;
    begin
      rx_data_ff = rx_data;
      repeat(keep_time)
        begin
          @(posedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[3:0];
          @(negedge rgmii_rxc)
            rgmii_rx_ctl = 1;
            rgmii_rxd = rx_data_ff[7:4];
            rx_data_ff = rx_data_ff + 1;
        end
    end
  endtask
  task T_RX_ARP;
    input [15:0]  arp_opcode;
    input [47:0]  src_mac;
    input [31:0]  src_ip;
    input [31:0]  dst_ip;
    reg   [31:0]  crc32_result;
    reg   [47:0]  dst_mac;
    begin
      crc32_result = {32{1'b1}};
      dst_mac = {48{1'b1}};

      // Preamble
      repeat(7) begin @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; end
      // SFD
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'hD;
      // MAC DA
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[47:44]; crc32_result = CRC32(crc32_result, dst_mac[47:40]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[39:36]; crc32_result = CRC32(crc32_result, dst_mac[39:32]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[31:28]; crc32_result = CRC32(crc32_result, dst_mac[31:24]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[23:20]; crc32_result = CRC32(crc32_result, dst_mac[23:16]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[15:12]; crc32_result = CRC32(crc32_result, dst_mac[15:8]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[7:4];   crc32_result = CRC32(crc32_result, dst_mac[7:0]);
      // MAC SA
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[47:44]; crc32_result = CRC32(crc32_result, src_mac[47:40]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[39:36]; crc32_result = CRC32(crc32_result, src_mac[39:32]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[31:28]; crc32_result = CRC32(crc32_result, src_mac[31:24]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[23:20]; crc32_result = CRC32(crc32_result, src_mac[23:16]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[15:12]; crc32_result = CRC32(crc32_result, src_mac[15:8]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[7:4];   crc32_result = CRC32(crc32_result, src_mac[7:0]);
      // EtherType
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h8; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h08);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h6; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h06);
      // ARP
        // Hardware Type
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h1; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h01);
        // Protocol Type
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h8; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h08);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        // Hardware Address Length
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h6; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h06);
        // Protocol Address Length
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h4; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h04);
        // Operation Code
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = arp_opcode[11:8]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = arp_opcode[15:12]; crc32_result = CRC32(crc32_result, arp_opcode[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = arp_opcode[3:0];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = arp_opcode[7:4]; crc32_result = CRC32(crc32_result, arp_opcode[7:0]);
        // Sender Hardware Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[47:44]; crc32_result = CRC32(crc32_result, src_mac[47:40]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[39:36]; crc32_result = CRC32(crc32_result, src_mac[39:32]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[31:28]; crc32_result = CRC32(crc32_result, src_mac[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[23:20]; crc32_result = CRC32(crc32_result, src_mac[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[15:12]; crc32_result = CRC32(crc32_result, src_mac[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[7:4];   crc32_result = CRC32(crc32_result, src_mac[7:0]);
        // Sender Protocol Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[27:24];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[31:28];  crc32_result = CRC32(crc32_result, src_ip[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[19:16];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[23:20];  crc32_result = CRC32(crc32_result, src_ip[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[11:8];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[15:12];  crc32_result = CRC32(crc32_result, src_ip[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[3:0];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[7:4];    crc32_result = CRC32(crc32_result, src_ip[7:0]);
        // Target Hardware Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[47:44]; crc32_result = CRC32(crc32_result, dst_mac[47:40]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[39:36]; crc32_result = CRC32(crc32_result, dst_mac[39:32]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[31:28]; crc32_result = CRC32(crc32_result, dst_mac[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[23:20]; crc32_result = CRC32(crc32_result, dst_mac[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[15:12]; crc32_result = CRC32(crc32_result, dst_mac[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[7:4];   crc32_result = CRC32(crc32_result, dst_mac[7:0]);
        // Target Protocol Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[27:24];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[31:28];  crc32_result = CRC32(crc32_result, dst_ip[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[19:16];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[23:20];  crc32_result = CRC32(crc32_result, dst_ip[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[11:8];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[15:12];  crc32_result = CRC32(crc32_result, dst_ip[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[3:0];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[7:4];    crc32_result = CRC32(crc32_result, dst_ip[7:0]);
        // Stuff Data
        repeat(18) begin  @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00); end
        // CRC
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[31:28];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[23:20];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[15:12];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[7:4];
    end
  endtask
  task T_RX_IP;
    input [7:0]   ip_type;
    input [47:0]  src_mac;
    input [47:0]  dst_mac;
    input [31:0]  src_ip;
    input [31:0]  dst_ip;
    input [15:0]  ip_total_len;
    input [15:0]  udp_src_port;
    input [15:0]  udp_dst_port;
    input [7:0]   icmp_type;
    reg   [31:0]  crc32_result;
    reg   [15:0]  ip_data_len;
    reg   [31:0]  ip_checksum;
    reg   [31:0]  icmp_checksum;
    reg   [31:0]  udp_checksum;
    integer       i;
    begin
      i = 0;
      crc32_result = {32{1'b1}};
      ip_data_len = ip_total_len - 20;
      // Preamble
      repeat(7) begin @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; end
      // SFD
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'hD;
      // MAC DA
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[47:44]; crc32_result = CRC32(crc32_result, dst_mac[47:40]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[39:36]; crc32_result = CRC32(crc32_result, dst_mac[39:32]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[31:28]; crc32_result = CRC32(crc32_result, dst_mac[31:24]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[23:20]; crc32_result = CRC32(crc32_result, dst_mac[23:16]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[15:12]; crc32_result = CRC32(crc32_result, dst_mac[15:8]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_mac[7:4];   crc32_result = CRC32(crc32_result, dst_mac[7:0]);
      // MAC SA
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[43:40]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[47:44]; crc32_result = CRC32(crc32_result, src_mac[47:40]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[35:32]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[39:36]; crc32_result = CRC32(crc32_result, src_mac[39:32]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[31:28]; crc32_result = CRC32(crc32_result, src_mac[31:24]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[23:20]; crc32_result = CRC32(crc32_result, src_mac[23:16]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[15:12]; crc32_result = CRC32(crc32_result, src_mac[15:8]);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_mac[7:4];   crc32_result = CRC32(crc32_result, src_mac[7:0]);
      // EtherType
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h8; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h08);
      @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
      // IP
        // IP Version
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h5; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h4; crc32_result = CRC32(crc32_result, 8'h45);
        // IP Service
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        // IP Total Length
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_total_len[11:8]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_total_len[15:12]; crc32_result = CRC32(crc32_result, ip_total_len[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_total_len[3:0];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_total_len[7:4];  crc32_result = CRC32(crc32_result, ip_total_len[7:0]);
        // IP Identification
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        // IP Flags & IP Fragment Offset
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h4; crc32_result = CRC32(crc32_result, 8'h40);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
        // IP TTL
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h4; crc32_result = CRC32(crc32_result, 8'h40);
        // IP Protocol
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_type[3:0];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_type[7:4];  crc32_result = CRC32(crc32_result, ip_type);
        // IP Header Checksum
        ip_checksum = 16'h4500 + ip_total_len + 16'h0000 + 16'h4000 + {8'h40, ip_type} + src_ip[31:16] + src_ip[15:0] + dst_ip[31:16] + dst_ip[15:0];
        ip_checksum = ip_checksum[31:16] + ip_checksum[15:0];
        ip_checksum = ~ip_checksum;
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_checksum[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_checksum[15:12]; crc32_result = CRC32(crc32_result, ip_checksum[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_checksum[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_checksum[7:4];   crc32_result = CRC32(crc32_result, ip_checksum[7:0]);
        // IP Source Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[27:24];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[31:28];  crc32_result = CRC32(crc32_result, src_ip[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[19:16];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[23:20];  crc32_result = CRC32(crc32_result, src_ip[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[11:8];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[15:12];  crc32_result = CRC32(crc32_result, src_ip[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[3:0];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = src_ip[7:4];    crc32_result = CRC32(crc32_result, src_ip[7:0]);
        // IP Destination Address
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[27:24];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[31:28];  crc32_result = CRC32(crc32_result, dst_ip[31:24]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[19:16];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[23:20];  crc32_result = CRC32(crc32_result, dst_ip[23:16]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[11:8];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[15:12];  crc32_result = CRC32(crc32_result, dst_ip[15:8]);
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[3:0];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = dst_ip[7:4];    crc32_result = CRC32(crc32_result, dst_ip[7:0]);
        // IP Payload
        if (ip_type == IP_PROTO_ICMP)
          begin
            // ICMP Type
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_type[3:0]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_type[7:4]; crc32_result = CRC32(crc32_result, icmp_type);
            // ICMP Code
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00);
            // ICMP Checksum
            icmp_checksum = {16'h0,icmp_type,8'h0};
            for (i = 0; i < (ip_data_len-4); i=i+1)
              begin
                if (i[0] == 0)
                  icmp_checksum = icmp_checksum + {i[7:0],8'h0};
                else
                  icmp_checksum = icmp_checksum + {8'h0,i[7:0]};
              end
            icmp_checksum = icmp_checksum[31:16] + icmp_checksum[15:0];
            icmp_checksum = ~icmp_checksum;
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_checksum[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_checksum[15:12]; crc32_result = CRC32(crc32_result, icmp_checksum[15:8]);
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_checksum[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = icmp_checksum[7:4];   crc32_result = CRC32(crc32_result, icmp_checksum[7:0]);
            // ICMP Payload
            for (i = 0; i < (ip_data_len-4); i=i+1)
              begin
                @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = i[3:0]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = i[7:4]; crc32_result = CRC32(crc32_result, i[7:0]);
              end
          end
        else if (ip_type == IP_PROTO_UDP)
          begin
            // UDP Source Port
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_src_port[11:8]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_src_port[15:12]; crc32_result = CRC32(crc32_result, udp_src_port[15:8]);
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_src_port[3:0];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_src_port[7:4];  crc32_result = CRC32(crc32_result, udp_src_port[7:0]);
            // UDP Destination Port
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_dst_port[11:8]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_dst_port[15:12]; crc32_result = CRC32(crc32_result, udp_dst_port[15:8]);
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_dst_port[3:0];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_dst_port[7:4];  crc32_result = CRC32(crc32_result, udp_dst_port[7:0]);
            // UDP Length
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_data_len[11:8];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_data_len[15:12]; crc32_result = CRC32(crc32_result, ip_data_len[15:8]);
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_data_len[3:0];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = ip_data_len[7:4];  crc32_result = CRC32(crc32_result, ip_data_len[7:0]);
            // UDP Checksum
            udp_checksum = src_ip[31:16] + src_ip[15:0] + dst_ip[31:16] + dst_ip[15:0] + {ip_type,8'h0} + ip_data_len;
            udp_checksum = udp_checksum + udp_src_port + udp_dst_port + ip_data_len;
            for (i = 0; i < (ip_data_len-8); i=i+1)
              begin
                if (i[0] == 0)
                  udp_checksum = udp_checksum + {i[7:0],8'h0};
                else
                  udp_checksum = udp_checksum + {8'h0,i[7:0]};
              end
            udp_checksum = udp_checksum[31:16] + udp_checksum[15:0];
            udp_checksum = ~udp_checksum;
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_checksum[11:8];    @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_checksum[15:12]; crc32_result = CRC32(crc32_result, udp_checksum[15:8]);
            @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_checksum[3:0];     @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = udp_checksum[7:4];  crc32_result = CRC32(crc32_result, udp_checksum[7:0]);
            // UDP Payload
            for (i = 0; i < (ip_data_len-8); i=i+1)
              begin
                @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = i[3:0]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = i[7:4]; crc32_result = CRC32(crc32_result, i[7:0]);
              end
          end
          // Stuff Data
          if (ip_data_len < 26) repeat(26-ip_data_len) begin @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = 4'h0; crc32_result = CRC32(crc32_result, 8'h00); end
        // CRC
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[27:24]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[31:28];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[19:16]; @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[23:20];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[11:8];  @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[15:12];
        @(posedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[3:0];   @(negedge rgmii_rxc) rgmii_rx_ctl = 1;  rgmii_rxd = crc32_result[7:4];
    end
  endtask

//***************************    Function      ***************************
function [31:0] CRC32;
  input [7:0] din;
  input [31:0] crc32_next;
  reg   [7:0] data;
  begin
    data = {din[0],din[1],din[2],din[3],din[4],din[5],din[6],din[7]};

    CRC32[0]  = crc32_next[24] ^ crc32_next[30] ^ data[0] ^ data[6];
    CRC32[1]  = crc32_next[24] ^ crc32_next[25] ^ crc32_next[30] ^ crc32_next[31] ^ data[0] ^ data[1] ^ data[6] ^ data[7];
    CRC32[2]  = crc32_next[24] ^ crc32_next[25] ^ crc32_next[26] ^ crc32_next[30] ^ crc32_next[31] ^ data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[7];
    CRC32[3]  = crc32_next[25] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[31] ^ data[1] ^ data[2] ^ data[3] ^ data[7];
    CRC32[4]  = crc32_next[24] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[28] ^ crc32_next[30] ^ data[0] ^ data[2] ^ data[3] ^ data[4] ^ data[6];
    CRC32[5]  = crc32_next[24] ^ crc32_next[25] ^ crc32_next[27] ^ crc32_next[28] ^ crc32_next[29] ^ crc32_next[30] ^ crc32_next[31] ^ data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
    CRC32[6]  = crc32_next[25] ^ crc32_next[26] ^ crc32_next[28] ^ crc32_next[29] ^ crc32_next[30] ^ crc32_next[31] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
    CRC32[7]  = crc32_next[24] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[29] ^ crc32_next[31] ^ data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[7];
    CRC32[8]  = crc32_next[0] ^ crc32_next[24] ^ crc32_next[25] ^ crc32_next[27] ^ crc32_next[28] ^ data[0] ^ data[1] ^ data[3] ^ data[4];
    CRC32[9]  = crc32_next[1] ^ crc32_next[25] ^ crc32_next[26] ^ crc32_next[28] ^ crc32_next[29] ^ data[1] ^ data[2] ^ data[4] ^ data[5];
    CRC32[10] = crc32_next[2] ^ crc32_next[24] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[29] ^ data[0] ^ data[2] ^ data[3] ^ data[5];
    CRC32[11] = crc32_next[3] ^ crc32_next[24] ^ crc32_next[25] ^ crc32_next[27] ^ crc32_next[28] ^ data[0] ^ data[1] ^ data[3] ^ data[4];
    CRC32[12] = crc32_next[4] ^ crc32_next[24] ^ crc32_next[25] ^ crc32_next[26] ^ crc32_next[28] ^ crc32_next[29] ^ crc32_next[30] ^ data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6];
    CRC32[13] = crc32_next[5] ^ crc32_next[25] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[29] ^ crc32_next[30] ^ crc32_next[31] ^ data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7];
    CRC32[14] = crc32_next[6] ^ crc32_next[26] ^ crc32_next[27] ^ crc32_next[28] ^ crc32_next[30] ^ crc32_next[31] ^ data[2] ^ data[3] ^ data[4] ^ data[6] ^ data[7];
    CRC32[15] = crc32_next[7] ^ crc32_next[27] ^ crc32_next[28] ^ crc32_next[29] ^ crc32_next[31] ^ data[3] ^ data[4] ^ data[5] ^ data[7];
    CRC32[16] = crc32_next[8] ^ crc32_next[24] ^ crc32_next[28] ^ crc32_next[29] ^ data[0] ^ data[4] ^ data[5];
    CRC32[17] = crc32_next[9] ^ crc32_next[25] ^ crc32_next[29] ^ crc32_next[30] ^ data[1] ^ data[5] ^ data[6];
    CRC32[18] = crc32_next[10] ^ crc32_next[26] ^ crc32_next[30] ^ crc32_next[31] ^ data[2] ^ data[6] ^ data[7];
    CRC32[19] = crc32_next[11] ^ crc32_next[27] ^ crc32_next[31] ^ data[3] ^ data[7];
    CRC32[20] = crc32_next[12] ^ crc32_next[28] ^ data[4];
    CRC32[21] = crc32_next[13] ^ crc32_next[29] ^ data[5];
    CRC32[22] = crc32_next[14] ^ crc32_next[24] ^ data[0];
    CRC32[23] = crc32_next[15] ^ crc32_next[24] ^ crc32_next[25] ^ crc32_next[30] ^ data[0] ^ data[1] ^ data[6];
    CRC32[24] = crc32_next[16] ^ crc32_next[25] ^ crc32_next[26] ^ crc32_next[31] ^ data[1] ^ data[2] ^ data[7];
    CRC32[25] = crc32_next[17] ^ crc32_next[26] ^ crc32_next[27] ^ data[2] ^ data[3];
    CRC32[26] = crc32_next[18] ^ crc32_next[24] ^ crc32_next[27] ^ crc32_next[28] ^ crc32_next[30] ^ data[0] ^ data[3] ^ data[4] ^ data[6];
    CRC32[27] = crc32_next[19] ^ crc32_next[25] ^ crc32_next[28] ^ crc32_next[29] ^ crc32_next[31] ^ data[1] ^ data[4] ^ data[5] ^ data[7];
    CRC32[28] = crc32_next[20] ^ crc32_next[26] ^ crc32_next[29] ^ crc32_next[30] ^ data[2] ^ data[5] ^ data[6];
    CRC32[29] = crc32_next[21] ^ crc32_next[27] ^ crc32_next[30] ^ crc32_next[31] ^ data[3] ^ data[6] ^ data[7];
    CRC32[30] = crc32_next[22] ^ crc32_next[28] ^ crc32_next[31] ^ data[4] ^ data[7];
    CRC32[31] = crc32_next[23] ^ crc32_next[29] ^ data[5];
  end
endfunction
//***************************  Instance  ***************************
// 三速以太网MAC模块
  tri_mode_ethernet_mac #(
    // 帧过滤使能, 与本地MAC地址不一致过滤
    .C_FILTER_EN   (C_FILTER_EN),
    // 本地MAC地址
    .C_LOCAL_MAC   (C_LOCAL_MAC),
    // 接收超时时间(unit: rx_mac_aclk)
    .C_TIMEOUT     (C_TIMEOUT),
    // 帧间隔(Unit: bit time, 8整倍数)
    .C_IFG         (C_IFG)
  )u_ethernet(
    .clk_125mhz           (clk_125mhz),
    .clk90_125mhz         (clk90_125mhz),
    .reset                (reset),
    .reset90              (reset90),
    // PHY 芯片状态指示
    .inband_link_status   (), // up(1), down(0)
    .inband_clock_speed   (), // 125MHz(10), 2.5MHz(01), 2.5MHz(00), reserved(11)
    .inband_duplex_status (), // half-duplex(0), full-duplex(1)
    // RGMII_RX
    .rgmii_rxc            (rgmii_rxc),
    .rgmii_rx_ctl         (rgmii_rx_ctl),
    .rgmii_rxd            (rgmii_rxd),
    // RGMII_TX
    .rgmii_txc            (),
    .rgmii_tx_ctl         (),
    .rgmii_txd            (),
    // 用户接收数据 AXIS 接口
    .rx_mac_aclk          (),
    .rx_mac_reset         (),
    .rx_axis_mac_tdata    (),
    .rx_axis_mac_tvalid   (),
    .rx_axis_mac_tlast    (),
    .rx_axis_mac_tuser    (),
    // 用户发送数据 AXIS 接口
    .tx_mac_aclk          (tx_mac_aclk),
    .tx_mac_reset         (tx_mac_reset),
    .tx_axis_mac_tvalid   (tx_axis_mac_tvalid),
    .tx_axis_mac_tdata    (tx_axis_mac_tdata),
    .tx_axis_mac_tlast    (tx_axis_mac_tlast),
    .tx_axis_mac_tready   (tx_axis_mac_tready)
  );


endmodule
