// 封装 xpm_fifo_axis

module axis_data_fifo #(
  parameter  CDC_SYNC_STAGES = 2, // 2-8
  parameter  CLOCKING_MODE = "common_clock", // common_clock, independent_clock
  parameter  FIFO_DEPTH = 2048, // 16-4194304
  parameter  FIFO_MEMORY_TYPE = "auto", // auto, block, distributed, ultra
  parameter  PACKET_FIFO = "false", // false, true
  parameter  PROG_FULL_THRESH = 10, // Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted, Max_Value = FIFO_DEPTH - 5, Min_Value = 5 + CDC_SYNC_STAGES
  parameter  RELATED_CLOCKS = 0, // Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.
  parameter  TDATA_WIDTH = 0, // 8-2048
  parameter  TDEST_WIDTH = 0, // 1-32
  parameter  TID_WIDTH = 0, // 1-32
  parameter  TUSER_WIDTH = 0 // 1-4096
)(
  input                       s_aclk,
  input                       s_aresetn,
  input  [TDATA_WIDTH-1:0]    s_axis_tdata,
  input  [TDEST_WIDTH-1:0]    s_axis_tdest,
  input  [TID_WIDTH-1:0]      s_axis_tid,
  input  [TDATA_WIDTH/8-1:0]  s_axis_tkeep,
  input                       s_axis_tlast,
  input  [TDATA_WIDTH/8-1:0]  s_axis_tstrb,
  input  [TUSER_WIDTH-1:0]    s_axis_tuser,
  input                       s_axis_tvalid,
  output                      s_axis_tready,
  output                      almost_full_axis,

  input                       m_aclk,
  output [TDATA_WIDTH-1:0]    m_axis_tdata,
  output [TDEST_WIDTH-1:0]    m_axis_tdest,
  output [TID_WIDTH-1:0]      m_axis_tid,
  output [TDATA_WIDTH/8-1:0]  m_axis_tkeep,
  output                      m_axis_tlast,
  output [TDATA_WIDTH/8-1:0]  m_axis_tstrb,
  output [TUSER_WIDTH-1:0]    m_axis_tuser,
  output                      m_axis_tvalid,
  input                       m_axis_tready
);

//------------------------------------
//             Local Parameter
//------------------------------------
  localparam RD_DATA_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1; // log2(FIFO_DEPTH)+1

//------------------------------------
//             Local Signal
//------------------------------------
  wire almost_empty_axis;
  wire dbiterr_axis;
  wire prog_empty_axis;
  wire prog_full_axis;
  wire [RD_DATA_COUNT_WIDTH-1:0] rd_data_count_axis;
  wire sbiterr_axis;
  wire [RD_DATA_COUNT_WIDTH-1:0] wr_data_count_axis;
  wire injectdbiterr_axis;
  wire injectsbiterr_axis;

//------------------------------------
//             User Logic
//------------------------------------

