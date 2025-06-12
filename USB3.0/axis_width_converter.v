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
  output [M_TDATA_WIDTH-1:0]                      m_axis_tstrb,
  output [M_TDATA_WIDTH-1:0]                      m_axis_tkeep,
  output                                          m_axis_tlast,
  output [TID_WIDTH-1:0]                          m_axis_tid,
  output [TDEST_WIDTH-1:0]                        m_axis_tdest,
  output [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] m_axis_tuser
);
  
generate
  // 位宽一样, 直接透传
  if (S_TDATA_WIDTH == M_TDATA_WIDTH) 
    begin
      assign m_axis_tvalid = s_axis_tvalid;
      assign s_axis_tready = m_axis_tready;
      assign m_axis_tdata = s_axis_tdata;
      assign m_axis_tstrb = s_axis_tstrb;
      assign m_axis_tkeep = s_axis_tkeep;
      assign m_axis_tlast = s_axis_tlast;
      assign m_axis_tid   = s_axis_tid;
      assign m_axis_tdest = s_axis_tdest;
      assign m_axis_tuser = s_axis_tuser;
    end
  // 输入位宽小于输出位宽
  else if (S_TDATA_WIDTH < M_TDATA_WIDTH)
    begin
    // Local Parameter
      localparam WIDTH_MULTIPLE = M_TDATA_WIDTH/S_TDATA_WIDTH;
    // Local Signal
      reg [$clogb2(WIDTH_MULTIPLE)-1:0]             cnt = 0;
      reg                                           s_axis_tlast_d1 = 0;
      reg                                           refresh = 1; // 用于第一个输出数据更新 tid/tdest 信号
      reg [M_TDATA_WIDTH*8-1:0]                     s_axis_tdata_srl = 0;
      reg [M_TDATA_WIDTH-1:0]                       s_axis_tstrb_srl = 0;
      reg [M_TDATA_WIDTH-1:0]                       s_axis_tkeep_srl = 0;
      reg [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0]  s_axis_tuser_srl = 0;

      reg                                           s_axis_tready_ff = 0;
      reg                                           m_axis_tvalid_ff = 0;
      reg [M_TDATA_WIDTH*8-1:0]                     m_axis_tdata_ff = 0;
      reg [M_TDATA_WIDTH-1:0]                       m_axis_tstrb_ff = 0;
      reg [M_TDATA_WIDTH-1:0]                       m_axis_tkeep_ff = 0;
      reg                                           m_axis_tlast_ff = 0;
      reg [TID_WIDTH-1:0]                           m_axis_tid_ff = 0;
      reg [TDEST_WIDTH-1:0]                         m_axis_tdest_ff = 0;
      reg [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0]  m_axis_tuser_ff = 0;

    // User Logic
      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          cnt <= 'd0;
        else
          begin
            if (s_axis_tvalid && s_axis_tready_ff && s_axis_tlast)
              cnt <= 'd0;
            else if (s_axis_tvalid && s_axis_tready_ff && (cnt == WIDTH_MULTIPLE))
              cnt <= 'd1;
            else if (s_axis_tvalid && s_axis_tready_ff)
              cnt <= cnt + 'd1;
          end

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          s_axis_tready_ff <= 1'b0;
        else
          begin
            if ((cnt == (WIDTH_MULTIPLE-1)) && s_axis_tvalid && (!m_axis_tready))
              s_axis_tready_ff <= 1'b0;
            else
              s_axis_tready_ff <= 1'b1;
          end

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && s_axis_tlast)
          s_axis_tlast_d1 <= 1'b1;
        else
          s_axis_tlast_d1 <= 1'b0;

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          refresh <= 1'b1;
        else if (m_axis_tlast_ff)
          refresh <= 1'b1;
        else if (m_axis_tvalid_ff)
          refresh <= 1'b0;

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && (cnt == WIDTH_MULTIPLE))
          s_axis_tdata_srl <= {{{M_TDATA_WIDTH-S_TDATA_WIDTH}{8'b0}},s_axis_tdata};
        else if (s_axis_tvalid && s_axis_tready_ff)
          s_axis_tdata_srl <= {s_axis_tdata_srl[(M_TDATA_WIDTH-S_TDATA_WIDTH)*8-1:0],s_axis_tdata};

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && (cnt == WIDTH_MULTIPLE))
          s_axis_tstrb_srl <= {{{M_TDATA_WIDTH-S_TDATA_WIDTH}{1'b0}},s_axis_tstrb};
        else if (s_axis_tvalid && s_axis_tready_ff)
          s_axis_tstrb_srl <= {s_axis_tstrb_srl[(M_TDATA_WIDTH-S_TDATA_WIDTH)*8-1:0],s_axis_tstrb};

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && (cnt == WIDTH_MULTIPLE))
          s_axis_tkeep_srl <= {{{M_TDATA_WIDTH-S_TDATA_WIDTH}{1'b0}},s_axis_tkeep};
        else if (s_axis_tvalid && s_axis_tready_ff)
          s_axis_tkeep_srl <= {s_axis_tkeep_srl[(M_TDATA_WIDTH-S_TDATA_WIDTH)*8-1:0],s_axis_tkeep};

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && (cnt == WIDTH_MULTIPLE))
          s_axis_tuser_srl <= {{{(M_TDATA_WIDTH-S_TDATA_WIDTH)*TUSER_WIDTH_PER_BYTE}{1'b0}},s_axis_tuser};
        else if (s_axis_tvalid && s_axis_tready_ff)
          s_axis_tuser_srl <= {s_axis_tuser_srl[(M_TDATA_WIDTH-S_TDATA_WIDTH)*TUSER_WIDTH_PER_BYTE-1:0],s_axis_tuser};

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          m_axis_tvalid_ff <= 1'b0;
        else
          begin
            if ((cnt == WIDTH_MULTIPLE) || s_axis_tlast_d1)
              m_axis_tvalid_ff <= 1'b1;
            else if (m_axis_tready)
              m_axis_tvalid_ff <= 1'b0;
          end

      always @ (posedge aclk)
        if ((cnt == WIDTH_MULTIPLE) || s_axis_tlast_d1)
          begin
            m_axis_tdata_ff <= s_axis_tdata_srl;
            m_axis_tstrb_ff <= s_axis_tstrb_srl;
            m_axis_tkeep_ff <= s_axis_tkeep_srl;
            m_axis_tuser_ff <= s_axis_tuser_srl;
          end

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          m_axis_tlast_ff <= 1'b0;
        else
          begin
            if (s_axis_tlast_d1)
              m_axis_tlast_ff <= 1'b1;
            else if (m_axis_tready)
              m_axis_tlast_ff <= 1'b0;
          end

      always @ (posedge aclk)
        if (refresh && s_axis_tvalid)
          begin
            m_axis_tid_ff <= s_axis_tid;
            m_axis_tdest_ff <= s_axis_tdest;
          end
    // Output
      assign m_axis_tvalid = m_axis_tvalid_ff;
      assign s_axis_tready = s_axis_tready_ff;
      assign m_axis_tdata = m_axis_tdata_ff;
      assign m_axis_tstrb = m_axis_tstrb_ff;
      assign m_axis_tkeep = m_axis_tkeep_ff;
      assign m_axis_tlast = m_axis_tlast_ff;
      assign m_axis_tid   = m_axis_tid_ff;
      assign m_axis_tdest = m_axis_tdest_ff;
      assign m_axis_tuser = m_axis_tuser_ff;
    end
  // 输入位宽大于输出位宽
  else // S_TDATA_WIDTH > M_TDATA_WIDTH 
    begin
    // Local Parameter
      localparam WIDTH_MULTIPLE = S_TDATA_WIDTH/M_TDATA_WIDTH;
    // Local Signal
      reg [$clogb2(WIDTH_MULTIPLE)-1:0]             cnt = 0;
      reg                                           start_conv = 0; // 复位后开始转换标志
      reg [S_TDATA_WIDTH*8-1:0]                     s_axis_tdata_srl = 0;
      reg [S_TDATA_WIDTH-1:0]                       s_axis_tstrb_srl = 0;
      reg [S_TDATA_WIDTH-1:0]                       s_axis_tkeep_srl = 0;
      reg [S_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0]  s_axis_tuser_srl = 0;
      reg                                           s_axis_tlast_lock = 0;
      reg [TID_WIDTH-1:0]                           s_axis_tid_lock = 0;
      reg [TDEST_WIDTH-1:0]                         s_axis_tdest_lock = 0;

      reg                                           s_axis_tready_ff = 0;
      reg                                           m_axis_tvalid_ff = 0;
      reg [M_TDATA_WIDTH*8-1:0]                     m_axis_tdata_ff = 0;
      reg [M_TDATA_WIDTH-1:0]                       m_axis_tstrb_ff = 0;
      reg [M_TDATA_WIDTH-1:0]                       m_axis_tkeep_ff = 0;
      reg                                           m_axis_tlast_ff = 0;
      reg [TID_WIDTH-1:0]                           m_axis_tid_ff = 0;
      reg [TDEST_WIDTH-1:0]                         m_axis_tdest_ff = 0;
      reg [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0]  m_axis_tuser_ff = 0;
    // User Logic
      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          cnt <= 'd0;
        else
          begin
            if (m_axis_tvalid_ff && m_axis_tready && (cnt == WIDTH_MULTIPLE-1))
              cnt <= 'd0;
            else if (m_axis_tvalid_ff && m_axis_tready)
              cnt <= cnt + 'd1;
          end

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          start_conv <= 'b0;
        else if (s_axis_tvalid)
          start_conv <= 'b1;

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          s_axis_tready_ff <= 1'b0;
        else
          begin
            if ((!start_conv) || ((cnt == (WIDTH_MULTIPLE-1)) && m_axis_tvalid_ff && m_axis_tready))
              s_axis_tready_ff <= 1'b1;
            else
              s_axis_tready_ff <= 1'b0;
          end

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff && s_axis_tlast)
          s_axis_tlast_lock <= 1'b1;
        else if (s_axis_tready_ff)
          s_axis_tlast_lock <= 1'b0;

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff)
          begin
            s_axis_tid_lock <= s_axis_tid;
            s_axis_tdest_lock <= s_axis_tdest;
          end

      always @ (posedge aclk)
        if (m_axis_tvalid_ff && m_axis_tready && (cnt > 0))
          begin
            s_axis_tdata_srl <= {s_axis_tdata_srl[(S_TDATA_WIDTH-2*M_TDATA_WIDTH)*8-1:0],{{2*M_TDATA_WIDTH}{8'b0}}};
            s_axis_tstrb_srl <= {s_axis_tstrb_srl[(S_TDATA_WIDTH-2*M_TDATA_WIDTH)-1:0],{{2*M_TDATA_WIDTH}{1'b0}}};
            s_axis_tkeep_srl <= {s_axis_tkeep_srl[(S_TDATA_WIDTH-2*M_TDATA_WIDTH)-1:0],{{2*M_TDATA_WIDTH}{1'b0}}};
            s_axis_tuser_srl <= {s_axis_tuser_srl[(S_TDATA_WIDTH-2*M_TDATA_WIDTH)-1:0],{{2*M_TDATA_WIDTH}{1'b0}}};
          end
        else if (s_axis_tvalid && s_axis_tready_ff)
          begin
            s_axis_tdata_srl <= {s_axis_tdata[(S_TDATA_WIDTH-M_TDATA_WIDTH)*8-1:0],{{M_TDATA_WIDTH}{8'b0}}};
            s_axis_tstrb_srl <= {s_axis_tstrb[(S_TDATA_WIDTH-M_TDATA_WIDTH)-1:0],{{M_TDATA_WIDTH}{1'b0}}};
            s_axis_tkeep_srl <= {s_axis_tkeep[(S_TDATA_WIDTH-M_TDATA_WIDTH)-1:0],{{M_TDATA_WIDTH}{1'b0}}};
            s_axis_tuser_srl <= {s_axis_tuser[(S_TDATA_WIDTH-M_TDATA_WIDTH)-1:0],{{M_TDATA_WIDTH}{1'b0}}};
          end

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          m_axis_tvalid_ff <= 1'b0;
        else
          begin
            if ((s_axis_tvalid && s_axis_tready_ff) || (cnt > 0))
              m_axis_tvalid_ff <= 1'b1;
            else if (m_axis_tready)
              m_axis_tvalid_ff <= 1'b0;
          end

      always @ (posedge aclk)
        if (s_axis_tvalid && s_axis_tready_ff)
          begin
            m_axis_tdata_ff <= s_axis_tdata[S_TDATA_WIDTH*8-1:-(M_TDATA_WIDTH*8)];
            m_axis_tstrb_ff <= s_axis_tstrb[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
            m_axis_tkeep_ff <= s_axis_tkeep[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
            m_axis_tuser_ff <= s_axis_tuser[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
          end
        else if (cnt > 0)
          begin
            m_axis_tdata_ff <= s_axis_tdata_srl[S_TDATA_WIDTH*8-1:-(M_TDATA_WIDTH*8)];
            m_axis_tstrb_ff <= s_axis_tstrb_srl[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
            m_axis_tkeep_ff <= s_axis_tkeep_srl[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
            m_axis_tuser_ff <= s_axis_tuser_srl[S_TDATA_WIDTH-1:-M_TDATA_WIDTH];
          end

      always @ (posedge aclk or negedge aresetn)
        if (!aresetn)
          m_axis_tlast_ff <= 1'b0;
        else
          begin
            if (s_axis_tlast_lock && (cnt == (WIDTH_MULTIPLE-1)))
              m_axis_tlast_ff <= 1'b1;
            else if (m_axis_tready)
              m_axis_tlast_ff <= 1'b0;
          end

      always @ (posedge aclk)
        begin
          m_axis_tid_ff <= s_axis_tid_lock;
          m_axis_tdest_ff <= s_axis_tdest_lock;
        end

    // Output
      assign m_axis_tvalid = m_axis_tvalid_ff;
      assign s_axis_tready = s_axis_tready_ff;
      assign m_axis_tdata = m_axis_tdata_ff;
      assign m_axis_tstrb = m_axis_tstrb_ff;
      assign m_axis_tkeep = m_axis_tkeep_ff;
      assign m_axis_tlast = m_axis_tlast_ff;
      assign m_axis_tid   = m_axis_tid_ff;
      assign m_axis_tdest = m_axis_tdest_ff;
      assign m_axis_tuser = m_axis_tuser_ff;

    end
endgenerate

endmodule