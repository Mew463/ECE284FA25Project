// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, weight_stationary, pass_psum, recall_psum);
parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; 
output [bw-1:0] out_e; 
input  [1:0] inst_w; 
//inst[2] == 1: output_stationary, inst[1]: pass psum (when we get the output data at the very end), inst[0]: execute (passing in weight and a nst[2] == 0: weight stationary, inst[1]: execute, inst[0]: kernel loading
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;  //either weight from output_stationary or psum from weight stationary
input  clk;
input  reset;
input pass_psum, weight_stationary, recall_psum;

reg [bw-1:0] a_q;   //activation
reg [psum_bw-1:0] b_q;  //either the weight for weight stationary or the weight from the north for output stationary
reg [psum_bw-1:0] c_q;  //psum
reg [1:0] inst_q;
reg load_ready_q;

wire signed [psum_bw-1:0] weight_stationary_mac_out; 
wire signed [psum_bw-1:0] output_stationary_mac_out; 
mac #(.bw(bw), .psum_bw(psum_bw)) weight_stationary_mac (
    .a(a_q), 
    .b(b_q[bw-1:0]),
    .c(c_q),
    .out(weight_stationary_mac_out)
); 
mac #(.bw(bw), .psum_bw(psum_bw)) output_stationary_mac (
    .a(a_q), 
    .b(b_q[bw-1:0]),
    .c(c_q),
    .out(output_stationary_mac_out)
); 
always @(posedge clk) begin
    if (reset) begin
        inst_q <= 2'b00;
        load_ready_q <= 1;
        a_q <= 0;
        b_q <= 0;
        c_q <= 0;

    end else if (weight_stationary) begin    //weight stationary
        inst_q[1] <= inst_w[1]; // Accept your inst_w[1] (execution) always into inst_q[1] latch.
        if (inst_w[1] == 1 || inst_w[0] == 1) begin
            a_q <= in_w;
        end

        if (inst_w[0] == 1 && load_ready_q == 1) begin
            b_q <= in_w; // b_q holds the weights
            load_ready_q <= 0;
        end

        c_q <= in_n;
        
        if (load_ready_q == 0) begin
            inst_q[0] <= inst_w[0];
        end
    end else begin  //output stationary
        inst_q <= inst_w; // Pass the instruction left to right
        if(inst_w[1]) begin //, inst[0]: execute
            a_q <= in_w; // activations from left
            b_q <= in_n; // weights from above
            c_q <= output_stationary_mac_out; // to do self accumulation
        end else if (pass_psum) begin // Pass psum from north to south
            c_q <= in_n;
        end else if (recall_psum) begin // Connect the output from our mac tile to the south
            c_q <= output_stationary_mac_out;
        end

        /*
        1) toggle recall_psum for one clock cycle
        2) set pass_psum high and run for 8? clock cycles
        */
    end 
end

assign out_e = a_q;
assign inst_e = inst_q;           // output stationary vv
assign out_s = weight_stationary ? weight_stationary_mac_out // Weight stationary output case
            : (pass_psum || recall_psum ? c_q : b_q) ; // Output stationary: pass down weight. Else, pass down psum 
endmodule
