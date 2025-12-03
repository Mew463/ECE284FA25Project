// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w; 
  input  [1:0] inst_w; // inst[1]:execute, inst[0]: kernel loading
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;


  reg    [2*row-1:0] inst_w_temp; //Importantly, the instruction is passed north to south, 
  wire   [psum_bw*col*(row+1)-1:0] temp;
  wire   [row*col-1:0] valid_temp;


  genvar i;
 
  assign out_s = temp[psum_bw*col*row +: psum_bw*col];
  assign temp[0 +: psum_bw*col] = 0;
  assign valid = valid_temp[col*(row-1) +: col];
  generate
  for (i=1; i < row+1 ; i=i+1) begin : row_num
    mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
    .clk(clk),
    .reset(reset),
	  .in_w(in_w[bw*(i-1) +: bw]),
	  .inst_w(inst_w_temp[2*(i-1) +: 2]),
	  .in_n(temp[psum_bw*col*(i-1) +: psum_bw*col]),
    .valid(valid_temp[col*(i-1) +: col]),
	  .out_s(temp[psum_bw*col*i +: psum_bw*col])
    );
  end
  endgenerate

  always @ (posedge clk) begin


    //valid <= valid_temp[row*col-1:row*col-8];
    inst_w_temp[1:0]   <= inst_w; 
    inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
    inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
    inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
    inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
    inst_w_temp[11:10] <= inst_w_temp[9:8]; 
    inst_w_temp[13:12] <= inst_w_temp[11:10]; 
    inst_w_temp[15:14] <= inst_w_temp[13:12]; 

    // Potential alpha??
    // inst_w_temp[1:0]   <= inst_w; 
    // inst_w_temp[3:2]   <= inst_w;
    // inst_w_temp[5:4]   <= inst_w;
    // inst_w_temp[7:6]   <= inst_w;
    // inst_w_temp[9:8]   <= inst_w;
    // inst_w_temp[11:10] <= inst_w;
    // inst_w_temp[13:12] <= inst_w; 
    // inst_w_temp[15:14] <= inst_w; 

  end



endmodule