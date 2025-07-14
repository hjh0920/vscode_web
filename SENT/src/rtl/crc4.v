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
  reg  [3:0] crc4 = 0;
  wire [3:0] crc4_next;

//------------------------------------
//             User Logic
//------------------------------------
assign crc4_next[0] = crc4[0] ^ crc4[1] ^ crc4[3] ^ din[0] ^ din[1] ^ din[3];
assign crc4_next[1] = crc4[1] ^ crc4[2] ^ din[1] ^ din[2];
assign crc4_next[2] = crc4[0] ^ crc4[1] ^ crc4[2] ^ din[0] ^ din[1] ^ din[2];
assign crc4_next[3] = crc4[0] ^ crc4[2] ^ din[0] ^ din[2];

always @ (posedge clk or posedge reset)
  if (reset)
    crc4 <= 4'b0011;
  else if (enable)
    crc4 <= crc4_next;

//------------------------------------
//             Output Port
//------------------------------------
  assign dout = crc4;

endmodule