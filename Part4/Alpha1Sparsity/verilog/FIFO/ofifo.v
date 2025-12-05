// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module ofifo (clk, in, out, rd, wr, o_full, reset, o_ready, o_valid);

  parameter col  = 8;
  parameter bw = 16;

  input  clk;
  input  [col-1:0] wr;
  input  rd;
  input  reset;
  input  [col*bw-1:0] in;
  output [col*bw-1:0] out;
  output o_full;
  output o_ready;
  output o_valid;

  wire [col-1:0] empty;
  wire [col-1:0] full;
  reg  rd_en;
  reg  rd_en_buf;
  reg  rd_en_buf_buf;
  
  genvar i;

  assign o_ready = ~(|full) ;
  assign o_full  = |full ;
  assign o_valid = &(~empty) ;

  generate
  for (i=0; i<col ; i=i+1) begin : col_num
    fifo_depth64 #(.bw(bw)) fifo_instance (
    .rd_clk(clk),
    .wr_clk(clk),
    // .rd(rd),
    .rd(rd_en),
    .wr(wr[i]),
    .o_empty(empty[i]),
    .o_full(full[i]),
    .in(in[(i+1)*bw-1:i*bw]),
    .out(out[(i+1)*bw-1:i*bw]),
    .reset(reset));
  end
  endgenerate

  //assign rd_en = rd;
  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 0;
      rd_en_buf <= 0;
      rd_en_buf_buf <= 0;
   end
   else begin
    rd_en <= rd;
    rd_en_buf <= rd_en;
    rd_en_buf_buf <= rd_en_buf;
    end
   end


endmodule
