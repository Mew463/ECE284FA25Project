module core(clk, inst, ofifo_valid, D_xmem, sfp_out, reset);

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;
    parameter col = 8; //output columns
    parameter row = 8; //input channels

    input clk;
    input [33:0] inst; // instruction to handle everything
    input ofifo_valid; 
    input [bw*row-1:0] D_xmem; // Handles weight and activation data 
    output [col*psum_bw-1:0] sfp_out; // Final output
    input reset;


    wire  [col*psum_bw-1:0] ofifo_out;
    reg  [col*psum_bw-1:0] sram_in;
    wire  [col*psum_bw-1:0] sram_out;
    reg  [col*psum_bw-1:0] sram_out_reg;
    wire [psum_bw*col-1:0] out_s;

    // Expand the instruction bus from the core_tb
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


    wire [row*bw-1:0] sram_l0_bridge; 
    wire [row*bw-1:0] l0_mac_bridge;


    wire ofifo_full, ofifo_ready, ofifo_valid;
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

    wire [col-1:0] mac_ofifo_valid_bridge;
    mac_array macarray (
        .clk(clk),
        .reset(reset),
        .out_s(out_s),
        .in_w(l0_mac_bridge),
        .in_n({psum_bw*col{1'b0}}),
        .inst_w({execute, load}),
        .valid(mac_ofifo_valid_bridge)
    );

    //sram_32b_w2048 (clk, D, Q, CEN, WEN, A);

    sram_32b_w2048 PSUM_sram (
        .clk(clk),
        .D(sram_in), // input data
        .Q(sram_out),  // output data
        .CEN(CEN_pmem), // clock enable (when high, do nothing)
        .WEN(WEN_pmem), // write enable (when low, write to address)
        .A(A_pmem) // Address
    );

    sram_32b_w2048 ACTIVATION_WEIGHTS_sram (
        .clk(clk),
        .D(D_xmem), // input data
        .Q(sram_l0_bridge),  // output data
        .CEN(CEN_xmem), // clock enable (when high, do nothing)
        .WEN(WEN_xmem), // write enable (when low, write to address)
        .A(A_xmem) // Address
    );

    wire o_full, o_ready;

    // reg all_row_at_a_time;
    l0 WEST_l0 (
        .clk(clk),
        .in(sram_l0_bridge),
        .out(l0_mac_bridge),
        .rd(l0_rd),
        .wr(l0_wr),
        .o_full(o_full),
        .reset(reset),
        .o_ready(o_ready),
        .all_row_at_a_time(1'b0) // Dont use for vanilla version (or ever probably)
    );
    
    wire accumulate = 1'b1;
    genvar sfp_i; // Could use this variable (and rename) for everything that needs 1 per col
    for(sfp_i = 1; sfp_i <= col; sfp_i += 1) begin
        sfp SFP(
            .psum_in(sram_out[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .ofifo_in(ofifo_out[col*psum_bw-1:0]),
            .accum(accumulate),
            .sfp_out(sram_in[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)])
        );
    end
    assign sfp_out = sram_in;
    
    // Kernel data writing to L0
    // assign all_row_at_a_time = load && l0_rd; 
    always @(posedge clk) begin

        /*
        *****************************************************************
        STATE: RESET
        ******************************************************************
        */

        /*
        *****************************************************************
        STATE: Kernel data writing to L0
        ******************************************************************
        */

        /*
        *****************************************************************
        STATE: loading weights into the mac array
        ******************************************************************
        */

        /*
        *****************************************************************
        STATE: loading weights into the mac array
        ******************************************************************
        */

        /*
        *****************************************************************
        STATE: Mac array execution and OFIFO filling
        ******************************************************************
        */

        /*
        *****************************************************************
        STATE: loading Psum from SRAM and accumulation from OFIFO to SRAM
        ******************************************************************
        */

        // once the ofifo is full --> if(ofifo_full)
        // Read from PSUM_SRAM 
        // Read from ofifo 
        // Write to PSUM_SRAM 
        
        // How does OFIFO become empty?
        if(o_valid) begin // OFIFO is full -> Read inputs for SFP
            if(!WEN_pmem) begin
            // we wrote this cycle, so read next cycle
                A <= // address
                
                // ofifo_out[col*psum_bw-1:0] will have value
                WEN_pmem <= 1'b1; // read from that address
                // sram_out would have a new value now
                accumulate <= 1'b1;
                
                // SFU will have sram_in data ready to be written
            end
            else begin // write
                WEN_pmem <= 1'b0;
            end
            
        end
        else if(o_empty && !WEN_pmem) begin
            WEN_pmem <= 1; // read from PSUM_SRAM
            accumulate <= 1'b0; // do ReLU
        end
        



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