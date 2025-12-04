module core(clk, inst, ofifo_valid, D_xmem, sfp_out, reset);

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;
    parameter col = 8; //output columns
    parameter row = 8; //input channels

    input clk;
    input [63:0] inst; // instruction to handle everything
    output ofifo_valid; 
    input [bw*row-1:0] D_xmem; // Handles weight and activation data 
    output [col*psum_bw-1:0] sfp_out; // Final output
    input reset;

    wire  [psum_bw*col-1:0] D_xmem_128_bit; 
    wire  [col*psum_bw-1:0] ofifo_out;
    wire  [col*psum_bw-1:0] sram_in;
    reg   [col*psum_bw-1:0] sram_in_reg;
    wire  [col*psum_bw-1:0] sram_out;
    reg   [col*psum_bw-1:0] sram_out_reg;
    wire  [psum_bw*col-1:0] out_s;

    // Expand the instruction bus from the core_tb
    wire debug = inst[63];
    // wire[1:0] actFunc = inst_q[37:36];
    wire pass_psum = inst[39];
    wire recall_psum = inst[38];
    wire l1_wr    = inst[37];
    wire output_stationary = inst[36];
    wire REN_pmem = inst[35];
    wire passthrough = inst[34];
    wire acc        = inst[33];
    wire CEN_pmem   = inst[32];
    wire WEN_pmem   = inst[31];
    wire [10:0] A_pmem = inst[30:20];
    wire CEN_xmem   = inst[19];
    wire WEN_xmem   = inst[18];
    wire [10:0] A_xmem = inst[17:7];
    wire ofifo_rd   = inst[6];
    wire ififo_wr   = inst[5];
    wire ififo_rd   = inst[4];
    wire l0_rd      = inst[3];
    wire l0_wr      = inst[2];
    wire execute    = inst[1];
    wire load       = inst[0];

    wire [psum_bw*col-1:0] sram_l0_bridge; 
    wire [row*bw-1:0] l0_mac_bridge;
    wire [psum_bw*col-1:0] sram_l1_bridge; 
    wire [psum_bw*col-1:0] l1_mac_bridge;
    wire [row*bw-1:0] l1_output;

    wire ofifo_full, ofifo_ready, ofifo_valid;
    wire [col-1:0] mac_ofifo_valid_bridge;
    ofifo outputfifo (
        .clk(clk),
        .in(out_s),
        .out(ofifo_out),
        .rd(ofifo_rd),
        .wr(mac_ofifo_valid_bridge),
        .o_full(ofifo_full),
        .reset(reset),
        .o_ready(ofifo_ready),
        .o_valid(ofifo_valid)
    );

    genvar k;
    wire [127:0] expanded;
    generate
        for (k = 0; k < 8; k = k + 1) begin
            assign expanded[(k+1)*16-1 : k*16] = {12'b0, l1_output[k*4 +: 4]};
        end
    endgenerate

    assign l1_mac_bridge = output_stationary ? expanded : {psum_bw*col{1'b0}};
    // assign l1_mac_bridge = output_stationary ? l1_output:{psum_bw*col{1'b0}}; // needs to change
    mac_array macarray (
        .clk(clk),
        .reset(reset),
        .out_s(out_s),
        .in_w(l0_mac_bridge),
        .in_n(l1_mac_bridge), // This should be l1_mac_bridge for output stationary mapping 
        .inst_w({execute, load}),
        .valid(mac_ofifo_valid_bridge),
        .weight_stationary(!output_stationary), // This is annoying that the testbench uses output stationary wording
        .pass_psum(pass_psum),
        .recall_psum(recall_psum));

    sram_32b_w2048_read_write PSUM_sram (
        .CLK(clk),
        .D(sram_in), // input data
        .Q(sram_out),  // output data
        .CEN(CEN_pmem), // clock enable (when high, don't write)
        .REN(REN_pmem), // When high, read
        .WEN(WEN_pmem), // When high, write 
        .A(A_pmem) // Read pointer is always one ahead of the write pointer
    );
    
    assign D_xmem_128_bit = {{96{1'b0}}, D_xmem};
    sram_32b_w2048 ACTIVATION_WEIGHTS_sram (
        .CLK(clk),
        .D(D_xmem_128_bit), // input data
        .Q(sram_l0_bridge),  // output data
        .CEN(CEN_xmem), // clock enable (when high, do nothing)
        .WEN(WEN_xmem), // write enable (when low, write to address)
        .A(A_xmem) // Address
    );



    wire l0_o_full, l0_o_ready;
    wire l1_o_full, l1_o_ready;

    // reg all_row_at_a_time;
    l0 WEST_l0 (
        .clk(clk),
        .in(sram_l0_bridge[row*bw-1:0]),
        .out(l0_mac_bridge),
        .rd(l0_rd),
        .wr(l0_wr),
        .o_full(l0_o_full),
        .reset(reset),
        .o_ready(l0_o_ready),
        .all_row_at_a_time(1'b0) // Dont use for vanilla version (or ever probably)
    );

    l0 NORTH_l0 (
        .clk(clk),
        .in(sram_l0_bridge[row*bw-1:0]),
        .out(l1_output),
        .rd(l0_rd),
        .wr(l1_wr),
        .o_full(l1_o_full),
        .reset(reset),
        .o_ready(l1_o_ready),
        .all_row_at_a_time(1'b0) // Dont use for vanilla version (or ever probably)
    );
    
    genvar sfp_i; 
    for(sfp_i = 1; sfp_i <= col; sfp_i = sfp_i + 1) begin
        sfp SFP(
            .psum_in(sram_out[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .ofifo_in(ofifo_out[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .accum(acc),
            // .actFunc(actFunc),
            .sfp_out(sram_in[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .passthrough(passthrough)
        );
    end
    assign sfp_out = sram_in;
    
    // Kernel data writing to L0
    // assign all_row_at_a_time = load && l0_rd; 
    always @(posedge clk) begin
        if (reset) begin
            sram_in_reg <= 0;
        end
        else begin
            sram_in_reg <= sram_in;
            // if (debug) begin
            //     for 
            // end
        end
        // /*Z
        // *****************************************************************
        // STATE: loading Psum from SRAM and accumulation from OFIFO to SRAM
        // ******************************************************************
        // */

        // // once the ofifo is full --> if(ofifo_full)
        // // Read from PSUM_SRAM 
        // // Read from ofifo 
        // // Write to PSUM_SRAM 
        // reg [10:0] A_pmem_reg;
        // assign A_pmem = A_pmem_reg;
        // reg WEN_pmem_reg;
        // assign WEN_pmem = WEN_pmem_reg;

        // How does OFIFO become empty?
        // if(ofifo_valid) begin // OFIFO is full -> Read inputs for SFP
        //     if(!WEN_pmem) begin
        //     // we wrote this cycle, so read next cycle
        //     // output [col*psum_bw-1:0] sfp_out; // Final output
        //     // wire  [col*psum_bw-1:0] ofifo_out;
        //     // reg  [col*psum_bw-1:0] sram_in;
        //     // wire  [col*psum_bw-1:0] sram_out;
        //         A_pmem_reg <= psum_sram_ptr; // address
                
        //         // ofifo_out[col*psum_bw-1:0] will have value
        //         WEN_pmem_reg <= 1'b1; // read from that address
        //         // sram_out would have a new value now
        //         accumulate <= 1'b1;
                
        //         // SFU will have sram_in data ready to be written
        //     end
        //     else begin // write
        //         WEN_pmem <= 1'b0;
        //     end
        //     psum_sram_ptr <= psum_sram_ptr + 1;
        // end
        // else if(!accumulate && !WEN_pmem) begin
        //     // if()
        //     WEN_pmem <= 1; // read from PSUM_SRAM
        //     accumulate <= 1'b0; // do ReLU
            
        // end
        



        // if(/*state = psum loading or maybe instruction == blahblah*/) begin
        //     if (/*we are ready to sum ofifo into psum*/) begin // accumulate and write to SRAM
        //         // sram_in <= ofifo_out + sram_out_reg;
                
        //     end
        //     else if (/*We are ready to read the SRAM into a temp variable*/) begin // read from SRAM
        //         sram_out_reg <= sram_out;
        //     end
        //     else if (!CEN && !WEN) begin //
                
        //     end
        // end
    end

endmodule

/*
States:

*/