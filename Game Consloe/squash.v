// horizontal 
`define ha 112		// duration of pulse to VGA_HSYNC signifying end of row of data
`define hb 248		// back porch
`define hc 1280		// horizontal screen size (px)
`define hd 48		// front porch

// vertical
`define va 3		// duration of pulse to VGA_HSYNC signifying end of row of data
`define vb 38		// back porch
`define vc 1024		// vertical screen size (px)
`define vd 1		// front porch

// Ball and bat size & speed parameters
`define ballsize   16
`define ballspeed  5
`define batwidth   16
`define batheight  160
`define batspeed   10
 

module squash(
	clock2_50,
	clock_50,
	key,
	sw,
	vga_r,
	vga_g,
	vga_b,
	vga_clk,
	vga_blank,
	vga_hs,
	vga_vs,
	vga_sync,
	ledr,
	p1_score, high_score,
	winner,
	mode
	);
	
	input clock2_50, clock_50;
	input [1:0] key;
	input [0:0] sw;
	input [0:0] mode;
	output [9:0] vga_r, vga_g, vga_b;
	output vga_clk, vga_blank, vga_hs, vga_vs, vga_sync;
	output [17:0] ledr;
	output [1:0] winner;				// 0 = none, 1 = P1, 2 = P2
	// Scores
	output [3:0] p1_score;
	output [3:0] high_score;
	
	wire video_clock;
	
	// convert CLOCK2_50 to required clock speed
	pll50Mz pll(.inclk0(clock2_50), .c0(video_clock));
	
	assign vga_clk = video_clock;
	assign vga_sync = 0;
	
	wire candraw;
	wire start;		// 1 = beginning of frame
 	
 	wire ball_on;
 	
 	// Location of pixel to draw
	wire [10:0] x;
	wire [10:0] y;
	// Bats locations
	wire [10:0] p_y;
	// Ball location
	wire [10:0] ball_x;
	wire [10:0] ball_y;

	
	assign ledr[17] = (winner > 0);	// light up ledr-17 to alert user to reset game
		

	// VGA output module
	vga sv(
		.clk(video_clock),
		.vsync(vga_vs),
		.hsync(vga_hs),
		.x(x),
		.y(y),
		.can_draw(candraw),
		.start_of_frame(start)
		);

	// Module that renders graphics on-screen 
	squash_graphics sg(
		.clk(video_clock),
		.candraw(candraw),
		.x(x),
		.y(y),
		.p_y(p_y),
		.ball_on(ball_on),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.red(vga_r),
		.green(vga_g),
		.blue(vga_b),
		.vga_blank(vga_blank)
		);
	
	// Game logic module
	squash_gamelogic sgl(
		.clock50(clock_50),
		.video_clock(video_clock),
		.start(start),
		.reset(sw[0]),
		.p_up(~key[1]),
		.p_down(~key[0]),
		.p_y(p_y),
		.ball_on(ball_on),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.p1_score(p1_score),
		.high_score(high_score),
		.winner(winner),
		.mode(mode)
		);
	
	oneshot pulser(
		.pulse_out(read),
		.trigger_in(scan_ready),
		.clk(clock_50)
		);
	
endmodule

// Module that renders graphics on-screen 
// Draws objects pixel by pixel
module squash_graphics(
	clk,
	candraw,
	x,
	y,
	p_y,
	ball_on,
	ball_x,
	ball_y,
	red, 
	green, 
	blue,
	vga_blank
	);

	input clk;
	input candraw;
	input ball_on;
	input [10:0] x, y, p_y, ball_x, ball_y;
	output reg [9:0] red, green, blue;
	output vga_blank;
	
	reg n_vga_blank;
	assign vga_blank = !n_vga_blank;
	
	always @(posedge clk) begin
		if (candraw) begin
			n_vga_blank <= 1'b0;
			// draw wall
			if (x < `batwidth) begin
					// white bat
					red <= 10'b1111111111;
					green <= 10'b1111111111;
					blue <= 10'b1111111111;
			end
			// draw player (right) bat
			else if (x > `hc - `batwidth && y > p_y && y < p_y + `batheight) begin
					// white bat
					red <= 10'b0000000000;
					green <= 10'b1111111111;
					blue <= 10'b1111111111;
			end
			// draw ball
			else if (ball_on && x > ball_x && x < ball_x + `ballsize && y > ball_y && y < ball_y + `ballsize) begin
					// white ball
					red <= 10'b1111111111;
					green <= 10'b1111111111;
					blue <= 10'b1111111111;
			end
			// black background
			else begin
					red <= 10'b0000000000;
					green <= 10'b0000000000;
					blue <= 10'b0000000000;
			end
		end else begin
			// if we are not in the visible area, we must set the screen blank
			n_vga_blank <= 1'b1;
		end
	end
endmodule 


// Counter for incrementing/decrementing bat position within bounds of screen
module squash_batpos(
	clk,
	up,
	down,
	reset,
	speed,
	value,
	mode
	);

	input clk;
	input up, down;				// signal for counting up/down
	input [4:0] speed;			// # of px to increment bats by
	input reset, mode;
	output [10:0] value;		// max value is 1024 (px), 11 bits wide
	
	reg [10:0] value;
	
	initial begin
		value <= `vc / 2;
	end
	
	always @ (posedge clk or posedge reset or posedge mode) begin
		if (reset || mode) begin
			// go back to the middle
			value <= `vc / 2;
		end
		else begin
			if (up) begin
				// prevent bat from going beyond upper bound of the screen
				if ((value - speed) > `va) begin
					// move bat up the screen
					value <= value - speed;
				end
			end
			else if (down) begin
				// prevent bat from going beyond lower bound of the screen
				if ((value + speed) < (`vc - `batheight)) begin
					// move bat down the screen
					value <= value + speed;
				end
			end
		end
	end

