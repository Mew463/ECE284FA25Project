// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_32b_w2048_read_write_black_box (CLK, D, Q, CEN, WEN, REN, A);

  input  CLK; /* synthesis keep = 1 */
  input  REN; /* synthesis keep = 1 */
  input  WEN; /* synthesis keep = 1 */
  input  CEN; /* synthesis keep = 1 */
  input  [127:0] D; /* synthesis keep = 1 */
//   input  [10:0] RA; //Read addr
//   input  [10:0] WA; //Write addr
  input  [10:0] A; /* synthesis keep = 1 */
  output [127:0] Q; /* synthesis keep = 1 */
  assign Q = 0;
endmodule
