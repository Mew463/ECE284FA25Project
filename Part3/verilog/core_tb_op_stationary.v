`timescale 1ns/1ps
module core_tb;

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
reg acc;

reg output_stationary_q; // inst[2]: 1 if output_stationary, 0 if weight_stationary

// instruction registers for weight stationary
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0; 

// instuction registers for output stationary
reg pass_psum_q = 0;

//SFU instructions for weight stationary
reg sfu_passthrough_q = 0;
reg sfu_passthrough;

reg ofifo_wr;

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
reg CEN_pmem, WEN_pmem, A_pmem;
reg output_stationary = 1;
//weight stationary instructions
reg execute;
reg load;
//output stationary instructions
reg pass_psum;
reg recall_psum;

reg [8*128:1] w_file_name; // take care of weight file one output channel at a time
wire ofifo_valid;

// weight stationary sfp output
wire [col*psum_bw-1:0] sfp_out; 

reg [col-1:0] psum_sram_ptr;


integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
reg [1024:0] captured_data; 
reg [8*256:1] dummy_line;
integer t, i, j, k, kij, a, ic;
integer error;


assign inst_q[63] = debug; // Debug signal for psum_sram
// assign inst_q[37:36] = actFunc;
assign inst_q[39] = pass_psum;
assign inst_q[38] = recall_psum;
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
assign inst_q[1]   = execute; 
assign inst_q[0]   = load; 

// integer skippedFirst; // for weight stationary ?
integer o_nij_index;
integer nij;
integer debug1;

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
  $dumpvars(1, core_instance.PSUM_sram.memory[0]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[1]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[2]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[3]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[4]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[5]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[6]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[7]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[8]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[9]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[10]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[11]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[12]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[13]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[14]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[15]); 
  $dumpvars(1, core_instance.PSUM_sram.memory[16]);

  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[0]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[1]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[2]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[3]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[4]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[5]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[6]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[7]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[8]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[9]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[10]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[11]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[12]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[13]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[14]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[15]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[16]);

  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 0]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 1]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 2]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 3]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 4]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 5]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 6]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 7]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 8]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 9]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 10]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 11]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 12]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 13]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 14]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 15]); 
  $dumpvars(1, core_instance.ACTIVATION_WEIGHTS_sram.memory[576 + 16]);

  
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
    recall_psum = 0; //output stationary inst[0]
    REN_pmem = 0;
    WEN_pmem = 0;
    psum_sram_ptr = 0;
    sfu_passthrough = 0;
    output_stationary = 1;


    /////// Activation Data Writing to SRAM /////////////
    x_file = $fopen("output_stationary_data/activation_os.txt", "r"); 
    // x_file = $fopen("activation_tile0.txt", "r"); 
    // Following three lines are to remove the first three comment lines of the file
    // for (i = 0; i < 11; i++) begin
    //     x_scan_file = $fscanf(x_file,"%s", captured_data); // Remove the first 11 lines
    // end
    // repeat (11) begin
    //         $fgets(dummy_line, x_file);
    // end
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
        for (t=0; t<len_kij*len_onij/2; t=t+1) begin  // 9*8 = 576 preprocessed values are needed when only half of o/c 
            #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); // Load the activations (inputs) into core.v
            if (x_scan_file == 0)
                $display("ERROR: fscanf failed for input activations line=%0d", t);
            else
                $display("SUCCESS: read %b", D_xmem);

            /* ALPHA: Formal Intensive Verification */
            // act_memory[t] = $unsigned($random); // Loads arbitrary 32 bitstream 
            // D_xmem = act_memory[t]; 
            WEN_xmem = 0; CEN_xmem = 0; 
            if (t>0)  A_xmem = A_xmem +1; 
            #0.5 clk = 1'b1;   
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        $fclose(x_file);

    /////////////////////////////////////////////////

    /////// Weight Data Writing to SRAM /////////////
    /** Output stationary (loop input channel times)
    * SRAM => L0; SRAM => L1; (9*8 4-bit input each time)
    * Load W and X into PE and accumulate
    * Note: Due to limitation of L0 and L1, we are only to loop through the loading and accumulation process for input channel times.
    */
    // 
    // w_file_name = "output_stationary_data/weights_os.txt"; 
    w_file = $fopen("output_stationary_data/weights_os.txt", "r");
    // for (i = 0; i < 7; i++) begin // Remove the first 7 lines for weights
    //     w_scan_file = $fscanf(w_file,"%s", captured_data);
    // end
    
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
        A_xmem = 10'b1001000000; //starting at 576 (weight)
        for (t=0; t<len_kij*len_onij/2; t=t+1) begin  // 9*8  576 preprocessed values are needed when only half of o/c 
            #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
            if (w_scan_file == 0)
                $display("ERROR: fscanf failed for weights line=%0d", t);
            else
                $display("SUCCESS: read %b", D_xmem);
            WEN_xmem = 0; CEN_xmem = 0; //write to SRAM
            if (t>0) A_xmem = A_xmem + 1; 
            #0.5 clk = 1'b1;   
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        $fclose(w_file);

        for(ic=0; ic<8; ic=ic+1)  begin //loop ic times for loading and accumulation
                /////// Activation Data Writing to L0 /////////////
                A_xmem = ic*9; //starting at 0 (activation)
                #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0;
                #0.5 clk = 1'b1; 
                
                for (t=0; t<len_kij+1; t=t+1) begin  //load in all activation for the first input channel 9 -- output nij * preprocessed nij to fit kernel multiplication
                #0.5 clk = 1'b0; l0_wr = 1; if (t>0) A_xmem = A_xmem + 1; 
                #0.5 clk = 1'b1;  
                end

                #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;// CHIP Disable
                #0.5 clk = 1'b1;

                /////// Weight Data Writing to L1 /////////////
                A_xmem = 10'b1001000000 + ic*9;//starting at 576 (weight)
                #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0;
                #0.5 clk = 1'b1; 
                
                for (t=0; t<len_kij+1; t=t+1) begin  
                #0.5 clk = 1'b0; l1_wr = 1; if (t>0) A_xmem = A_xmem + 1; 
                #0.5 clk = 1'b1;  
                end

                #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l1_wr = 0;// CHIP Disable
                 l0_wr = 0; l1_wr = 0;
                #0.5 clk = 1'b1; 
            
                ///// Weight and Activation load from l0 & l1 and accumulate ////
                #0.5 clk = 1'b0; l0_rd = 1; 
                #0.5 clk = 1'b1; //Need one cycle for L0 to propogate signal to first column
                for(i = 0; i < len_kij + col + row; i=i+1) begin // compute 
                    #0.5 clk = 1'b0;
                    if(i < len_kij) begin 
                        l0_rd = 1; execute = 1; // L0&L1 -> PE ; accumulate
                    end else begin
                        l0_rd = 0; execute = 0;
                    end
                    #0.5 clk = 1'b1; 
                end


                
        end
    
    //////// Finished accumulation, Sending Signal to output to OFIFO////
    #0.5 clk = 1'b0; 
    recall_psum = 1;
    ofifo_wr = 1; // Write to OFIFO
    sfu_passthrough = 1; // Enable passthrough in SFP
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0; 
    ofifo_rd = 1;
    pass_psum = 1; recall_psum = 0;
    A_pmem = 7;
    #0.5 clk = 1'b1;

    for (i = 0; i < col; i++) begin // Hopefully data is ready to be written straight to PMEM at this point
        #0.5 clk = 1'b0; 
        A_pmem = A_pmem - 1;
        CEN_pmem = 0; WEN_pmem = 1; // Write address delayed by one clock cycle 
        #0.5 clk = 1'b1;
    end

    CEN_pmem = 1; // Disable


    ////////// Accumulation /////////
  out_file = $fopen("output_stationary_data/out.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start during accumulation #############"); 
  #0.5 clk = 1'b0; 
  #0.5 clk = 1'b1; 
  #0.5 clk = 1'b0; 
  for (i=0; i<len_onij/2; i=i+1) begin 
    CEN_pmem = 0;
    A_pmem = i;
    #0.5 clk = 1'b1; #0.5 clk = 1'b0; 
    out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
    if (sfp_out == answer)
      $display("%2d-th output featuremap Data matched! :D", i); 
    else begin
      $display("%2d-th output featuremap Data ERROR!!", i); 
      $display("sfpout: %128b", sfp_out);
      $display("answer: %128b", answer);
      error = error + 1;
    end
  end


    end else begin
    //weight stationary version // 
    //////// Kernel loading /////
    /////// Whole Activation processing cycle -- weight stationary///////
      /*
      1) SRAM(activation) -> L0
      2) L0 -> PE (execute)
      3) Is there a complete row in OFIFO filled? 
        Yes: Accumulate
      4) Repeat
      5) Store output in PSUM SRAM
      */

    
    end    
    /////////////////////////////////////////////////

    #10 $finish;
end
endmodule