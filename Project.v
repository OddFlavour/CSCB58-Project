// Part 2 skeleton

module project_1
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		LEDR,
		HEX0, HEX1, HEX4, HEX5,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;

	output [17:0] LEDR;
	output [6:0] HEX0, HEX1, HEX4, HEX5;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Reset game state whenever a player's score hits 10
	wire resetn;
	assign resetn = (p1_score == 4'd10 | p2_score == 4'd10) ^ 1'b1;
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
   
	// some clocks
	custom_clk h_clk (1, CLOCK_50, 26'd2, half_clk);
	custom_clk f_clk (1, CLOCK_50, 26'd833_333, sixtyhz_clk);
	
	wire [2:0] state;
	wire sixtyhz_clk, half_clk;
	
	draw_control_center dcc(
		.clk(half_clk),
		.state(state),
		
		.init_x(init_x_out),
		.init_y(init_y_out),
		
		.ui_x(ui_x_out),
		.ui_y(ui_y_out),
		
		.p_x(p_x_out),
		.p_y(p_y_out),
		
		.b_x(b_x_out),
		.b_y(b_y_out),
		
		.x_out(x),
		.y_out(y),
		.colour_out(colour)
		);

    // Instansiate FSM control
    control c0(
		.clk(half_clk),
		.sixtyhz_clk(sixtyhz_clk),
		.resetn(resetn),

		.paddle_control(!SW[3] | !SW[2] | !SW[1] | !SW[0]),
		
		.state(state)
		);

	// Init
	wire [7:0] init_x_out;
	wire [6:0] init_y_out;
	init d_init(
		.clk(half_clk),
		.resetn(resetn),
		.state(state),
		
		.x_out(init_x_out),
		.y_out(init_y_out)
		);
	
	// UI
	wire [7:0] ui_x_out;
	wire [6:0] ui_y_out;
	ui d_ui(
		.clk(half_clk),
		.resetn(resetn),
		.state(state),
		
		.x_out(ui_x_out),
		.y_out(ui_y_out)
		);
	
	// Paddles
	wire [7:0] p_x_out;
	wire [6:0] p_y_out;
	paddles p(
		.clk(half_clk),
		.sixtyhz_clk(sixtyhz_clk),
		.resetn(resetn),
		.state(state),
		
		.inc_p1_y(!SW[3]),
		.dec_p1_y(!SW[2]),

		.inc_p2_y(!SW[1]),
		.dec_p2_y(!SW[0]),
		
		.paddle1_x(p1_x),
		.paddle1_y(p1_y),
		
		.paddle2_x(p2_x),
		.paddle2_y(p2_y),
		// Position to draw paddle
		.x_out(p_x_out),
		.y_out(p_y_out),

		//.LEDR(LEDR)

		// Need: Position of top pixel (head) of paddle
		);
	
	// Ball
	wire [7:0] b_x_out;
	wire [6:0] b_y_out;
	wire [3:0] p1_score;
	wire [3:0] p2_score;
	wire [7:0] p1_x, p2_x;
	wire [6:0] p1_y, p2_y;
	ball b(
		.clk(half_clk),
		.sixtyhz_clk(sixtyhz_clk),
		.resetn(resetn),
		.state(state),
		
		.p1_x(p1_x),
		.p1_y(p1_y),
		.p2_x(p2_x),
		.p2_y(p2_y),

		.force_applied(KEY[1]),

		.x_out(b_x_out),
		.y_out(b_y_out),
		
		.p1_score(p1_score),
		.p2_score(p2_score),
		.LEDR(LEDR)
		);

	score_display s_display(
		.p1_score(p1_score),
		.p2_score(p2_score),
		.p1_ones(HEX0[6:0]),
		.p1_tens(HEX1[6:0]),
		.p2_ones(HEX4[6:0]),
		.p2_tens(HEX5[6:0])
	);
	
endmodule

module control(
	input clk,
	input sixtyhz_clk,
	input resetn,
	input paddle_control,
	
	// Enable signals
	output [2:0] state
	);

	reg [2:0] current_state, next_state;

	assign state = current_state;
	
	localparam S_INIT = 3'd0,
					S_DRAW_UI = 3'd1,
					S_DRAW_BALL = 3'd2,
					S_ERASE_BALL = 3'd3,
					S_DRAW_PADDLES = 3'd4,
					S_ERASE_PADDLES = 3'd5;
	
	always@(clk)
	begin: state_table
		   next_state = S_INIT;

		   case (current_state)
				S_INIT: next_state = initialized ? S_DRAW_UI : S_INIT;
				S_DRAW_UI: next_state = ui_drawn ? S_DRAW_PADDLES : S_DRAW_UI;
				S_DRAW_PADDLES: next_state = paddles_drawn ? S_ERASE_BALL : S_DRAW_PADDLES;
				S_DRAW_BALL: next_state = sixtyhz_clk? S_INIT : S_DRAW_BALL;
//				S_DRAW_BALL: begin
//					if (output_sixtyhz_clk) begin
//						next_state = paddle_control ? S_ERASE_PADDLES : S_ERASE_BALL;
//					end else begin
//						next_state = S_DRAW_BALL;
//					end
//				end
				S_ERASE_PADDLES: next_state = paddles_erased ? S_DRAW_PADDLES : S_ERASE_PADDLES;
				S_ERASE_BALL: next_state = S_DRAW_BALL;
//				S_ERASE_BALL: next_state = output_sixtyhz_clk ? S_DRAW_BALL : S_ERASE_BALL;
		   endcase
	end
	
	wire initialized, ui_drawn, paddles_drawn, paddles_erased;

	custom_clk init_clk (current_state == S_INIT, clk, 26'd19200, initialized);
	custom_clk ui_clk (current_state == S_DRAW_UI, clk, 26'd250, ui_drawn); // 160x + 90y = 250
	custom_clk p_clk_1 (current_state == S_DRAW_PADDLES, clk, 26'd41, paddles_drawn); // 7 + 7 = 14
	custom_clk p_clk_2 (current_state == S_ERASE_PADDLES, clk, 26'd40, paddles_erased); // 7 + 7 = 14, same thing as above

	always@(posedge clk)
	begin: state_FFs
		if (!resetn) begin
			current_state <= S_INIT;
		end
		else begin
			current_state <= next_state;
		end
	end

endmodule

// Source: https://github.com/sunderrd/VerilogDDR/wiki/F.-Keeping-Score

// module speed(force_applied, ball_y, clk, sixtyhz_clk, speed);

// 	// 1 if user "hit" paddle, 0 if not - should be input from an active low "switch"
// 	input force_applied;
// 	input [6:0] ball_y;
// 	input clk, sixtyhz_clk,
// 	output real speed;

// 	// If y-position of ball is within:
// 	// - left/right 20 pixels: increase speed by 15%
// 	// - left/right 10 pixels: increase speed by 25%
// 	// - left/right 5 pixels: increase speed by 50%

// 	always @(posedge sixtyhz_clk)
// 	begin
// 		if (force_applied)
// 		begin
// 			if (ball_y <= 6'd5 || ball_y >= 6'd115)
// 				speed = 1.5;
// 			else if (ball_y <= 6'd10 || ball_y >= 6'd110)
// 				speed = 1.25;
// 			else if (ball_y <= 6'd20 || ball_y >= 6'd100)
// 				speed = 1.15;
// 			else
// 				speed = 1;
// 		end
// 		else
// 			speed = 1;
// 	end

// endmodule