endmodule


// Module with counters that determining the ball position
module squash_ballpos(
	clk,
	reset,
	speed,
	dir_x,		// 0 = LEFT, 1 = RIGHT
	dir_y,		// 0 = UP, 1 = DOWN
	value_x,
	value_y,
	mode
	);

	input clk;
	input [4:0] speed;					// # of px to increment bat by
	input reset, mode;
	input dir_x, dir_y;
	output [10:0] value_x, value_y;		// max value is 1024 (px), 11 bits wide
	
	reg [10:0] value_x, value_y;
	
	// the initial position of the ball is at the top of the screen, in the middle,
	initial begin
		value_x <= `hc / 2 - (`ballsize / 2);
		value_y <= `va + 7;
	end
	
	always @ (posedge clk or posedge reset or posedge mode) begin
		if (reset || mode) begin
			value_x <= `hc / 2 - (`ballsize / 2);
			value_y <= `va + 7;
		end
		else begin
			// increment x
			if (dir_x) begin
				// right 
				value_x <= value_x + speed;
			end
			else begin
				// left
				value_x <= value_x - speed;
			end
			
			// increment y
			if (dir_y) begin
				// down
				value_y <= value_y + speed;
			end
			else begin
				// up
				value_y <= value_y - speed;
			end
		end
	end

endmodule


// Ball collision detection module
// Detects collisions between the ball and the bats and walls and
// determines what direction the ball should go
module squash_ballcollisions(
	clk,
	reset,
	p_y,
	ball_x,
	ball_y,
	dir_x,
	dir_y,
	oob,	// whether ball is out of bounds
	hit,
	mode
	);
	
	input clk, reset, mode;
	input [10:0] p_y, ball_x, ball_y;
	output dir_x, dir_y, oob, hit;
		
	reg dir_x, dir_y, oob, hit;
	initial begin
		dir_x <= 0;
		dir_y <= 1;
		oob <= 0;
		hit <= 0;
	end
		
	always @ (posedge clk) begin
		if (reset || mode) begin
			dir_x <= 0;
			dir_y <= 1;
			oob <= 0;
			hit <= 0;
		end
		else begin
			// out of bounds (i.e. one of the players missed the ball)
			if (ball_x <= 0 || ball_x >= `hc) begin
				oob = 1;
			end
			else begin
				oob = 0;
				hit <= 0;
			end
			
			// collision with top & bottom walls
			if (ball_y <= `va + 5) begin
				dir_y = 1;
			end
			if (ball_y >= `vc - `ballsize) begin
				dir_y = 0;
			end
			
			// collision with wall
			if (ball_x <= `batwidth && ball_y) begin
			
				dir_x = 1;	// reverse direction
				hit <= 1;
				
			end
			// collision with bat
			else if (ball_x >= `hc - `batwidth -`ballsize && ball_y + `ballsize <= p_y + `batheight && ball_y >= p_y) begin
				
				dir_x = 0;	// reverse direction
				
				if (ball_y + `ballsize <= p_y + (`batheight / 2)) begin
					// collision with top half of p1 bat, go up
					dir_y = 0;
				end
				else begin
					// collision with bottom half of p1 bat, go down
					dir_y = 1;
				end
			end
		end
	end
	
endmodule


// Game logic module
// Produces the data for output (VGA & HEX) given our inputs
module squash_gamelogic(
	clock50,
	video_clock,
	start,
	reset,	
	p_up,
	p_down,
	p_y,
	ball_on,
	ball_x,
	ball_y,
	p1_score,
	high_score,
	winner,
	mode
	);
	
	input clock50;
	input reset;
	input video_clock;
	input start;
	input p_up, p_down;
	input mode;
	output [10:0] p_y;
	output [10:0] ball_x, ball_y;
	output ball_on;
	output [3:0] p1_score, high_score;
	output [1:0] winner;
	wire [10:0] p_yw, ball_xw, ball_yw;
	
	reg [3:0] p1_score, high_score;	// 0 - 10
	initial begin
		p1_score <= 4'd0000;
		high_score <= 4'd5;
	end
	
	reg [1:0] winner;	// 0 = none, 1 = P1, 2 = P2
	initial begin
		winner <= 0;
	end
	
	reg ball_on;
	initial begin
		ball_on <= 1;
	end
	
	wire dir_x;		// 0 = LEFT, 1 = RIGHT
	wire dir_y;		// 0 = UP, 1 = DOWN
	wire hit;
	
	wire outofbounds;
	reg newround;
	reg [25:0] count_sec;
	reg [1:0] count_secs;



	always @ (posedge clock50) begin
		
		if (outofbounds) begin
			ball_on = 0;
			
			// Second counter
			if (count_sec == 26'd49_999_999) begin
				// 50,000,000 clock cycles per second since we're using clock_50 (50 MHz)
				count_sec = 26'd0;
				count_secs = count_secs + 1;
			end
			else begin
				// Increment every clock cycle
				count_sec = count_sec + 1;
			end
			
			// 2 secs after ball is out of bounds
			if (count_secs == 3