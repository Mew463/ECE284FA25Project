// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
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
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 0;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg sfu_passthrough_q = 0;
reg sfu_passthrough;
reg REN_pmem_q = 0;
reg REN_pmem;
// reg [1:0] actFunc_q = 0;
// reg [1:0] actFunc;
reg debug = 0;

reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
reg [col-1:0] psum_sram_ptr;

/* ALPHA: Formal Intensive Verification */
// reg [bw*row-1:0] act_memory [0:len_nij-1];
// reg [bw*row-1:0] wgt_memory [0:len_kij-1];
// reg [psum_bw*col-1:0] golden_output; // could also just fill `answer

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, a;
integer error;

// assign inst_q[35] = REN_pmem_q;
// assign inst_q[34] = sfu_passthrough_q;
// assign inst_q[33] = acc_q;
// assign inst_q[32] = CEN_pmem_q;
// assign inst_q[31] = WEN_pmem_q;
// assign inst_q[30:20] = A_pmem_q;
// assign inst_q[19]   = CEN_xmem_q;
// assign inst_q[18]   = WEN_xmem_q;
// assign inst_q[17:7] = A_xmem_q;
// assign inst_q[6]   = ofifo_rd_q;
// assign inst_q[5]   = ififo_wr_q;
// assign inst_q[4]   = ififo_rd_q;
// assign inst_q[3]   = l0_rd_q;
// assign inst_q[2]   = l0_wr_q;
// assign inst_q[1]   = execute_q; 
// assign inst_q[0]   = load_q; 
assign inst_q[63] = debug; // Debug signal for psum_sram
// assign inst_q[37:36] = actFunc;
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

integer skippedFirst;
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
end 

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

/* ALPHA: Formal Intensive Verification */
// task calculateCNN; 
//   input [bw*row-1:0] input_act_mem [0:len_kij-1];
//   input [bw*row-1:0] input_wgt_mem [0:len_kij-1];

//   output [psum_bw*col-1:0] golden_output;

//   reg [psum_bw-1:0] temp_psum [0:col-1];
//   integer act_idx;
//   integer wgt_idx;
// endtask


