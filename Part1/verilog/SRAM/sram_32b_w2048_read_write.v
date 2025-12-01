// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_32b_w2048_read_write (CLK, D, Q, CEN, WEN, REN, A);

  input  CLK;
  input  REN; // Read Envvvvable, read when high
  input  WEN; // Write Enable, write when high
  input  CEN; // Clock Enable, enable when low
  input  [127:0] D;
//   input  [10:0] RA; //Read addr
//   input  [10:0] WA; //Write addr
  input  [10:0] A; //Write addr
  output [127:0] Q;
  parameter num = 2048;

  reg [127:0] memory [num-1:0];
  reg [10:0] add_q;
  reg [10:0] add_q_prev;
  assign Q = memory[add_q];


  always @ (posedge CLK) begin

   if (!CEN && REN) begin // read  
      add_q <= A;
      add_q_prev <= add_q;
   end

   if (!CEN && WEN) begin // write
      memory[add_q_prev] <= D; 
   end
  end

endmodule