//------------------------------------
//             Instance
//------------------------------------
  // xpm_fifo_axis: AXI Stream FIFO
  // Xilinx Parameterized Macro, version 2025.1

  xpm_fifo_axis #(
    .CASCADE_HEIGHT(0),             // DECIMAL
    .CDC_SYNC_STAGES(CDC_SYNC_STAGES),            // DECIMAL
    .CLOCKING_MODE(CLOCKING_MODE), // String,
    .ECC_MODE("no_ecc"),            // String
    .EN_SIM_ASSERT_ERR("warning"),  // String
    .FIFO_DEPTH(FIFO_DEPTH),              // DECIMAL
    .FIFO_MEMORY_TYPE(FIFO_MEMORY_TYPE),      // String
    .PACKET_FIFO(PACKET_FIFO),          // String
    .PROG_EMPTY_THRESH(5),         // DECIMAL
    .PROG_FULL_THRESH(PROG_FULL_THRESH),          // DECIMAL
    .RD_DATA_COUNT_WIDTH(RD_DATA_COUNT_WIDTH),        // DECIMAL
    .RELATED_CLOCKS(RELATED_CLOCKS),             // DECIMAL
    .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .TDATA_WIDTH(TDATA_WIDTH),               // DECIMAL
    .TDEST_WIDTH(TDEST_WIDTH),                // DECIMAL
    .TID_WIDTH(TID_WIDTH),                  // DECIMAL
    .TUSER_WIDTH(TUSER_WIDTH),                // DECIMAL
    .USE_ADV_FEATURES("1000"),      // String
    .WR_DATA_COUNT_WIDTH(RD_DATA_COUNT_WIDTH)         // DECIMAL
  )
  xpm_fifo_axis_inst (
    .almost_empty_axis(almost_empty_axis),   // 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be
                                              // performed before the FIFO goes to empty.

    .almost_full_axis(almost_full_axis),     // 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be
                                              // performed before the FIFO is full.

    .dbiterr_axis(dbiterr_axis),             // 1-bit output: Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data
                                              // in the FIFO core is corrupted.

    .m_axis_tdata(m_axis_tdata),             // TDATA_WIDTH-bit output: TDATA: The primary payload that is used to provide the data that is passing
                                              // across the interface. The width of the data payload is an integer number of bytes.

    .m_axis_tdest(m_axis_tdest),             // TDEST_WIDTH-bit output: TDEST: Provides routing information for the data stream.
    .m_axis_tid(m_axis_tid),                 // TID_WIDTH-bit output: TID: The data stream identifier that indicates different streams of data.
    .m_axis_tkeep(m_axis_tkeep),             // TDATA_WIDTH/8-bit output: TKEEP: The byte qualifier that indicates whether the content of the
                                              // associated byte of TDATA is processed as part of the data stream. Associated bytes that have the
                                              // TKEEP byte qualifier deasserted are null bytes and can be removed from the data stream. For a
                                              // 64-bit DATA, bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the
                                              // most significant byte. For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                              // DATA[63:56] is a NULL byte

    .m_axis_tlast(m_axis_tlast),             // 1-bit output: TLAST: Indicates the boundary of a packet.
    .m_axis_tstrb(m_axis_tstrb),             // TDATA_WIDTH/8-bit output: TSTRB: The byte qualifier that indicates whether the content of the
                                              // associated byte of TDATA is processed as a data byte or a position byte. For a 64-bit DATA, bit 0
                                              // corresponds to the least significant byte on DATA, and bit 0 corresponds to the least significant
                                              // byte on DATA, and bit 7 corresponds to the most significant byte. For example: STROBE[0] = 1b,
                                              // DATA[7:0] is valid STROBE[7] = 0b, DATA[63:56] is not valid

    .m_axis_tuser(m_axis_tuser),             // TUSER_WIDTH-bit output: TUSER: The user-defined sideband information that can be transmitted
                                              // alongside the data stream.

    .m_axis_tvalid(m_axis_tvalid),           // 1-bit output: TVALID: Indicates that the master is driving a valid transfer. A transfer takes place
                                              // when both TVALID and TREADY are asserted

    .prog_empty_axis(prog_empty_axis),       // 1-bit output: Programmable Empty- This signal is asserted when the number of words in the FIFO is
                                              // less than or equal to the programmable empty threshold value. It is de-asserted when the number of
                                              // words in the FIFO exceeds the programmable empty threshold value.

    .prog_full_axis(prog_full_axis),         // 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is
                                              // greater than or equal to the programmable full threshold value. It is de-asserted when the number
                                              // of words in the FIFO is less than the programmable full threshold value.

    .rd_data_count_axis(rd_data_count_axis), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count- This bus indicates the number of words available
                                              // for reading in the FIFO.

    .s_axis_tready(s_axis_tready),           // 1-bit output: TREADY: Indicates that the slave can accept a transfer in the current cycle.
    .sbiterr_axis(sbiterr_axis),             // 1-bit output: Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit
                                              // error.

    .wr_data_count_axis(wr_data_count_axis), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written
                                              // into the FIFO.

    .injectdbiterr_axis(injectdbiterr_axis), // 1-bit input: Double Bit Error Injection- Injects a double bit error if the ECC feature is used.
    .injectsbiterr_axis(injectsbiterr_axis), // 1-bit input: Single Bit Error Injection- Injects a single bit error if the ECC feature is used.
    .m_aclk(m_aclk),                         // 1-bit input: Master Interface Clock: All signals on master interface are sampled on the rising edge
                                              // of this clock.

    .m_axis_tready(m_axis_tready),           // 1-bit input: TREADY: Indicates that the slave can accept a transfer in the current cycle.
    .s_aclk(s_aclk),                         // 1-bit input: Slave Interface Clock: All signals on slave interface are sampled on the rising edge
                                              // of this clock.

    .s_aresetn(s_aresetn),                   // 1-bit input: Active low asynchronous reset.
    .s_axis_tdata(s_axis_tdata),             // TDATA_WIDTH-bit input: TDATA: The primary payload that is used to provide the data that is passing
                                              // across the interface. The width of the data payload is an integer number of bytes.

    .s_axis_tdest(s_axis_tdest),             // TDEST_WIDTH-bit input: TDEST: Provides routing information for the data stream.
    .s_axis_tid(s_axis_tid),                 // TID_WIDTH-bit input: TID: The data stream identifier that indicates different streams of data.
    .s_axis_tkeep(s_axis_tkeep),             // TDATA_WIDTH/8-bit input: TKEEP: The byte qualifier that indicates whether the content of the
                                              // associated byte of TDATA is processed as part of the data stream. Associated bytes that have the
                                              // TKEEP byte qualifier deasserted are null bytes and can be removed from the data stream. For a
                                              // 64-bit DATA, bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the
                                              // most significant byte. For example: KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                              // DATA[63:56] is a NULL byte

    .s_axis_tlast(s_axis_tlast),             // 1-bit input: TLAST: Indicates the boundary of a packet.
    .s_axis_tstrb(s_axis_tstrb),             // TDATA_WIDTH/8-bit input: TSTRB: The byte qualifier that indicates whether the content of the
                                              // associated byte of TDATA is processed as a data byte or a position byte. For a 64-bit DATA, bit 0
                                              // corresponds to the least significant byte on DATA, and bit 0 corresponds to the least significant
                                              // byte on DATA, and bit 7 corresponds to the most significant byte. For example: STROBE[0] = 1b,
                                              // DATA[7:0] is valid STROBE[7] = 0b, DATA[63:56] is not valid

    .s_axis_tuser(s_axis_tuser),             // TUSER_WIDTH-bit input: TUSER: The user-defined sideband information that can be transmitted
                                              // alongside the data stream.

    .s_axis_tvalid(s_axis_tvalid)            // 1-bit input: TVALID: Indicates that the master is driving a valid transfer. A transfer takes place
                                              // when both TVALID and TREADY are asserted

  );

  // End of xpm_fifo_axis_inst instantiation

endmodule