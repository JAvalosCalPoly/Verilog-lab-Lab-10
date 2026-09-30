
module top_vga(
			   input wire	     clk, // 100 MHz board clock on Nexys A7
			   input wire	     rst, // Active-high reset
            input wire [3:0] move_dir,
			   // VGA outputs
			   output wire [3:0] vgaRed,
			   output wire [3:0] vgaGreen,
			   output wire [3:0] vgaBlue,
			   output wire	     hsync,
			   output wire	     vsync
			   );

   wire [9:0] hcount;
   wire [9:0] vcount;
   wire	      hblank;
   wire	      vblank;
   wire	      pixpulse;
   wire	      is_a_wall, empty, draw_ball;

   wire	      move;
   reg [11:0] current_pixel;
   reg vblank_d1;


   wire [23:0] draw_block;
   wire [23:0] broken;
   wire any_block;
   wire unbreak;

   assign unbreak = &broken;  // all blocks are broken, so reset them all

   assign any_block = |draw_block;
   assign all_broken = &broken;

   wire draw_paddle;

   wire [9:0] paddle_xloc, paddle_yloc;

   wire ballEmpty;
   wire blockEmpty;
   wire paddleEmpty;

   localparam WALL_COLOR = 12'h00f;
   localparam BALL_COLOR = 12'h0f0;
   localparam EMPTY_COLOR = 12'h700;
   
   //---------------------------------------------
   // VGA Timing Generator
   //---------------------------------------------
   vga_timing vga_gen (
		       .clk    (clk),
		       .pixpulse (pixpulse),
		       .rst    (rst),  //active high
		       .hcount (hcount[9:0]),
		       .vcount (vcount[9:0]),
		       .hsync  (hsync),
		       .vsync  (vsync),
		       .hblank (hblank),
		       .vblank (vblank)
		       ); 

             paddle #(320,400,5,2) u_paddle (
   .clk(clk),
   .pixpulse(pixpulse),
   .rst(rst),
   .hcount(hcount),
   .vcount(vcount),
   .empty(paddleEmpty),
   .move(move),
   .move_dir(move_dir),
   .draw_paddle(draw_paddle),
   .xloc(paddle_xloc),
   .yloc(paddle_yloc)
);
//        calculate score
   wire draw_score;

   reg [7:0] score_value;
   integer i;
   always @(*) begin
   score_value = 0;
   for (i = 0; i < 24; i = i + 1)
      score_value = score_value + broken[i];
end
   score #(40,40) u_score (
		   // Outputs
		   .draw_score (draw_score),
		   // Inputs
		   .clk		(clk),
		   .pixpulse	(pixpulse),
		   .rst		(rst),
		   .hcount	(hcount[9:0]),
		   .vcount	(vcount[9:0]),
		   .score	(score_value)  // score starts at 0
		   );

   //add 24 in two rows of 12
  genvar row, col;
generate
   for (row = 0; row < 2; row = row + 1) begin : ROWS
      for (col = 0; col < 12; col = col + 1) begin : COLS
         block #(
            .xloc       (col * 50 + 40),   // was col * 20 + 10
            .yloc       (row * 30 + 70),   // keep blocks below the score
            .xsize_div_2(20),
            .ysize_div_2(10)
         ) blok (
            .clk        (clk),
            .pixpulse   (pixpulse),
            .rst        (rst),
            .hcount     (hcount),
            .vcount     (vcount),
            .empty      (blockEmpty),      
            .move       (move),
            .unbreak    (unbreak),
            .draw_block (draw_block[row * 12 + col]),
            .broken     (broken[row * 12 + col])
         );
      end
   end
endgenerate

   ball #(320,240,0,0) u_ball_1 ( 
		  // Outputs
		  .draw_ball		(draw_ball),
		  .xloc			(),
		  .yloc			(),
		  // Inputs
		  .clk			(clk),
		  .pixpulse             (pixpulse),
		  .rst			(rst),
		  .hcount		(hcount[9:0]),
		  .vcount		(vcount[9:0]),
		  .empty		(ballEmpty),
		  .move			(move));
      //      ball #(100,40,0,0) u_ball_2 ( 
		//   // Outputs
		//   .draw_ball		(draw_ball),
		//   .xloc			(),
		//   .yloc			(),
		//   // Inputs
		//   .clk			(clk),
		//   .pixpulse             (pixpulse),
		//   .rst			(rst),
		//   .hcount		(hcount[9:0]),
		//   .vcount		(vcount[9:0]),
		//   .empty		(empty & ~draw_ball2),
		//   .move			(move));

   // big_ball #(100,100,0,-1) u_ball_3 (
   //       // Outputs
   //       .draw_ball		(draw_ball2),
   //       .xloc			(),
   //       .yloc			(),
   //       // Inputs
   //       .clk			(clk),
   //       .pixpulse             (pixpulse),
   //       .rst			(rst),
   //       .hcount		(hcount[9:0]),
   //       .vcount		(vcount[9:0]),
   //       .empty		(empty & ~draw_ball),
   //       .move			(move));  
         //    big_ball #(100,50,0,-1) u_ball_4 (
         // // Outputs
         // .draw_ball		(draw_ball2),
         // .xloc			(),
         // .yloc			(),
         // // Inputs
         // .clk			(clk),
         // .pixpulse             (pixpulse),
         // .rst			(rst),
         // .hcount		(hcount[9:0]),
         // .vcount		(vcount[9:0]),
         // .empty		(empty & ~draw_ball),
         // .move			(move));    
   
   assign is_a_wall = ((hcount < 5) | (hcount > 625) | (vcount < 5) | (vcount > 475));

   // assign empty = ~is_a_wall & ~any_block;
   //assign empty = ~is_a_wall & ~any_block & ~draw_paddle;
   assign blockEmpty = ~(is_a_wall | draw_ball | draw_paddle);
   assign paddleEmpty = ~is_a_wall;
   assign ballEmpty = ~(is_a_wall | any_block | draw_paddle);
   assign move = (vblank & ~vblank_d1);  // move balls at start of vertical blanking

   always @(posedge clk or posedge rst) begin
      if (rst) begin
	 vblank_d1 <= 0;
      end else if (pixpulse) begin
         vblank_d1 <= vblank;
      end
   end
   
   // Register the current pixel
   always @(posedge clk) begin
   if (pixpulse)
      current_pixel <= (is_a_wall)                ? WALL_COLOR  :
                       (any_block)                ? 12'hff0     : // yellow
                       (draw_paddle)              ? 12'h0ff     : // cyan
                       (draw_ball)                ? BALL_COLOR  :
                       (draw_score)               ? 12'hfff     : // white
                                                    EMPTY_COLOR;
   end
   // Map 12-bit to 4:4:4
   assign vgaRed   = (~hblank && ~vblank) ? current_pixel[11:8] : 4'b0;
   assign vgaGreen = (~hblank && ~vblank) ? current_pixel[7:4] : 4'b0;
   assign vgaBlue  = (~hblank && ~vblank) ? current_pixel[3:0] : 4'b0;
   
endmodule
   
