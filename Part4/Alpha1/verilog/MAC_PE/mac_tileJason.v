// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, zero, reset);

parameter bw = 4;
parameter psum_bw = 16;

// Equip ports
output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input zero; // When high, this means weight/activation = 0, so `a_q`, `b_q`, `c_q` don't change
input  clk;
input  reset;


// Latches
reg [1:0] inst_q;
reg [bw-1:0] a_q; // Activation
reg [bw-1:0] b_q; // Weight
reg [psum_bw-1:0] c_q; // Psum
reg load_ready_q;
wire[psum_bw-1:0] mac_out;
reg [bw-1:0] in_w_reg;
reg [psum_bw-1:0] mac_reg;

assign out_e = zero ? 0 : a_q;
assign inst_e = inst_q;
assign out_s = mac_out; // If `zero`, just output the input psum

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q), 
    .b(b_q), 
    .c(c_q),
	.out(mac_out)
); 

always @(posedge clk)begin
    // in_w_reg <= in_w;
    // mac_reg <= in_n;
    if(reset)begin
        inst_q <= 0;  
        load_ready_q <= 1;
        a_q <= 0;
        b_q <= 0;
        c_q <= 0;
    end
    else begin
        inst_q[1] <= inst_w[1];
        c_q <= in_n;
        if(1)begin
            if(inst_w[0] || inst_w[1])begin
                a_q <= in_w;
            end
            if(inst_w[0] && load_ready_q)begin
                b_q <= in_w;
                load_ready_q <= 0;
            end
        end
    end
    if(!load_ready_q)begin
        inst_q[0] <= inst_w[0];
    end
end

endmodule
