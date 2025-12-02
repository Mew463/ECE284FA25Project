// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, separateweights);
parameter bw = 4;
parameter psum_bw = 16;
//MAIN CHANGES, need two cycles to load weights if two bit mode, need inst[1:0] -> inst[2:0] for all top mods
output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // westward input
output [bw-1:0] out_e;
input  [2:0] inst_w; // inst[2]: 2-bit mode, inst[1]:execute, inst[0]: kernel loading
output [2:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [bw-1:0] b_q1, b_q2; // 4 bit weights
reg [bw-1:0] a_q; // Activations (entire 4 bits)
wire signed [bw/2:0] a_q1, a_q2; // 2 bit activations, need to be signed so bw/2+1 len

wire is_two_bit;
assign is_two_bit = inst_w[2];

reg [psum_bw-1:0] c_q;
reg [2:0] inst_q;

assign a_q1 = {1b'0, a_q[1:0]};
assign a_q2 = {1b'0, a_q[3:2]};

wire signed [psum_bw-1:0] prod1, prod2;
assign prod1 = a_q1 * b_q1;
assign prod2 = a_q2 * b_q2;

assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = is_two_bit ? (prod1 + prod2 + c_q) : (prod1 + (prod2 << 2) + c_q);

reg load_ready_q1, load_ready_q2, load_ready;  //fill the 
assign load_ready = load_ready_q1 || load_ready_q2; //if either weight isnt filled

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
        inst_q[2] <= inst_w[2]; // Accept your inst_w[2] (2-bit mode) always into inst_q[2] latch.
        if (inst_w[1] == 1 || inst_w[0] == 1) begin // Execute step
            a_q <= in_w; // Store the activation
        end

        if (inst_w[0] == 1 && load_read == 1) begin //load a weight
            if (is_two_bit) begin
                if (load_ready_q2 == 1 ) begin 
                    b_q2 <= in_w; // b_q1 holds the weights
                    load_ready_q2 <= 0;
                end else if (load_ready_q1 == 1) begin 
                    b_q1 <= in_w; // b_q2 holds the weights
                    load_ready_q1 <= 0;   
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

    if (load_ready == 0) begin
        inst_q[0] <= inst_w[0];
    end
end

endmodule
