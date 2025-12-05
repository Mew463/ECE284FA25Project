// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_32b_w2048_black_box (CLK, D, Q, CEN, WEN, A);

  input  CLK; /* synthesis keep = 1 */
  input  WEN; /* synthesis keep = 1 */
  input  CEN; /* synthesis keep = 1 */
  input  [127:0] D; /* synthesis keep = 1 */
  input  [10:0] A; /* synthesis keep = 1 */
  output [127:0] Q; /* synthesis keep = 1 */

  assign Q = 0;

endmodule
