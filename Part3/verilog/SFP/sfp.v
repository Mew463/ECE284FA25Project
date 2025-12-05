// Reads from PSUM SRAM and read from Output FIFO
// sfp_out --> PSUM_SRAM

 module sfp(psum_in, ofifo_in, accum, sfp_out, passthrough, relu );

    parameter bw = 4; //weight and activation width
    parameter psum_bw = 16;

    input signed [psum_bw-1:0] psum_in, ofifo_in; 
    // input signed [psum_bw-1:0] psum_in, ofifo_in;
    input accum, relu; 
    // input [1:0] actFunc;
    output [psum_bw-1:0] sfp_out;
    input passthrough;
    wire [psum_bw-1:0] accumulate = psum_in + ofifo_in;
    // wire [psum_bw-1:0] accumulated;
    // assign accumulated = accum ? psum_in + ofifo_in: psum_in;
    // case ({passthrough, accum, relu})
    //     3'b000: sfp_out = psum_in;
    //     3'b001: sfp_out = (psum_in[psum_bw-1:0] == 0) ? psum_in : 0;
    //     3'b010: 
    // endcase

    function [15:0] sfp_func;
        input passthrough, accum, relu;
        input [15:0] psum_in, ofifo_in, accumulate;
        begin
            case ({passthrough, accum, relu})
                3'b000: sfp_func = psum_in;
                3'b001: sfp_func = psum_in[15] ? 0 : psum_in; // Perform Relu
                3'b010: sfp_func = psum_in + ofifo_in;
                3'b011: sfp_func = accumulate[15] ? 0 : accumulate;  // Accumulate and Relu    
                3'b100: sfp_func = ofifo_in;
                3'b101: sfp_func = ofifo_in[15] ? 0 : ofifo_in;
                default: sfp_func = ofifo_in;   //dunno what case this would be
            endcase
        end
    endfunction

    assign sfp_out = sfp_func(passthrough, accum, relu, psum_in, ofifo_in, accumulate);

    // assign sfp_out =
    //     passthrough  ? ofifo_in :                   // passthrough path
    //     relu        ? (accumulated[psum_bw-1] == 1 ? 0: accumulated) :       // accumulation
    //                 (accumulated); // ReLU

                    
                   //(psum_in[psum_bw-1] == 1 ? 0 : psum_in); // ReLU
//  accum        ? (psum_in + ofifo_in) :
//  actFunc[0]   ?  (psum_in < 0 ? 0 : psum_in) : // ReLU
//                   (psum_in < 0 ? psum_in >> 6 : psum_in); Leaky ReLU with alpha = 0.015625 
                   
    
    
    // accum        ? (psum_in&{psum_bw{~passthrough}} + ofifo_in) : psum_in

endmodule