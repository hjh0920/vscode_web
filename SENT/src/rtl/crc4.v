// SENT CRC4校验模块

module crc4 (
  input         clk,
  input         reset,
  input  [3:0]  din,
  input         enable,
  output [3:0]  dout
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire [3:0] data;
  reg  [3:0] crc4 = 0;

//------------------------------------
//             User Logic
//------------------------------------
assign data = {din[0],din[1],din[2],din[3]};

assign crc4_next[0]  = 1'b0;
assign crc4_next[1]  = 1'b0;
assign crc4_next[2]  = 1'b0;
assign crc4_next[3]  = 1'b0;

always @ (posedge clk or posedge reset)
  if (reset)
    crc4 <= {4{1'b1}};
  else if (enable)
    crc4 <= crc4_next;

//------------------------------------
//             Output Port
//------------------------------------
  assign dout = crc4;

endmodule