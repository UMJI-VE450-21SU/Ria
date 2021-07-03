// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Integer Multiplier
// Author:  Li Shi
// Date:    2021/07/03

`include "src/common/defines.svh"

// Ref: Xilinx ug901-vivado-synthesis.pdf
module imul_unsigned (clock, A, B, RES);

  parameter WIDTHA = 32;
  parameter WIDTHB = 32;
  input                       clock;
  input   [WIDTHA-1:0]        A;
  input   [WIDTHB-1:0]        B;
  output  [WIDTHA+WIDTHB-1:0] RES;

  reg [WIDTHA-1:0]        rA;
  reg [WIDTHB-1:0]        rB;
  reg [WIDTHA+WIDTHB-1:0] M [`IMUL_LATENCY:0];

  integer i;
  always @(posedge clock) begin
    rA <= A;
    rB <= B;
    M[0] <= rA * rB;
    for (i = 0; i < `IMUL_LATENCY; i = i+1)
      M[i + 1] <= M[i];
  end

  assign RES = M[`IMUL_LATENCY];

endmodule
