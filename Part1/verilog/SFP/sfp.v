// Reads from PSUM SRAM and read from Output FIFO
// sfp_out --> PSUM_SRAM
module sfp(psum_in, ofifo_in, accum, sfp_out, passthrough);

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;

    input [psum_bw-1:0] psum_in, ofifo_in;
    input accum;
    output [psum_bw-1:0] sfp_out;
    input passthrough;

    reg [psum_bw-1:0] sum;

assign sfp_out =
    accum        ? (psum_in + ofifo_in) :       // accumulation
    passthrough  ? ofifo_in :                   // passthrough path
                   (psum_in < 0 ? 0 : psum_in); // ReLU
    
    
    // accum        ? (psum_in&{psum_bw{~passthrough}} + ofifo_in) : psum_in

endmodule