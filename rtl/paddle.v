// paddle

module paddle #(parameter xloc_start=320,
	      parameter	yloc_start=400,
	      parameter	xsize_div_2 = 5,
	      parameter	ysize_div_2 = 2)
   (
    input	     clk, // 100 MHz system clock
    input	     pixpulse, // every 4 clocks for 25MHz pixel rate
    input	     rst,
    input [9:0]	     hcount, // x-location where we are drawing
    input [9:0]	     vcount, // y-location where we are drawing
    input	     empty, // is this pixel empty
    input	     move, // signal to update the location of the paddle
    input [3:0]	     move_dir, // one hot vector {up,right,down,left}
    output	     draw_paddle, // is the paddle being drawn here?
    output reg [9:0] xloc, // x-location of the paddle
    output reg [9:0] yloc // y-location of the paddle
    );

   reg [ysize_div_2*2:0]			 occupied_lft;
   reg [ysize_div_2*2:0]			 occupied_rgt;
   reg [xsize_div_2*2:0]			 occupied_bot;
   reg [xsize_div_2*2:0]			 occupied_top;

   wire				 blk_lft, blk_rgt;
   wire				 blk_up, blk_dn;
   
   assign draw_paddle = (hcount <= xloc+xsize_div_2) & (hcount >= xloc-xsize_div_2) & 
			(vcount <= yloc+ysize_div_2) & (vcount >= yloc-ysize_div_2) ?  1 : 0;

   // hcount goes from 0=left to 640=right
   // vcount goes from 0=top to 480=bottom
   
   // keep track of the neighboring pixels to detect a collision
   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   occupied_lft <= 0;
	   occupied_rgt <= 0;
	   occupied_bot <= 0;
	   occupied_top <= 0;
	end else if (pixpulse) begin  // only make changes when pixpulse is high
	   if (vcount >= yloc-(ysize_div_2+1) && vcount <= yloc+(ysize_div_2+1)) 
	     if (hcount == xloc+(xsize_div_2+1))
	       occupied_rgt[(yloc-vcount+(ysize_div_2+1))] <= ~empty;  // LSB is at bottom
	     else if (hcount == xloc-(xsize_div_2+1))
	       occupied_lft[(yloc-vcount+(ysize_div_2+1))] <= ~empty;
	      
	   if (hcount >= xloc-(xsize_div_2+1) && hcount <= xloc+(xsize_div_2+1)) 
	     if (vcount == yloc+(ysize_div_2+1))
	       occupied_bot[(xloc-hcount+(xsize_div_2+1))] <= ~empty;  // LSB is at right
	     else if (vcount == yloc-(ysize_div_2+1))
	       occupied_top[(xloc-hcount+(xsize_div_2+1))] <= ~empty;
	end
     end	      

   assign blk_lft = |occupied_lft;  // upper left pixels are blocked
   assign blk_rgt = |occupied_rgt;  // upper right pixels are blocked

   assign blk_up = |occupied_top;  // left-side top pixels are blocked
   assign blk_dn = |occupied_bot;  // left-side bottom pixels are blocked

   always @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   xloc <= xloc_start;
	   yloc <= yloc_start;
	end else if (pixpulse) begin
	   if (move) begin
	      case (move_dir)
		4'b0001: begin  // heading to left
		   if (~blk_lft) begin
		      xloc <= xloc - 1;
		   end
		end
		4'b0010: begin  // heading down
		   if (~blk_dn) begin
		      yloc <= yloc + 1;
		   end
		end
		4'b0100: begin  // heading to right
		   if (~blk_rgt) begin
		      xloc <= xloc + 1;
		   end
		end
		4'b1000: begin  // heading up
		   if (~blk_up) begin
		      yloc <= yloc - 1;
		   end
		end
	      endcase 
	   end 
	end 
     end
   
endmodule // paddle
