// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c);

parameter bw = 4; // weight bitwidth
parameter psum_bw = 16; 

output signed [psum_bw-1:0] out;
input signed  [bw-1:0] a;  // activation
input signed  [bw-1:0] b;  // weight
input signed  [psum_bw-1:0] c;


wire signed [bw*2:0] product; // product bitwidth = abw + wbw, max 6 bits
wire signed [psum_bw-1:0] psum;
wire signed [bw:0]   a_pad;

assign a_pad = {1'b0, a}; // force to be unsigned number
assign product = a_pad * b;

assign psum = product + c;
assign out = psum;

endmodule
