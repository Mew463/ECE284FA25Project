// Reads from PSUM SRAM and read from Output FIFO
// sfp_out --> PSUM_SRAM
// module sfp(psum_in, ofifo_in, accum, sfp_out, passthrough);
module sfp(psum_in, ofifo_in, accum, actFunc, sfp_out, passthrough);

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;

    input [psum_bw-1:0] psum_in, ofifo_in; 
    // input signed [psum_bw-1:0] psum_in, ofifo_in;
    input accum; 
    input [1:0] actFunc;
    output [psum_bw-1:0] sfp_out;
    input passthrough;

    wire [psum_bw-1:0] mask = {6'b111111, {(psum_bw-6){1'b0}}};

assign sfp_out =
    actFunc[1] ? psum_in : // if actFunc[1] == 1, then just read.
    passthrough  ? ofifo_in :                   // passthrough path
        accum        ? (psum_in + ofifo_in) :       // accumulation or ReLUs 
            (psum_in[psum_bw-1] == 1) ? // check if negative
                (
                    actFunc[0] ? ((psum_in >> 6) | mask) : 0
                ) : // Leaky ReLu or ReLU
                        // 1: Leaky ReLU with alpha = 0.015625 
                        // 0: Normal ReLU --> 0 
                psum_in; // psum > 0 --> psum
endmodule