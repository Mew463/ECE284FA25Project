// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_128b_1address (CLK, D, Q, CEN, WEN);

  input  CLK;
  input  WEN;
  input  CEN;
  input  [127:0] D;
  output [127:0] Q;

  reg [127:0] memory;
  // reg [10:0] add_q;
  // assign Q = memory[add_q];

  assign Q = memory;

  always @ (posedge CLK) begin
   if (!CEN && !WEN) // write
      memory <= D; 
  end

endmodule
