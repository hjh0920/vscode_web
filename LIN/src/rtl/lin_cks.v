// LIN 接口校验和模块, 只做累加计算, 没有取反操作

module crc4 (
  input         clk,
  input         reset,
  input         enable,
  input  [7:0]  din,
  output [7:0]  dout
);

//------------------------------------
//             Local Signal
//------------------------------------
  reg  [8:0] sum = 0;

//------------------------------------
//             User Logic
//------------------------------------
always @ (posedge clk)
  if (reset)
    sum <= 9'b0;
  else if (enable)
    sum <= {1'b1,sum[7:0]} + {1'b0,din}, {8'b0,sum[8]};

//------------------------------------
//             Output Port
//------------------------------------
  assign dout = sum[8] ? (sum[7:0] + 8'b1) : sum[7:0];

endmodule