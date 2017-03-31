module Game_console(	
	CLOCK2_50,
	CLOCK_50,
	KEY,
	SW,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_CLK,
	VGA_BLANK,
	VGA_HS,
	VGA_VS,
	VGA_SYNC,
	TD_RESET,
	LEDR,
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
	);
	
	input CLOCK2_50, CLOCK_50;
	input [3:0] KEY;
	input [17:0] SW;
	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	output TD_RESET;
	output [17:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	
	wire [9:0] vga_r_1, vga_r_2, vga_g_1, vga_g_2, vga_b_1, vga_b_2;
	wire vga_clk1, vga_blank1, vga_hs1, vga_vs1, vga_sync1, vga_clk2, vga_blank2, vga_hs2, vga_vs2, vga_sync2;
	wire [17:0] ledr1, ledr2;
	wire [3:0] score11, score21, score12, score22, out_score1, out_score2;
	wire [1:0] winner1, winner2, winner_out;
	wire [17:0] led1, led2;
	
	// New instances of games
	pong pong_game(CLOCK2_50, CLOCK_50, KEY[3:0], SW[17],vga_r_1,vga_g_1,vga_b_1,vga_clk1, vga_blank1, vga_hs1, vga_vs1, vga_sync1, led1, score11[3:0], score21[3:0], winner1[1:0], SW[0]);
	squash squash_game(CLOCK2_50, CLOCK_50, KEY[1:0], SW[17],vga_r_2,vga_g_2,vga_b_2,vga_clk2, vga_blank2, vga_hs2, vga_vs2, vga_sync2, led2, score22[3:0], score12[3:0], winner2[1:0], ~SW[0]);
	
	
	// multiplexers for input and output control
	score_mux player1(SW[0], score11, score12, out_score1);
	score_mux player2(SW[0], score21, score22, out_score2);
	
	winner_mux(SW[0], winner1, winner2, winner_out);
	
	vga_mux clk(SW[0],vga_clk1, vga_clk2, VGA_CLK);
	vga_mux blank(SW[0],vga_blank1,vga_blank2, VGA_BLANK);
	vga_mux hs(SW[0],vga_hs1, vga_hs2, VGA_HS);
	vga_mux vs(SW[0],vga_vs1, vga_vs2, VGA_VS);
	vga_mux sync(SW[0],vga_sync1, vga_sync2, VGA_SYNC);
	
	led_mux led(SW[0], led1, led2, LEDR[17:0]);

	vga_rgb_mux vga_r(SW[0], vga_r_1, vga_r_2, VGA_R);
	vga_rgb_mux vga_g(SW[0], vga_g_1, vga_g_2, VGA_G);
	vga_rgb_mux vga_b(SW[0], vga_b_1, vga_b_2, VGA_B);
	
	sevenseg info(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7, out_score1, out_score2, winner_out, SW[0]);
	
	
endmodule


// vga mux that controls the output location
module vga_mux(mode, vga_in1, vga_in2, vga_out);
	input mode;
	input vga_in1, vga_in2;
	output vga_out;
	reg vga_out;
	
	always@(*)
	begin
		case(mode)
			1'b0: vga_out = vga_in1;
			1'b1: vga_out = vga_in2;
		endcase
	end
endmodule

module led_mux(mode, led_in1, led_in2, led_out);
	input mode;
	input [17:0]led_in1, led_in2;
	output [17:0]led_out;
	reg [17:0]led_out;
	
	always@(*)
	begin
		case(mode)
			1'b0: led_out = led_in1;
			1'b1: led_out = led_in2;
		endcase
	end
endmodule

module winner_mux(mode, winner1, winner2, winner_out);
	input mode;
	input [1:0] winner1, winner2;
	output [1:0] winner_out;
	reg [1:0] winner_out;
	
	always@(*)
	begin
		case(mode)
			1'b0: winner_out = winner1;
			1'b1: winner_out = winner2;
		endcase
	end

endmodule

module score_mux(mode, score1, score2, score_out);
	input mode;
	input [3:0] score1, score2;
	output [3:0] score_out;
	reg [3:0] score_out;
	
	always@(*)
	begin
		case(mode)
			1'b0: score_out = score1;
			1'b1: score_out = score2;
		endcase
	end

endmodule

module vga_rgb_mux(mode, vga_in1, vga_in2, vga_out);
	input mode;
	input [9:0] vga_in1, vga_in2;
	output [9:0] vga_out;
	reg [9:0] vga_out;
	
	always@(*)
	begin
		case(mode)
			1'b0: vga_out = vga_in1;
			1'b1: vga_out = vga_in2;
		endcase
	end
endmodule


// Module to output info to the seven-segement displays
module sevenseg(seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7, score_p1, score_p2, winner, mode);
	input [3:0] score_p1, score_p2;								
	input [1:0] winner;				// 0 = none, 1 = P1, 2 = P2
	input mode;
	output [6:0] seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7;
	
	reg [6:0] seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7;
	
	always @ (score_p1 or winner) begin
		
		if (winner > 0) begin
			if(mode == 0) begin
				// Show the winner on hex7 and hex6 (i.e. P1 or P2)
				seg7 = 7'b0001100;				// P
				case (winner)
					2'h1: seg6 = 7'b1111001;	// 1
					2'h2: seg6 = 7'b0100100;	// 2
					default: seg6 = 7'b1111111;
				endcase
			end
			else begin
				seg7 = 7'b1111111;
				case (score_p1)
					4'h0: seg6 = 7'b1000000;
					4'h1: seg6 = 7'b1111001; 
					4'h2: seg6 = 7'b0100100; 
					4'h3: seg6 = 7'b0110000; 
					4'h4: seg6 = 7'b0011001; 	
					4'h5: seg6 = 7'b0010010; 
					4'h6: seg6 = 7'b0000010; 
					4'h7: seg6 = 7'b1111000; 
					4'h8: seg6 = 7'b0000000; 
					4'h9: seg6 = 7'b0011000; 
					default: seg6 = 7'b1111111; 
				endcase
			end	
		end
		
		else begin
			seg7 = 7'b1111111;
			case (score_p1)
					4'h0: seg6 = 7'b1000000;
					4'h1: seg6 = 7'b1111001; 
					4'h2: seg6 = 7'b0100100; 
					4'h3: seg6 = 7'b0110000; 
					4'h4: seg6 = 7'b0011001; 	
					4'h5: seg6 = 7'b0010010; 
					4'h6: seg6 = 7'b0000010; 
					4'h7: seg6 = 7'b1111000; 
					4'h8: seg6 = 7'b0000000; 
					4'h9: seg6 = 7'b0011000; 
					default: seg6 = 7'b1111111; 
			endcase
		end
	end
	
	always @ (score_p2 or winner) begin
		if (winner > 0) begin
			// Unused; blank out
			seg5 = 7'b1111111;
			seg4 = 7'b1111111;
		end
		else begin
			// display different info for the squash game
			if(mode) begin
				seg5 = 7'b1111111;
				case (score_p2)
						default: seg4 = 7'b1111111; 
				endcase
			end
			else begin
			
			seg5 = 7'b1111111;
			case (score_p2)
					4'h0: seg4 = 7'b1000000; 
					4'h1: seg4 = 7'b1111001; 
					4'h2: seg4 = 7'b0100100; 
					4'h3: seg4 = 7'b0110000; 
					4'h4: seg4 = 7'b0011001; 	
					4'h5: seg4 = 7'b0010010; 
					4'h6: seg4 = 7'b0000010; 
					4'h7: seg4 = 7'b1111000; 
					4'h8: seg4 = 7'b0000000; 
					4'h9: seg4 = 7'b0011000; 
					default: seg4 = 7'b1111111; 
			endcase
			end
		end
	end
	
	// Blank out unused displays
	always begin
		seg3 = 7'b1111111;
		seg2 = 7'b1111111;
		seg1 = 7'b1111111;
		seg0 = 7'b1111111;
	end

endmodule

