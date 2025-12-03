// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);
parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; 
output [bw-1:0] out_e; 
input  [1:0] inst_w; // inst[1]:execute, inst[0]: kernel loading
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [bw-1:0] a_q, b_q;
reg [psum_bw-1:0] c_q;
reg [1:0] inst_q;
reg load_ready_q;
reg w_zero;//, x_zero;

wire signed [psum_bw-1:0] mac_out; 
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q), 
    .b(b_q),
    .c(c_q),
	.out(mac_out)
); 
assign out_e = a_q;
assign inst_e = inst_q;
// assign out_s = (!x_zero) ? mac_out : 0; // mux
assign out_s = mac_out;
// assign w_zero = (b_q == 0) ? 1 : 0; 
// assign x_zero = (a_q == 0) ? 1 : 0; 
always @(posedge clk) begin
    if(inst_w[0] == 1 && load_ready_q == 1) begin // when its time for a new weight
        w_zero <= (in_w == 0) ? 1 : 0; // w_zero is 1 when weight is 0 // mux
    end
    // x_zero <= (a_q == 0) ? 1 : 0; // x_zero is 1 when activation is 0 // mux
    if (reset) begin
        inst_q <= 2'b00;
        load_ready_q <= 1;
        a_q <= 0;
        b_q <= 0;
        c_q <= 0;
        w_zero <= 0;
        // x_zero <= 0;
    end 
    else if(!w_zero) begin // additional check
        if (inst_w[1] == 1 || inst_w[0] == 1) begin
            a_q <= in_w;
        end

        if (inst_w[0] == 1 && load_ready_q == 1) begin
            b_q <= in_w; // b_q holds the weights
            load_ready_q <= 0;
        end
        c_q <= in_n;
    end
    // else begin
    //     // a_q, b_q, c_q never change so mac will never turn on (it is combinational)  
    // end

    // When weight is loaded, new instructions will just go to east
    inst_q[1] <= inst_w[1]; // Accept your inst_w[1] (execution) always into inst_q[1] latch.
    if (load_ready_q == 0) begin
        inst_q[0] <= inst_w[0];
    end
end


endmodule
