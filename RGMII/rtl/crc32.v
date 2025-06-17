// 以太网CRC32校验模块

module crc32 (
  input         clk,
  input         reset,
  input  [7:0]  din,
  input         enable,
  output [31:0] crc32,
  output [31:0] crc32_next
);

//------------------------------------
//             Local Signal
//------------------------------------
  wire [7:0]  data;
  reg  [31:0] crc32_ff = 0;

//------------------------------------
//             User Logic
//------------------------------------
assign data = {din[0],din[1],din[2],din[3],din[4],din[5],din[6],din[7]};

assign crc32_next[0]  = crc32_ff[24] ^ crc32_ff[30] ^ data[0] ^ data[6];
assign crc32_next[1]  = crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[0] ^ data[1] ^ data[6] ^ data[7];
assign crc32_next[2]  = crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[7];
assign crc32_next[3]  = crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[31] ^ data[1] ^ data[2] ^ data[3] ^ data[7];
assign crc32_next[4]  = crc32_ff[24] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[28] ^ crc32_ff[30] ^ data[0] ^ data[2] ^ data[3] ^ data[4] ^ data[6];
assign crc32_next[5]  = crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[27] ^ crc32_ff[28] ^ crc32_ff[29] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
assign crc32_next[6]  = crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[28] ^ crc32_ff[29] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
assign crc32_next[7]  = crc32_ff[24] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[29] ^ crc32_ff[31] ^ data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[7];
assign crc32_next[8]  = crc32_ff[0] ^ crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[27] ^ crc32_ff[28] ^ data[0] ^ data[1] ^ data[3] ^ data[4];
assign crc32_next[9]  = crc32_ff[1] ^ crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[28] ^ crc32_ff[29] ^ data[1] ^ data[2] ^ data[4] ^ data[5];
assign crc32_next[10] = crc32_ff[2] ^ crc32_ff[24] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[29] ^ data[0] ^ data[2] ^ data[3] ^ data[5];
assign crc32_next[11] = crc32_ff[3] ^ crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[27] ^ crc32_ff[28] ^ data[0] ^ data[1] ^ data[3] ^ data[4];
assign crc32_next[12] = crc32_ff[4] ^ crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[28] ^ crc32_ff[29] ^ crc32_ff[30] ^ data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6];
assign crc32_next[13] = crc32_ff[5] ^ crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[29] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7];
assign crc32_next[14] = crc32_ff[6] ^ crc32_ff[26] ^ crc32_ff[27] ^ crc32_ff[28] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[2] ^ data[3] ^ data[4] ^ data[6] ^ data[7];
assign crc32_next[15] = crc32_ff[7] ^ crc32_ff[27] ^ crc32_ff[28] ^ crc32_ff[29] ^ crc32_ff[31] ^ data[3] ^ data[4] ^ data[5] ^ data[7];
assign crc32_next[16] = crc32_ff[8] ^ crc32_ff[24] ^ crc32_ff[28] ^ crc32_ff[29] ^ data[0] ^ data[4] ^ data[5];
assign crc32_next[17] = crc32_ff[9] ^ crc32_ff[25] ^ crc32_ff[29] ^ crc32_ff[30] ^ data[1] ^ data[5] ^ data[6];
assign crc32_next[18] = crc32_ff[10] ^ crc32_ff[26] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[2] ^ data[6] ^ data[7];
assign crc32_next[19] = crc32_ff[11] ^ crc32_ff[27] ^ crc32_ff[31] ^ data[3] ^ data[7];
assign crc32_next[20] = crc32_ff[12] ^ crc32_ff[28] ^ data[4];
assign crc32_next[21] = crc32_ff[13] ^ crc32_ff[29] ^ data[5];
assign crc32_next[22] = crc32_ff[14] ^ crc32_ff[24] ^ data[0];
assign crc32_next[23] = crc32_ff[15] ^ crc32_ff[24] ^ crc32_ff[25] ^ crc32_ff[30] ^ data[0] ^ data[1] ^ data[6];
assign crc32_next[24] = crc32_ff[16] ^ crc32_ff[25] ^ crc32_ff[26] ^ crc32_ff[31] ^ data[1] ^ data[2] ^ data[7];
assign crc32_next[25] = crc32_ff[17] ^ crc32_ff[26] ^ crc32_ff[27] ^ data[2] ^ data[3];
assign crc32_next[26] = crc32_ff[18] ^ crc32_ff[24] ^ crc32_ff[27] ^ crc32_ff[28] ^ crc32_ff[30] ^ data[0] ^ data[3] ^ data[4] ^ data[6];
assign crc32_next[27] = crc32_ff[19] ^ crc32_ff[25] ^ crc32_ff[28] ^ crc32_ff[29] ^ crc32_ff[31] ^ data[1] ^ data[4] ^ data[5] ^ data[7];
assign crc32_next[28] = crc32_ff[20] ^ crc32_ff[26] ^ crc32_ff[29] ^ crc32_ff[30] ^ data[2] ^ data[5] ^ data[6];
assign crc32_next[29] = crc32_ff[21] ^ crc32_ff[27] ^ crc32_ff[30] ^ crc32_ff[31] ^ data[3] ^ data[6] ^ data[7];
assign crc32_next[30] = crc32_ff[22] ^ crc32_ff[28] ^ crc32_ff[31] ^ data[4] ^ data[7];
assign crc32_next[31] = crc32_ff[23] ^ crc32_ff[29] ^ data[5];

always @ (posedge clk or posedge reset)
  if (reset)
    crc32_ff <= {32{1'b1}};
  else if (enable)
    crc32_ff <= crc32_next;

//------------------------------------
//             Output Port
//------------------------------------
  assign crc32 = crc32_ff;

endmodule