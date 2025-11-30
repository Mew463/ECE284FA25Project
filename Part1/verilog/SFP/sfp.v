// Reads from PSUM SRAM and read from Output FIFO
// sfp_out --> PSUM_SRAM
module sfp(psum_in, ofifo_in, accum, sfp_out );

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;

    input [psum_bw-1:0] psum_in, ofifo_in;
    input accum;
    output [psum_bw-1:0] sfp_out;

    reg [psum_bw-1:0] sum;

    assign sfp_out = accum ? 
        psum_in + ofifo_in : // Accumulator
        (psum_in < 0 ? 0 : psum_in); // ReLU
    

endmodule