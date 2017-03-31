// VGA signal params
// horizontal and vertical sync parameters for 1280x1024 at 60Hz 
// using 108MHz video_clock

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
`define ballspeed  3
`define batwidth   16
`define batheight  128
`define batspeed   10
 

// Top level module
module pong(
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
	p1_score, p2_score,
	winner,
	mode
	);
	
	input clock2_50, clock_50;
	input [3:0] key;
	input [0:0] sw;
	input [0:0] mode;
	output [9:0] vga_r, vga_g, vga_b;
	output vga_clk, vga_blank, vga_hs, vga_vs, vga_sync;
	output [17:0] ledr;
	output [1:0] winner;				// 0 = none, 1 = P1, 2 = P2
	// Scores
	output [3:0] p1_score;
	output [3:0] p2_score;
	
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
	wire [10:0] p1_y;
	wire [10:0] p2_y;
	// Ball location
	wire [10:0] ball_x;
	wire [10:0] ball_y;

	
	assign ledr[17] = (winner > 0);	// light up ledr-17 to alert user to reset game
		

	// VGA output module
	vga v(
		.clk(video_clock),
		.vsync(vga_vs),
		.hsync(vga_hs),
		.x(x),
		.y(y),
		.can_draw(candraw),
		.start_of_frame(start)
		);

	// Module that renders graphics on-screen 
	graphics g(
		.clk(video_clock),
		.candraw(candraw),
		.x(x),
		.y(y),
		.p1_y(p1_y),
		.p2_y(p2_y),
		.ball_on(ball_on),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.red(vga_r),
		.green(vga_g),
		.blue(vga_b),
		.vga_blank(vga_blank)
		);
	
	// Game logic module
	gamelogic gl(
		.clock50(clock_50),
		.video_clock(video_clock),
		.start(start),
		.reset(sw[0]),
		.p1_up(~key[3]),
		.p1_down(~key[2]),	
		.p2_up(~key[1]),
		.p2_down(~key[0]),
		.p1_y(p1_y),
		.p2_y(p2_y),
		.ball_on(ball_on),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.p1_score(p1_score),
		.p2_score(p2_score),
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
module graphics(
	clk,
	candraw,
	x,
	y,
	p1_y,
	p2_y,
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
	input [10:0] x, y, p1_y, p2_y, ball_x, ball_y;
	output reg [9:0] red, green, blue;
	output vga_blank;
	
	reg n_vga_blank;
	assign vga_blank = !n_vga_blank;
	
	always @(posedge clk) begin
		if (candraw) begin
			n_vga_blank <= 1'b0;
			// draw P1 (left) bat
			if (x < `batwidth && y > p1_y && y < p1_y + `batheight) begin
					// white bat
					red <= 10'b1111111111;
					green <= 10'b0000000000;
					blue <= 10'b0000000000;
			end
			// draw P2 (right) bat
			else if (x > `hc - `batwidth && y > p2_y && y < p2_y + `batheight) begin
					// white bat
					red <= 10'b0000000000;
					green <= 10'b0000000000;
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


// VGA output module
// Controls the output parameters
// Credit: https://www.cl.cam.ac.uk/teaching/1011/ECAD+Arch/files/params.sv
module vga(
	clk,
	vsync,
	hsync,
	x,
	y,
	can_draw,
	start_of_frame
	); 
	
	input clk;
	output vsync, hsync;
	output [10:0] x, y;
	output can_draw;
	output start_of_frame;

	assign x = h - `ha - `hb;
	assign y = v - `va - `vb;
	assign can_draw = (h >= (`ha + `hb)) && (h < (`ha + `hb + `hc))
				   && (v >= (`va + `vb)) && (v < (`va + `vb + `vc));
	assign vsync = vga_vsync;
	assign hsync = vga_hsync;
	assign start_of_frame = startframe;

	// horizontal and vertical counts
	reg [10:0] h;
	reg [10:0] v;
	reg vga_vsync;
	reg vga_hsync;
	reg startframe;
	
	always @(posedge clk) begin
	    // if we are not at the end of a row, increment h
		if (h < (`ha + `hb + `hc + `hd)) begin
			h <= h + 11'd1;
		// otherwise set h = 0 and increment v (unless we are at the bottom of the screen)
		end else begin
			h <= 11'd0;
			v <= (v < (`va + `vb + `vc + `vd)) ? v + 11'd1 : 11'd0;
		end
		vga_hsync <= h > `ha;
		vga_vsync <= v > `va;
		
		startframe <= (h == 11'd0) && (v == 11'd0);
	end
endmodule 


// Counter for incrementing/decrementing bat position within bounds of screen
module batpos(
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
module ballpos(
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
module ballcollisions(
	clk,
	reset,
	p1_y,
	p2_y,
	ball_x,
	ball_y,
	dir_x,
	dir_y,
	oob,	// whether ball is out of bounds
	mode
	);
	
	input clk, reset, mode;
	input [10:0] p1_y, p2_y, ball_x, ball_y;
	output dir_x, dir_y, oob;
		
	reg dir_x, dir_y, oob;
	initial begin
		dir_x <= 0;
		dir_y <= 1;
		oob <= 0;
	end
		
	always @ (posedge clk) begin
		if (reset || mode) begin
			dir_x <= ~dir_x;	// alternate starting direction every round
			dir_y <= 1;
			oob <= 0;
		end
		else begin
			// out of bounds (i.e. one of the players missed the ball)
			if (ball_x <= 0 || ball_x >= `hc) begin
				oob = 1;
			end
			else begin
				oob = 0;
			end
			
			// collision with top & bottom walls
			if (ball_y <= `va + 5) begin
				dir_y = 1;
			end
			if (ball_y >= `vc - `ballsize) begin
				dir_y = 0;
			end
			
			// collision with P1 bat
			if (ball_x <= `batwidth && ball_y + `ballsize >= p1_y && ball_y <= p1_y + `batheight) begin
			
				dir_x = 1;	// reverse direction
		
				if (ball_y + `ballsize <= p1_y + (`batheight / 2)) begin
					// collision with top half of p1 bat, go up
					dir_y = 0;
				end
				else begin
					// collision with bottom half of p1 bat, go down
					dir_y = 1;
				end
			end
			// collision with P2 bat
			else if (ball_x >= `hc - `batwidth -`ballsize && ball_y + `ballsize <= p2_y + `batheight && ball_y >= p2_y) begin
				
				dir_x = 0;	// reverse direction
				
				if (ball_y + `ballsize <= p2_y + (`batheight / 2)) begin
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
module gamelogic(
	clock50,
	video_clock,
	start,
	reset,	
	p1_up,
	p1_down,
	p2_up,
	p2_down,
	p1_y,
	p2_y,
	ball_on,
	ball_x,
	ball_y,
	p1_score,
	p2_score,
	winner,
	mode
	);
	
	input clock50;
	input reset;
	input video_clock;
	input start;
	input p1_up, p1_down, p2_up, p2_down;
	input mode;
	output [10:0] p1_y, p2_y;
	output [10:0] ball_x, ball_y;
	output ball_on;
	output [3:0] p1_score, p2_score;
	output [1:0] winner;
	
	reg [3:0] p1_score, p2_score;	// 0 - 10
	initial begin
		p1_score <= 4'b0;
		p2_score <= 4'b0;
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
			if (count_secs == 3) begin
			
				// Increment the score on the first clock cycle
				// We need to check for this so the score is only incremented ONCE
				if (count_sec == 26'd1) begin
					if (dir_x) begin
						// Out of bounds on the right
						p1_score = p1_score + 1;
					end
					else begin
						// Out of bounds on the left
						p2_score = p2_score + 1;
					end	
				end
				
				// Check if someone has won
				if (p1_score == 4'd10) begin
					winner = 1;
				end
				else if (p2_score == 4'd10) begin
					winner = 2;
				end
				
				// New round
				ball_on = 1;
				newround = 1;
			end
		end
		else begin
			if (newround) begin
				newround = 0;
			end
			count_secs = 1'b0;
			count_sec = 26'd0;
			
			if (reset || mode) begin
				p1_score = 0;
				p2_score = 0;
				winner = 0;
			end
		end
	end
	
	// Module for controlling player 1's bat
	batpos b1 (
		.clk(video_clock && start),
		.up(p1_up),
		.down(p1_down),
		.reset(reset),
		.speed(`batspeed),
		.value(p1_y),
		.mode(mode)
		);
		
	// Module for controlling player 2's bat
	batpos b2 (
		.clk(video_clock && start),
		.up(p2_up),
		.down(p2_down),
		.reset(reset),
		.speed(`batspeed),
		.value(p2_y),
		.mode(mode)
		);
		
	// Ball collision detection module
	ballcollisions bcs (
		.clk(video_clock && start && ball_on),
		.reset(reset || newround),
		.p1_y(p1_y),
		.p2_y(p2_y),
		.ball_x(ball_x),
		.ball_y(ball_y),
		.dir_x(dir_x),
		.dir_y(dir_y),
		.oob(outofbounds),
		.mode(mode)
		);
	
	// Module with counters that determining the ball position
	ballpos bp (
		.clk(video_clock && start && ball_on),
		.reset(reset || newround || (winner > 0)),
		.speed(`ballspeed),
		.dir_x(dir_x),
		.dir_y(dir_y),
		.value_x(ball_x),
		.value_y(ball_y),
		.mode(mode)
		);
	
endmodule
