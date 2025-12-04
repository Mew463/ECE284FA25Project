// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c);

parameter wbw = 4; // weight bitwidth
parameter abw = 2; // activation bitwidth
parameter psum_bw = 10; // using half of the bitwidth for a whole psum (?)

output signed [psum_bw-1:0] out;
input signed  [abw-1:0] a;  // activation
input signed  [wbw-1:0] b;  // weight
input signed  [psum_bw-1:0] c;


wire signed [(abw+wbw):0] product; // product bitwidth = abw + wbw, max 6 bits
wire signed [psum_bw-1:0] psum;
wire signed [abw:0]   a_pad;

assign a_pad = {1'b0, a}; // force to be unsigned number
assign product = a_pad * b;

assign psum = product + c;
assign out = psum;

endmodule
