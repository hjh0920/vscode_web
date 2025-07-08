// ICMP报文处理模块

module icmp_process(
  // 接收 IP 数据
  input         rx_mac_aclk,
  input         rx_mac_reset,
  input  [7:0]  rx_axis_ip_tdata,
  input         rx_axis_ip_tvalid,
  input         rx_axis_ip_tlast,
  input  [1:0]  rx_axis_ip_tuser, // [0]: MAC error, [1]: IP error
  input         rx_axis_ip_tdest, // 0: UDP, 1: ICMP
  // 接收 IP 数据
  input         tx_mac_aclk,
  input         tx_mac_reset,
  output [31:0] tx_axis_icmp_tdata,
  output        tx_axis_icmp_tvalid,
  output        tx_axis_icmp_tlast,
  input         tx_axis_icmp_tready
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [7:0]  rx_axis_ip_tdata_d1 = 0; // 打拍, 用于数据解析
  reg  [7:0]  rx_axis_ip_tdata_d2 = 0;
  reg         rx_axis_ip_tvalid_d1 = 0; // 打拍
  reg         rx_axis_ip_tlast_d1 = 0;
  reg         rx_axis_ip_tdest_d1 = 0;
  reg         rx_axis_ip_tvalid_d2 = 0; // 打拍
  reg         rx_axis_ip_tlast_d2 = 0;
  reg         rx_axis_ip_tdest_d2 = 0;
  reg  [10:0] rx_byte_cnt = 0; // 接收字节计数器
  reg  [7:0]  rx_icmp_type = 0; // 接收 ICMP 报文类型
  reg  [15:0] rx_icmp_cksum = 0; // 接收 ICMP 报文校验和
  reg  [25:0] rx_icmp_csum_calc = 0; // 计算接收 ICMP 报文校验和
  reg  [25:0] rx_icmp_csum_calc_1 = 0;
  reg  [15:0] rx_icmp_csum_result = 0; // 计算得到的接收 ICMP 报文校验和
  reg  [25:0] tx_icmp_csum_calc = 0; // 计算发送 ICMP 报文校验和
  reg  [25:0] tx_icmp_csum_calc_1 = 0;
  reg  [15:0] tx_icmp_csum_result = 0; // 计算得到的发送 ICMP 报文校验和

  reg         icmp_sdpram_wea = 0; // RAM写使能
  reg  [10:0] icmp_sdpram_addra = 0; // RAM写地址
  reg  [7:0]  icmp_sdpram_dina = 0; // RAM写数据
  reg  [8:0]  icmp_sdpram_addrb = 0; // RAM读地址
  reg  [31:0] icmp_sdpram_doutb = 0; // RAM读数据

//------------------------------------
//             User Logic
//------------------------------------
// ICMP Receive
  // 打拍, 用于数据解析
    always @ (posedge rx_mac_aclk)
      if (rx_axis_ip_tvalid)
        begin
          rx_axis_ip_tdata_d1 <= rx_axis_ip_tdata;
          rx_axis_ip_tdata_d2 <= rx_axis_ip_tdata_d1;
        end
  // 打拍
    always @ (posedge rx_mac_aclk) rx_axis_ip_tvalid_d1 <= rx_axis_ip_tvalid;
    always @ (posedge rx_mac_aclk) rx_axis_ip_tlast_d1 <= rx_axis_ip_tlast;
    always @ (posedge rx_mac_aclk) rx_axis_ip_tdest_d1 <= rx_axis_ip_tdest;
    always @ (posedge rx_mac_aclk) rx_axis_ip_tvalid_d2 <= rx_axis_ip_tvalid_d1;
    always @ (posedge rx_mac_aclk) rx_axis_ip_tlast_d2 <= rx_axis_ip_tlast_d1;
    always @ (posedge rx_mac_aclk) rx_axis_ip_tdest_d2 <= rx_axis_ip_tdest_d1;
  // 接收字节计数器
    always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
      if (rx_mac_reset)
        rx_byte_cnt <= 11'b0;
      else if (rx_axis_ip_tvalid && rx_axis_ip_tlast && rx_axis_ip_tdest)
        rx_byte_cnt <= 11'b0;
      else if (rx_axis_ip_tvalid && rx_axis_ip_tdest)
        rx_byte_cnt <= rx_byte_cnt + 11'b1;
  // 接收 ICMP 报文类型
    always @ (posedge rx_mac_aclk)
      if (rx_byte_cnt == 11'd1) rx_icmp_type <= rx_axis_ip_tdata_d1;
  // 接收 ICMP 报文校验和
    always @ (posedge rx_mac_aclk)
      if (rx_byte_cnt == 11'd4) rx_icmp_cksum <= {rx_axis_ip_tdata_d2,rx_axis_ip_tdata_d1};
  // 计算接收 ICMP 报文校验和
    always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
      if (rx_mac_reset)
        rx_icmp_csum_calc <= 26'b0;
      else if (rx_axis_ip_tvalid_d1 && rx_axis_ip_tlast_d1)
        rx_icmp_csum_calc <= 26'b0;
      else if (rx_axis_ip_tvalid && rx_axis_ip_tdest && (rx_byte_cnt[10:1] != 10'd1))
        begin
          if (rx_byte_cnt[0])
            rx_icmp_csum_calc <= rx_icmp_csum_calc + {18'b0,rx_axis_ip_tdata};
          else
            rx_icmp_csum_calc <= rx_icmp_csum_calc + {10'b0,rx_axis_ip_tdata,8'b0};
        end
    always @ (posedge rx_mac_aclk)
      if (rx_axis_ip_tvalid_d1 && rx_axis_ip_tlast_d1)
        rx_icmp_csum_calc_1 <= {10'b0,rx_icmp_csum_calc[15:0]} + {16'b0,rx_icmp_csum_calc[25:16]};
  // 计算得到的接收 ICMP 报文校验和
    always @ (posedge rx_mac_aclk)
      rx_icmp_csum_result <= ~(rx_icmp_csum_calc_1[15:0] + {6'b0,rx_icmp_csum_calc_1[25:16]});
  // RAM写使能
    always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
      if (rx_mac_reset)
        icmp_sdpram_wea <= 1'b0;
      else if (rx_axis_ip_tvalid && rx_axis_ip_tdest)
        icmp_sdpram_wea <= 1'b1;
      else
        icmp_sdpram_wea <= 1'b0;
  // RAM写地址
    always @ (posedge rx_mac_aclk or posedge rx_mac_reset)
      if (rx_mac_reset)
        icmp_sdpram_addra <= 11'b0;
      else if (rx_axis_ip_tvalid_d1 && rx_axis_ip_tlast_d1 && rx_axis_ip_tdest_d1)
        icmp_sdpram_addra <= 11'b0;
      else if (rx_axis_ip_tvalid_d1 && rx_axis_ip_tdest_d1)
        icmp_sdpram_addra <= icmp_sdpram_addra + 11'b1;
  // RAM写数据
    always @ (posedge rx_mac_aclk) icmp_sdpram_dina <= rx_axis_mac_tdata;

// ICMP Send

//------------------------------------
//             Output Port
//------------------------------------


//------------------------------------
//             Instance
//------------------------------------
   // xpm_memory_sdpram: Simple Dual Port RAM
   // Xilinx Parameterized Macro, version 2020.1

   xpm_memory_sdpram #(
      .ADDR_WIDTH_A(11),               // DECIMAL
      .ADDR_WIDTH_B(9),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("independent_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(1480),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(32),         // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(8),        // DECIMAL
      .WRITE_MODE_B("read_first")      // String
   )xpm_memory_sdpram_icmp (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(icmp_sdpram_doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(icmp_sdpram_addra),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb(icmp_sdpram_addrb),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(rx_mac_aclk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(tx_mac_aclk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(icmp_sdpram_dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
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

      .rstb(tx_mac_reset),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(icmp_sdpram_wea)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule
