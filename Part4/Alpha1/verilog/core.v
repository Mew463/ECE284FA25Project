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

    mac_array macarray (
        .clk(clk),
        .reset(reset),
        .out_s(out_s),
        .in_w(l0_mac_bridge),
        .in_n({psum_bw*col{1'b0}}),
        .inst_w({execute, load}),
        .valid(mac_ofifo_valid_bridge)
    );

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

    wire o_full, o_ready;

    // reg all_row_at_a_time;
    l0 WEST_l0 (
        .clk(clk),
        .in(sram_l0_bridge[row*bw-1:0]),
        .out(l0_mac_bridge),
        .rd(l0_rd),
        .wr(l0_wr),
        .o_full(o_full),
        .reset(reset),
        .o_ready(o_ready),
        .all_row_at_a_time(1'b0) // Dont use for vanilla version (or ever probably)
    );
    
    genvar sfp_i; 
    for(sfp_i = 1; sfp_i <= col; sfp_i = sfp_i + 1) begin
        sfp SFP(
            .psum_in(sram_out[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .ofifo_in(ofifo_out[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .accum(acc),
            .sfp_out(sram_in[psum_bw*sfp_i - 1: psum_bw*(sfp_i-1)]),
            .passthrough(passthrough)
        );
    end
    assign sfp_out = sram_in;
    
    // Kernel data writing to L0
    always @(posedge clk) begin
        if (reset) begin
            sram_in_reg <= 0;
        end
        else begin
            sram_in_reg <= sram_in;
        end

    end

endmodule