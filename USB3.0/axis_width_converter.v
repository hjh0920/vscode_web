// AXI4-Stream位宽转换模块

module axis_width_converter #(
  parameter interger S_TDATA_WIDTH = 0, // 1-512 (byte)
  parameter interger M_TDATA_WIDTH = 0, // 1-512 (byte)
  parameter interger TID_WIDTH = 0, // 0-32 (bit)
  parameter interger TDEST_WIDTH = 0, // 0-32 (bit)
  parameter interger TUSER_WIDTH_PER_BYTE = 0 // 0-2048 (bit)
)(
  input                                           aclk,
  input                                           aresetn,

  input                                           s_axis_tvalid,
  output                                          s_axis_tready,
  input  [S_TDATA_WIDTH*8-1:0]                    s_axis_tdata,
  input  [S_TDATA_WIDTH-1:0]                      s_axis_tstrb,
  input  [S_TDATA_WIDTH-1:0]                      s_axis_tkeep,
  input                                           s_axis_tlast,
  input  [TID_WIDTH-1:0]                          s_axis_tid,
  input  [TDEST_WIDTH-1:0]                        s_axis_tdest,
  input  [S_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] s_axis_tuser,

  output                                          m_axis_tvalid,
  input                                           m_axis_tready,
  output [M_TDATA_WIDTH*8-1:0]                    m_axis_tdata,
  input  [M_TDATA_WIDTH-1:0]                      m_axis_tstrb,
  input  [M_TDATA_WIDTH-1:0]                      m_axis_tkeep,
  input                                           m_axis_tlast,
  input  [TID_WIDTH-1:0]                          m_axis_tid,
  input  [TDEST_WIDTH-1:0]                        m_axis_tdest,
  input  [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] m_axis_tuser
);
  
generate
  if (S_TDATA_WIDTH == M_TDATA_WIDTH)
    begin
      assign m_axis_tvalid = s_axis_tvalid;
      assign s_axis_tready = m_axis_tready;
      assign m_axis_tdata = s_axis_tdata;
      assign m_axis_tstrb = s_axis_tstrb;
      assign m_axis_tkeep = s_axis_tkeep;
      assign m_axis_tlast = s_axis_tlast;
      assign m_axis_tid = s_axis_tid;
      assign m_axis_tdest = s_axis_tdest;
      assign m_axis_tuser = s_axis_tuser;
    end
  else if (S_TDATA_WIDTH < M_TDATA_WIDTH)
    begin

    end
  else // S_TDATA_WIDTH > M_TDATA_WIDTH
    begin
      
    end
endgenerate

endmodule