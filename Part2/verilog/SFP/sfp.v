// Reads from PSUM SRAM and read from Output FIFO
// sfp_out --> PSUM_SRAM
module sfp(psum_in, ofifo_in, accum, sfp_out, passthrough);
// module sfp(psum_in, ofifo_in, accum, actFunc, sfp_out, passthrough);

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;

    input [psum_bw-1:0] psum_in, ofifo_in; 
    // input signed [psum_bw-1:0] psum_in, ofifo_in;
    input accum; 
    // input [1:0] actFunc;
    output [psum_bw-1:0] sfp_out;
    input passthrough;

    reg [psum_bw-1:0] sum;

assign sfp_out =
    passthrough  ? ofifo_in :                   // passthrough path
    accum        ? (psum_in + ofifo_in) :       // accumulation
                   (psum_in < 0 ? 0 : psum_in); // ReLU
//  accum        ? (psum_in + ofifo_in) :
//  actFunc[0]   ?  (psum_in < 0 ? 0 : psum_in) : // ReLU
//                   (psum_in < 0 ? psum_in >> 6 : psum_in); Leaky ReLU with alpha = 0.015625 
                   
    
    
    // accum        ? (psum_in&{psum_bw{~passthrough}} + ofifo_in) : psum_in

endmodule