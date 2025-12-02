// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, separateweights);
parameter bw = 4;
parameter bw_half = 2; // For the 2 bit activations
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // westward input
output [bw-1:0] out_e;
input separateweights; // 1 : separate weights (16x8) 0 : non separate weights (8x8) 
input  [1:0] inst_w; // inst[1]:execute, inst[0]: kernel loading
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [bw-1:0] b_q1, b_q2; // 4 bit weights
reg [bw-1:0] a_q; // Activations (entire 4 bits)
wire [bw_half-1:0] a_q1, a_q2; // 2 bit activations

reg [psum_bw-1:0] c_q;
reg [1:0] inst_q;
reg load_ready_q1;
reg load_ready_q2;

assign a_q2 = a_q[3:2];
assign a_q1 = a_q[1:0];

wire signed [psum_bw-1:0] mac1_out, mac2_out; 
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance2 ( // MSB
    .a({{2'b00},{a_q2}}), 
    .b(b_q2),
    .c({(psum_bw){1'b0}}),
	.out(mac2_out)
); 

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance1 ( // Handles LSB
    .a({{2'b00},{a_q1}}), 
    .b(b_q1),
    .c({(psum_bw){1'b0}}),
	.out(mac1_out)
); 

always @(posedge clk) begin
    if (reset) begin
        inst_q <= 2'b00;
        load_ready_q1 <= 1;
        load_ready_q2 <= 1;
        a_q <= 0;
        b_q1 <= 0; b_q2 <= 0;
        c_q <= 0;

    end else begin
        inst_q[1] <= inst_w[1]; // Accept your inst_w[1] (execution) always into inst_q[1] latch.
        if (inst_w[1] == 1 || inst_w[0] == 1) begin // Execute step
            a_q <= in_w; // Store the activation
        end

        if (inst_w[0] == 1 && load_ready_q2 == 1) begin
            if (separateweights) begin
                if (load_ready_q1 == 1 ) begin 
                    b_q1 <= in_w; // b_q1 holds the weights
                    load_ready_q1 <= 0;
                end else if (load_ready_q2 == 1) begin 
                    b_q2 <= in_w; // b_q2 holds the weights
                    load_ready_q2 <= 0;   
                end
            end else begin 
                b_q1 <= in_w;
                b_q2 <= in_w;
                load_ready_q1 <= 0;
                load_ready_q2 <= 0;
            end
        
        end
        c_q <= in_n;
    end

    if (load_ready_q1 == 0 && load_ready_q2 == 0) begin
        inst_q[0] <= inst_w[0];
    end
end
assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = separateweights ? mac1_out + mac2_out + c_q : (mac2_out <<< 2) + mac1_out + c_q;
endmodule
