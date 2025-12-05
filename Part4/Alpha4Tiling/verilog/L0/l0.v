// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module l0 (clk, in, out, rd, wr, o_full, reset, o_ready, all_row_at_a_time);

  parameter row  = 8;
  parameter bw = 4;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  [row*bw-1:0] in;
  input all_row_at_a_time; // Seems unnecessary
  output [row*bw-1:0] out;
  output o_full; // Enabled if ANY of the slots are full
  output o_ready; // Informs that there is at least a room to receive a new vector

  wire [row-1:0] empty;
  wire [row-1:0] full;
  reg [row-1:0] rd_en;
  
  genvar i;

  assign o_ready = ~(|full) ; // If they are all not full, then o_ready is true (we can take another vector)
  assign o_full  = |full; // Reduction OR, basically just OR everything together

   generate
  for (i=0; i<row ; i=i+1) begin : row_num
      fifo_depth64 #(.bw(bw)) fifo_instance (
	   .rd_clk(clk),
      .wr_clk(clk),
      .rd(rd_en[i]),
      .wr(wr), // Hope this is right
      .o_empty(empty[i]),
      .o_full(full[i]),
      .in(in[(i+1)*bw-1:i*bw]), // Hope these two are also right
      .out(out[(i+1)*bw-1:i*bw]),
      .reset(reset));
  end
   endgenerate

  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 8'b00000000;
   end
   else
      if (all_row_at_a_time) begin
         /////////////// version1: read all row at a time ////////////////
         if (rd) begin 
            rd_en <= 8'b11111111;
         end
         else begin 
            rd_en <= 8'b0;
         end
      end 
      else begin // probably always going to be using the below case
         //////////////// version2: read 1 row at a time /////////////////
         if (rd) begin 
            rd_en <= {rd_en[row-2:0], 1'b1};
         end
         else begin 
            rd_en <= {rd_en[row-2:0], 1'b0};
         end
      end

    end

endmodule
