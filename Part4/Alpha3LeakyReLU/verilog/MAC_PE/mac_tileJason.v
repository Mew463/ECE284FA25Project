// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

// Equip ports
output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; 
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

// Latches
reg [1:0] inst_q;
reg [bw-1:0] a_q;      // Activation
reg [bw-1:0] b_q;      // Weight
reg [psum_bw-1:0] c_q; // Psum (Input from North, registered)
reg load_ready_q;
wire [psum_bw-1:0] mac_out;
reg w_zero;            // 1 if Weight is 0

// Assignments
assign out_e = a_q;
assign inst_e = inst_q;

// -------------------------------------------------------------
// OUTPUT LOGIC & POWER GATING
// -------------------------------------------------------------
// 1. If w_zero is 1: Bypass the MAC output. Pass c_q (which is in_n) directly south.
// 2. If w_zero is 0: Pass the calculated MAC output.
assign out_s = (w_zero) ? c_q : mac_out; 

// OPERAND ISOLATION:
// If weight is zero, force input 'a' to 0. 
// This stops internal toggling in the MAC adder to save power.
wire [bw-1:0] gated_a;
assign gated_a = (w_zero) ? {bw{1'b0}} : a_q;

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(gated_a), 
    .b(b_q), 
    .c(c_q), // We use the registered input from North
    .out(mac_out)
); 

always @(posedge clk) begin
    if(reset) begin
        inst_q <= 0;  
        load_ready_q <= 1;
        w_zero <= 0;
        a_q <= 0;
        b_q <= 0;
        c_q <= 0;
    end
    else begin
        // ---------------------------------------------------------
        // CRITICAL FIX: Data Propagation must happen UNCONDITIONALLY
        // ---------------------------------------------------------
        inst_q[1] <= inst_w[1];

        // 1. Pass Activation (East Propagation)
        if(inst_w[0] || inst_w[1]) begin
            a_q <= in_w;
        end
        
        // 2. Pass Instruction
        if(!load_ready_q) begin
            inst_q[0] <= inst_w[0];
        end

        // 3. Capture Psum (South Propagation)
        // We must always capture in_n, even if weight is zero.
        // If w_zero=1, this value will simply flow through to out_s via the assign statement.
        c_q <= in_n;

        // ---------------------------------------------------------
        // Weight Loading Logic
        // ---------------------------------------------------------
        if(inst_w[0] && load_ready_q) begin
            b_q <= in_w;
            
            // Check for Zero Weight immediately during load
            if (in_w == 0)
                w_zero <= 1;
            else
                w_zero <= 0;

            load_ready_q <= 0;
        end
    end
end

endmodule