initial begin 
  acc      = 0; //totally making this up with accumulate
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  REN_pmem = 0;
  WEN_pmem = 0;
  psum_sram_ptr = 0;
  sfu_passthrough = 0;

  // $dumpfile("core_tb.vcd");
  // $dumpvars(0,core_tb);
  // $display("hello");

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
  /////////////////////////

  /////// Activation data writing to memory ///////
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
  /////////////////////////////////////////////////


  for (kij=0; kij<9; kij=kij+1) begin    // kij loop

    // case(kij)
    //  0: w_file_name = "weight_itile0_otile0_kij0.txt";
    //  1: w_file_name = "weight_itile0_otile0_kij1.txt";
    //  2: w_file_name = "weight_itile0_otile0_kij2.txt";
    //  3: w_file_name = "weight_itile0_otile0_kij3.txt";
    //  4: w_file_name = "weight_itile0_otile0_kij4.txt";
    //  5: w_file_name = "weight_itile0_otile0_kij5.txt";
    //  6: w_file_name = "weight_itile0_otile0_kij6.txt";
    //  7: w_file_name = "weight_itile0_otile0_kij7.txt";
    //  8: w_file_name = "weight_itile0_otile0_kij8.txt";
    // endcase
    case(kij)
     0: w_file_name = "weight0.txt";
     1: w_file_name = "weight1.txt";
     2: w_file_name = "weight2.txt";
     3: w_file_name = "weight3.txt";
     4: w_file_name = "weight4.txt";
     5: w_file_name = "weight5.txt";
     6: w_file_name = "weight6.txt";
     7: w_file_name = "weight7.txt";
     8: w_file_name = "weight8.txt";
    endcase
    

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

    /////// Kernel data writing to memory ///////
    // Load the weights into core.v's ACTIVATION_WEIGHTS_sram

    A_xmem = 11'b10000000000; // Starting at address 1024 the weights are loaded

    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem);  
      /* ALPHA: Formal Intensive Verification */ 
      // wgt_memory[kij] = $unsigned($random); // Loads arbitrary 32 bitstream 
      // D_xmem = wgt_memory[kij]; 

      WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1; 
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 

    /////// Kernel data writing to L0 /////// 
    // Make ACTIVATION_WEIGHTS_sram give the weights to the L0
    A_xmem = 11'b10000000000; // Since the weights are loaded at address 1024, make sure we start there
    #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0;
    #0.5 clk = 1'b1; 
    for (t=0; t<col +1; t=t+1) begin  
      #0.5 clk = 1'b0; l0_wr = 1; if (t>0) A_xmem = A_xmem + 1; 
      #0.5 clk = 1'b1;  
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;// CHIP UNENABLE
    #0.5 clk = 1'b1; 

    /////// Kernel loading to PEs ///////
    // L0 pass the weights to PE
    #0.5 clk = 1'b0; l0_rd = 1; 
    #0.5 clk = 1'b1; //Need one cycle for L0 to propogate signal to first column
    for (t=0; t< col + row; t=t+1) begin // Takes 8 + 8 cycles for weights to propagate
      #0.5 clk = 1'b0; load = 1;
      #0.5 clk = 1'b1;  
    end
    // #0.5 clk = 1'b0; #0.5 clk = 1'b1;

    ////// provide some intermission to clear up the kernel loading ///
    #0.5 clk = 1'b0;  l0_rd = 0; load = 0; 
    #0.5 clk = 1'b1;  
  
    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
    /////////////////////////////////////



    /////// Whole Activation processing cycle ///////
    /*
    1) SRAM(activation) -> L0
    2) L0 -> PE (execute)
    3) Is there a complete row in OFIFO filled? 
      Yes: Accumulate
    4) Repeat
    5) Store output in PSUM SRAM
    */
    //preload one activation into L0
    #0.5 clk = 1'b0; 
    A_xmem = 0; // Starting at address 0 the activations are loaded
    A_pmem = 0;
    l0_wr = 1; l0_rd = 1;
    WEN_xmem = 1; CEN_xmem = 0;
    #0.5 clk = 1'b1; 
    skippedFirst = 0;
    nij = -1;
    for (t=0; t<len_nij + col + row + 1; t=t+1) begin  // 36 + 8 + 8 = 52
      #0.5 clk = 1'b0; 
      if(t<len_nij) begin

        A_xmem = A_xmem + 1; // Increment for SRAM -> L0
        l0_rd = 1; execute = 1; // L0 -> PE  
      end
      else begin
        l0_rd = 0; execute = 0; // L0 -> PE : 44 --> 52
      end
      // Read from OFIFO - Accumulate step
      // t = 8 first ofifo slot full, t = 16 ofifo full read/accum, t = 36 + 16 = 52 

      if (ofifo_valid) begin // read a complete row from OFIFO
        CEN_pmem = 0; // Activate PMEM
        ofifo_rd = 1;
        nij = nij + 1;
        o_nij_index = onij(nij, kij);

        if (kij == 0) begin  
          sfu_passthrough = 1; // make SFU pass first KIJ index; ofifo goes to psum sram
          acc = 0;
        end else begin
          sfu_passthrough = 0;
          acc = 1;
        end
        
        if(o_nij_index >= 0 && o_nij_index < 16) begin 
          if (o_nij_index > 0) begin 
            WEN_pmem = 1; // Write to last APMEM (delay write by one clock cycle via register)
          end
          A_pmem = o_nij_index;
        end else begin
          CEN_pmem = 1;
        end 
        if (t == 34)begin 
          // Last `t` before goes all X: all start at 18
          // 0: 52, 1-2: 34, 3-5: 35; 6-8: 36
          $timeformat(-9, 2, " ns", 20); // Unit in ns (-9), 2 decimal places, " ns" suffix, field width 20 
          $display("kij = %d, sfpout: %16b sfpout: %d time: %t", kij, sfp_out[15:0],sfp_out[15:0], $time);
        end
        // $timeformat(-9, 2, " ns", 20); // Unit in ns (-9), 2 decimal places, " ns" suffix, field width 20 
        // $display("t: %d, kij = %d, sfpout: %16b sfpout: %d time: %t", t, kij, sfp_out[15:0],sfp_out[15:0], $time);          
      end

        #0.5 clk = 1'b1; 
    end
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1; #0.5 clk = 1'b0; #0.5 clk = 1'b1; #0.5 clk = 1'b0; //TWO CLOCK CYCLES TO HIT THE LAST NIJ VALUES
    CEN_xmem = 1; // Disable SRAM weights/activation
    CEN_pmem = 1; // Disable SRAM psum 
    WEN_pmem = 0;
    acc = 0;
    l0_wr = 0; // Disable L0 writing
    l0_rd = 0; execute = 0; // Disable L0 and PE execute
    ofifo_rd = 0; // Disable ofifo reading
    #0.5 clk = 1'b1; #0.5 clk = 1'b0; #0.5 clk = 1'b1;
    // $timeformat(-9, 2, " ns", 20); // Unit in ns (-9), 2 decimal places, " ns" suffix, field width 20 
    // $display("kij = %d, sfpout: %16b sfpout: %d time: %t", kij, sfp_out[15:0],sfp_out[15:0], $time);
    /////////////////////////////////////

  end  // end of kij loop


  ////////// Accumulation /////////
  out_file = $fopen("out.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start during accumulation #############"); 
  // RIGHT NOW, THE ADDRESS BUFFERING IS WEIRD AS SHIT. WILL SHIFT DELAY TO THE OFIFO IDEALLY.
  #0.5 clk = 1'b0; 
  #0.5 clk = 1'b1; 
  #0.5 clk = 1'b0; 
  for (i=0; i<len_onij; i=i+1) begin 
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
   
 
    // #0.5 clk = 1'b0; reset = 1;
    // #0.5 clk = 1'b1;  
    // #0.5 clk = 1'b0; reset = 0; 
    // #0.5 clk = 1'b1;  
    
    // acc_file = $fopen("activation_tile0.txt", "r");

    //   // Following three lines are to remove the first three comment lines of the file
    //   out_scan_file = $fscanf(out_file,"%s", answer); 
    //   out_scan_file = $fscanf(out_file,"%s", answer); 
    //   out_scan_file = $fscanf(out_file,"%s", answer); 

    // for (j=0; j<len_kij+1; j=j+1) begin 

    //   #0.5 clk = 1'b0;   
    //     if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
    //                    else  begin CEN_pmem = 1; WEN_pmem = 1; end

    //     if (j>0)  acc = 1;  
    //   #0.5 clk = 1'b1;   
    // end

    // #0.5 clk = 1'b0; acc = 0;
    // #0.5 clk = 1'b1; 
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end
  else begin
    $display("############ %d errors detected. ############", error);
  end

  // $fclose(acc_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;
end


// always @ (posedge clk) begin
//    D_xmem_q   <= D_xmem;
//    CEN_xmem_q <= CEN_xmem;
//    WEN_xmem_q <= WEN_xmem;
//    A_pmem_q   <= A_pmem;
//    CEN_pmem_q <= CEN_pmem;
//    WEN_pmem_q <= WEN_pmem;
//    REN_pmem_q <= REN_pmem;
//    A_xmem_q   <= A_xmem;
//    ofifo_rd_q <= ofifo_rd;
//    acc_q      <= acc;
//    ififo_wr_q <= ififo_wr;
//    ififo_rd_q <= ififo_rd;
//    l0_rd_q    <= l0_rd;
//    l0_wr_q    <= l0_wr ;
//    execute_q  <= execute;
//    load_q     <= load;
//    sfu_passthrough_q <= sfu_passthrough;
// end


endmodule




