`timescale 1ns/1ps
module core_tb_op;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [63:0] inst_q;

reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1; //SRAM
reg WEN_xmem = 1; //SRAM
reg [10:0] A_xmem = 0; // SRAM input
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;

reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg l1_wr_q = 0;

reg output_stationary_q; // inst[2]: 1 if output_stationary, 0 if weight_stationary

// instruction registers for weight stationary
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0; 

// instuction registers for output stationary
reg pass_psum_q = 0;
reg accumulate_q = 0;

//SFU instructions for weight stationary
reg sfu_passthrough_q = 0;
reg sfu_passthrough;

reg REN_pmem_q = 0;
reg REN_pmem;

//other instructions for debugging or not used
// reg [1:0] actFunc_q = 0;
// reg [1:0] actFunc;
reg debug = 0;
reg ififo_wr;
reg ififo_rd;


reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg l0_rd;
reg l0_wr; // l0 for activation
reg l1_wr; // l1 for weight (output stationary)

reg output_stationary = 1;
//weight stationary instructions
reg execute;
reg load;
//output stationary instructions
reg pass_psum;
reg accumulate;

reg [8*30:1] w_file_name; // take care of weight file one output channel at a time
wire ofifo_valid;

// weight stationary sfp output
wire [col*psum_bw-1:0] sfp_out; 

reg [col-1:0] psum_sram_ptr;


integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, a;
integer error;


assign inst_q[63] = debug; // Debug signal for psum_sram
// assign inst_q[37:36] = actFunc;
assign inst_q[37] = l1_wr;
assign inst_q[36] = output_stationary;
assign inst_q[35] = REN_pmem;
assign inst_q[34] = sfu_passthrough;
assign inst_q[33] = acc;
assign inst_q[32] = CEN_pmem;
assign inst_q[31] = WEN_pmem;
assign inst_q[30:20] = A_pmem;
assign inst_q[19]   = CEN_xmem;
assign inst_q[18]   = WEN_xmem;
assign inst_q[17:7] = A_xmem;
assign inst_q[6]   = ofifo_rd;
assign inst_q[5]   = ififo_wr;
assign inst_q[4]   = ififo_rd;
assign inst_q[3]   = l0_rd;
assign inst_q[2]   = l0_wr;
assign inst_q[1]   = output_stationary?pass_psum:execute; 
assign inst_q[0]   = output_stationary?accumation:load; 

// integer skippedFirst; // for weight stationary ?
integer o_nij_index;
integer nij;

core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
    .D_xmem(D_xmem), 
    .sfp_out(sfp_out), 
	.reset(reset)); 

initial begin
  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);
  // dump JUST the memory explicitly
//   $dumpvars(1, core_instance.PSUM_sram.memory[0]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[1]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[2]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[3]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[4]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[5]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[6]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[7]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[8]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[9]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[10]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[11]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[12]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[13]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[14]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[15]); 
//   $dumpvars(1, core_instance.PSUM_sram.memory[16]);
end 

//weight stationary helper function for onij calculation
function [31:0] onij;
    input [31:0] nij;
    input [31:0] kij;
    integer nijx, nijy, kijx, kijy, dx, dy, onijx, onijy;

    begin
        nijx = nij % 6;
        nijy = nij / 6;
        kijx = kij % 3;
        kijy = kij / 3;
        dx = -kijx;
        dy = -kijy;
        onijx = nijx + dx;
        onijy = nijy + dy;
        onij = (-1 < onijx && onijx < 4 && -1 < onijy && onijy < 4) ? onijx + onijy * 4 : -1;
    end
endfunction

initial begin 
    acc      = 0; //accumulate for weight stationary
    D_xmem   = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem   = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd    = 0;
    l0_wr    = 0;
    l1_wr    = 0;
    execute  = 0; //weight stationary inst[1]
    load     = 0; //weight stationary inst[0]
    pass_psum = 0; //output stationary inst[1]
    accumulate = 0; //output stationary inst[0]
    REN_pmem = 0;
    WEN_pmem = 0;
    psum_sram_ptr = 0;
    sfu_passthrough = 0;
    output_stationary = 1;


    /////// Activation Data Writing to SRAM /////////////
    x_file = $fopen("activation_tile0.txt", "r");
    // Following three lines are to remove the first three comment lines of the file
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    //////// Reset /////////
    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

    //output stationary version //
    if(output_stationary) begin
        for (t=0; t<kij*len_onij/2 * row; t=t+1) begin  // 9*8*8 = 576 preprocessed values are needed when only half of o/c 
            #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); // Load the activations (inputs) into core.v
            /* ALPHA: Formal Intensive Verification */
            // act_memory[t] = $unsigned($random); // Loads arbitrary 32 bitstream 
            // D_xmem = act_memory[t]; 
            WEN_xmem = 0; CEN_xmem = 0; 
            if (t>0) A_xmem = A_xmem + 1; 
            #0.5 clk = 1'b1;   
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        $fclose(x_file);
    end else begin

    // weight stationary version //
        for (t=0; t<len_nij; t=t+1) begin  
            #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); // Load the activations (inputs) into core.v
            /* ALPHA: Formal Intensive Verification */
            // act_memory[t] = $unsigned($random); // Loads arbitrary 32 bitstream 
            // D_xmem = act_memory[t]; 
            WEN_xmem = 0; CEN_xmem = 0; 
            if (t>0) A_xmem = A_xmem + 1;
            #0.5 clk = 1'b1;   
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        $fclose(x_file);
    end
    /////////////////////////////////////////////////

    /////// Weight Data Writing to SRAM /////////////
    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    
    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 
    
    for (i=0; i<10 ; i=i+1) begin
            #0.5 clk = 1'b0;
            #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1; 

    //output stationary version //
    if(output_stationary) begin
        A_xmem = 10'b1001000000 //starting at 576 (weight)
        for (t=0; t<kij*len_onij/2 * row; t=t+1) begin  // 9*8*8 = 576 preprocessed values are needed when only half of o/c 
            #0.5 clk = 1'b0;  x_scan_file = $fscanf(w_file,"%32b", D_xmem); 
            WEN_xmem = 0; CEN_xmem = 0; 
            if (t>0) A_xmem = A_xmem + 1; 
            #0.5 clk = 1'b1;   
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        $fclose(w_file);
    end else begin
    //weight stationary version // 
    // Note: weight staionary version does not have a seperate weight loading. It is combined with L0=>mac.

    end    
    /////////////////////////////////////////////////


    /////// Weight Data Writing to L1 /////////////
    if(output_stationary) begin
        A_xmem = 10'b1001000000; //starting at 576 (weight)
        #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0;
        #0.5 clk = 1'b1; 
    end

end
endmodule