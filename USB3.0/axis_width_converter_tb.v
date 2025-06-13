`timescale 1ns/1ns

`define S2_M2
// `define S2_M4
// `define S4_M2



module axis_width_converter_tb;

//*************************** Parameters ***************************
  parameter integer  PERIOD_ACLK = 10;

`ifdef S2_M2
  parameter interger S_TDATA_WIDTH = 2; // 1-512 (byte)
  parameter interger M_TDATA_WIDTH = 2; // 1-512 (byte)
`elsif S2_M4
  parameter interger S_TDATA_WIDTH = 2; // 1-512 (byte)
  parameter interger M_TDATA_WIDTH = 4; // 1-512 (byte)
`else
  parameter interger S_TDATA_WIDTH = 4; // 1-512 (byte)
  parameter interger M_TDATA_WIDTH = 2; // 1-512 (byte)
`endif

  parameter interger TID_WIDTH = 1; // 0-32 (bit)
  parameter interger TDEST_WIDTH = 1; // 0-32 (bit)
  parameter interger TUSER_WIDTH_PER_BYTE = 1; // 0-2048 (bit)

//***************************   Signals  ***************************
  reg                                           aclk = 0;
  reg                                           aresetn = 0;

  reg                                           s_axis_tvalid = 0;
  wire                                          s_axis_tready;
  reg  [S_TDATA_WIDTH*8-1:0]                    s_axis_tdata = 0;
  reg  [S_TDATA_WIDTH-1:0]                      s_axis_tstrb = 0;
  reg  [S_TDATA_WIDTH-1:0]                      s_axis_tkeep = 0;
  reg                                           s_axis_tlast = 0;
  reg  [TID_WIDTH-1:0]                          s_axis_tid = 0;
  reg  [TDEST_WIDTH-1:0]                        s_axis_tdest = 0;
  reg  [S_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] s_axis_tuser = 0;

  wire                                          m_axis_tvalid;
  reg                                           m_axis_tready = 0;
  wire [M_TDATA_WIDTH*8-1:0]                    m_axis_tdata;
  wire [M_TDATA_WIDTH-1:0]                      m_axis_tstrb;
  wire [M_TDATA_WIDTH-1:0]                      m_axis_tkeep;
  wire                                          m_axis_tlast;
  wire [TID_WIDTH-1:0]                          m_axis_tid;
  wire [TDEST_WIDTH-1:0]                        m_axis_tdest;
  wire [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] m_axis_tuser;

//*************************** Test Logic ***************************
  always # (PERIOD_ACLK/2) aclk = ~aclk;

//***************************    Task    ***************************
  initial
    begin
      repeat(10)@(posedge aclk);
      aresetn = 1;
      repeat(10)@(posedge aclk);

      `ifdef S2_M2
        fork
          begin
            repeat(10)
              begin
                @(posedge aclk);
                  s_axis_tvalid = 1;
                  s_axis_tdata  = 0;
                  s_axis_tstrb  = 2'b11;
                  s_axis_tkeep  = 2'b11;
                  s_axis_tlast  = 0;
                  s_axis_tid    = 0;
                  s_axis_tdest  = 0;
                  s_axis_tuser  = 2'b00;
                wait(s_axis_tready);
                  @(posedge aclk);
                  s_axis_tdata = s_axis_tdata + 1;
              end
            wait(s_axis_tready);
              @(posedge aclk);
              s_axis_tvalid = 1;
              s_axis_tdata = s_axis_tdata + 1;
              s_axis_tstrb  = 2'b10;
              s_axis_tkeep  = 2'b10;
              s_axis_tlast  = 1;
              s_axis_tid    = 0;
              s_axis_tdest  = 0;
              s_axis_tuser  = 2'b10;
            wait(s_axis_tready);
              @(posedge aclk);
              s_axis_tvalid = 0;
          end

          begin
            m_axis_tready = 1;
          end
        join
      `elsif S2_M4

      `else

      `endif

    end


//***************************  Instance  ***************************

// AXI4-Stream整数倍位宽转换模块
  axis_width_converter #(
    .S_TDATA_WIDTH         (S_TDATA_WIDTH), // 1-512 (byte)
    .M_TDATA_WIDTH         (M_TDATA_WIDTH), // 1-512 (byte)
    .TID_WIDTH             (TID_WIDTH), // 0-32 (bit)
    .TDEST_WIDTH           (TDEST_WIDTH), // 0-32 (bit)
    .TUSER_WIDTH_PER_BYTE  (TUSER_WIDTH_PER_BYTE) // 0-2048 (bit)
  ) tx_axis_width_converter(
    .aclk                  (aclk),
    .aresetn               (aresetn),
    .s_axis_tvalid         (s_axis_tvalid),
    .s_axis_tready         (s_axis_tready),
    .s_axis_tdata          (s_axis_tdata),
    .s_axis_tstrb          (s_axis_tstrb),
    .s_axis_tkeep          (s_axis_tkeep),
    .s_axis_tlast          (s_axis_tlast),
    .s_axis_tid            (s_axis_tid),
    .s_axis_tdest          (s_axis_tdest),
    .s_axis_tuser          (s_axis_tuser),
    .m_axis_tvalid         (m_axis_tvalid),
    .m_axis_tready         (m_axis_tready),
    .m_axis_tdata          (m_axis_tdata),
    .m_axis_tstrb          (m_axis_tstrb),
    .m_axis_tkeep          (m_axis_tkeep),
    .m_axis_tlast          (m_axis_tlast),
    .m_axis_tid            (m_axis_tid),
    .m_axis_tdest          (m_axis_tdest),
    .m_axis_tuser          (m_axis_tuser)
  );


endmodule
