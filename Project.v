// Part 2 skeleton

module Project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		LEDR,
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
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1),
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
    
	wire [2:0] state;
	wire sixtyhz_clk, movement_clock;
	
	draw_control_centre dcc(
			.clk(CLOCK_50),
			.state(state),
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

	
   // Instansiate datapath
	datapath d0(
			.colour(SW[9:7]),
			.clk(CLOCK_50),
			.frame_clk(sixtyhz_clk),
			.mv_clk(movement_clock),
			
			.state(state),
			
			.resetn(KEY[0])
			);

    // Instansiate FSM control
    control c0(
			.go({SW[16], SW[17]}),
			.clk(CLOCK_50),
			.resetn(KEY[0]),
			.output_sixtyhz_clk(sixtyhz_clk),
			
			.state(state)
			);

	wire [7:0] ui_x_out;
	wire [6:0] ui_y_out;
	ui d_ui(
			.clk(CLOCK_50),
			.resetn(resetn),
			.x_out(ui_x_out),
			.y_out(ui_y_out)
			);
	
	wire [7:0] p_x_out;
	wire [6:0] p_y_out;
	paddles p(
			.clk(CLOCK_50),
			.sixtyhz_clk(sixtyhz_clk),
			.resetn(resetn),
			.state(state),
			
			.inc_p1_y(/* P1 JOYSTICK INPUT */),
			.inc_p2_y(/* P2 JOYSTICK INPUT */),
			
			.x_out(p_x_out),
			.y_out(p_y_out)
			);
	
	wire [7:0] b_x_out;
	wire [6:0] b_y_out;
	ball b(
		.clk(CLOCK_50),
		.sixtyhz_clk(sixtyhz_clk),
		.resetn(resetn),
		.state(state),
		
		.x_out(b_x_out),
		.y_out(b_y_out)
		);
	
endmodule

// Custom clock that sends out one pulse after reaching the threshold
module custom_clk(input enable, input default_clk, input [25:0] threshold, output reg pulse);
	
	reg [25:0] counter;

	always@(posedge default_clk)
	begin
		if (counter >= threshold) begin
			counter <= 0;
			pulse <= 1;
		end else if (enable) begin
			counter <= counter + 1'b1;
			pulse <= 0;
		end else begin
			counter <= 0;
			pulse <= 0;
		end
	end
endmodule

module draw_control_centre(input clk, input [2:0] state,
	input [7:0] ui_x,
	input [6:0] ui_y,
	
	input [7:0] p_x,
	input [6:0] p_y,
	
	input [7:0] b_x,
	input [6:0] b_y,
	
	output reg [7:0] x_out,
	output reg [6:0] y_out,
	output reg [2:0] colour_out
	);
	
	// State table reference
	localparam S_INIT = 3'd0,
				S_DRAW_UI = 3'd1,
				S_DRAW_BALL = 3'd2,
				S_ERASE_BALL = 3'd3,
				S_DRAW_PADDLES = 3'd4,
				S_ERASE_PADDLES = 3'd5;
	
	/* *!?!*
		I should be able to paint as fast as I like,
		but in order to avoid skipping frames, I should
		only update at 60hz
		*!?!*
	*/
	
	// Draw Control Centre
	always@(posedge clk)
	begin
		case(state)
			S_DRAW_UI: begin
				x_out <= ui_x;
				y_out <= ui_y;
				colour_out <= 3'b111;
			end
			S_DRAW_PADDLES: begin
				x_out <= p_x; // SHOULD BE CONSTANT
				y_out <= p_y;
				colour_out <= 3'b111;
			end
			S_DRAW_BALL: begin
				x_out <= b_x;
				y_out <= b_y;
				colour_out <= 3'b111;
			end
			S_ERASE_PADDLES: begin
				x_out <= p_x;
				y_out <= p_y;
				colour_out <= 3'b000;
			end
			S_ERASE_BALL: begin
				x_out <= b_x;
				y_out <= b_y;
				colour_out <= 3'b000;
			end
		endcase
	end
endmodule

module ui(input clk, input resetn, output reg [7:0] x_out, output reg [6:0] y_out);

	reg horizontal_done;
	
	always@(posedge clk)
	begin
		if (!resetn) begin // active low reset
			x_out <= 8'b0;
			y_out <= 7'd30; // some constant for start of horizontal line
		end
		
		if (!horizontal_done) begin
			x_out <= x_out + 1'b1; // draw horizontal line
			y_out <= 7'd30;
			if (x_out >= 8'd159)
				horizontal_done <= 1'b1;
		end else begin
			x_out <= 8'd80;
			y_out <= y_out + 1'b1; // draw vertical line
		end
	end
endmodule

module paddles(input clk, input sixtyhz_clk, input resetn, input [2:0] state,
					
					/*input [1:0] inc_p1_x, */input [1:0] inc_p1_y,
					/*input [1:0] inc_p2_x, */input [1:0] inc_p2_y,
					
					output reg [7:0] x_out, output reg [6:0] y_out);

	reg [7:0] paddle1_x;
	reg [6:0] paddle1_y;
	
	reg [7:0] paddle2_x;
	reg [6:0] paddle2_y;

	reg [2:0] counter;
	reg draw_paddle_counter;
	
	initial begin
		// DEFINE CONSTANTS
		
		paddle1_x <= 8'd10;
		paddle1_y <= 7'd75;
		
		paddle2_x <= 8'd140;
		paddle2_y <= 7'd75;
		
	end
	
	/*
	This clock is used to update the positions of the paddles
	*/
	// Update x and y values however only at 60hz
	always@(posedge sixtyhz_clk)
	begin
		if (state == 3'd4) begin
			// 2 bits, 0 = no inc, 1 = +ve inc, 2 = -ve inc
			// PADDLE 1 BEGIN
			if (inc_p1_y == 2'd1) begin
				// edge detection
				if (paddle1_y < 7'd119) begin
					paddle1_y <= paddle1_y + 1'b1;
				end
			end else if (inc_p1_y == 2'd2) begin
				if (paddle1_y > 7'd1) begin
					paddle1_y <= paddle1_y - 1'b1;
				end
			end
			// PADDLE 1 END
			// PADDLE 2 BEGIN
			if (inc_p2_y == 2'd1) begin
				// edge detection
				if (paddle2_y < 7'd119) begin
					paddle2_y <= paddle2_y + 1'b1;
				end
			end else if (inc_p2_y == 2'd2) begin
				if (paddle2_y > 7'd1) begin
					paddle2_y <= paddle2_y - 1'b1;
				end
			end
			// PADDLE 2 END
		end
	end
	
	/*
	This clock is used to draw the paddles
	*/
	always@(posedge clk)
	begin
		// S_DRAW_PADDLES = 3'd4
		if (state == 3'd4) begin
			// Draw paddle 1
			if (draw_paddle_counter == 1'b0) begin
				x_out <= paddle1_x;
				y_out <= paddle1_y + counter;
				if (counter == 3'd6) begin
					draw_paddle_counter <= 1'b1;
					counter <= 3'b0;
				end else begin
					counter <= counter + 1'b1;
				end
			// Draw paddle 2
			end else if (draw_paddle_counter == 1'b1) begin
				x_out <= paddle2_x;
				y_out <= paddle2_y + counter;
			end
		end else if (state != 3'd4) begin
			counter <= 3'b0;
			draw_paddle_counter <= 1'b0;
		end
	end
	
endmodule

module ball(input clk, input sixtyhz_clk, input resetn, input [2:0] state,

				input [7:0] p1_x, input [6:0] p1_y, // p1 is left paddle
				input [7:0] p2_x, input [6:0] p2_y, // p2 is right paddle

				output reg [7:0] x_out, output reg [6:0] y_out);

	reg direction_x, direction_y;
	
	always@(posedge sixtyhz_clk)
	begin
		if (!resetn)
		begin
			x_out <= 1'b0;
			y_out <= 1'b0;
		end else begin
			/*
			Ball physics when hitting the boundary
			*/
			// x_out, y_out CANNOT HAVE NEGATIVE VALUES
			if (x_out <= 8'd1)
				direction_x <= 1'b0;
			if (x_out >= 8'd159)
				direction_x <= 1'b1;
			if (y_out <= 7'd32)
				direction_y <= 1'b0;
			if (y_out >= 7'd119)
				direction_y <= 1'b1;
				
			/*
			Ball physics when hitting the paddles
			*/
			// BALL PHYSICS GO HERE, EITHER CODE UP DIFFERENT MODULE OR CODE IT HERE
			// Checks if the ball hit the paddle
			if (x_out <= (p1_x + 1'b1) // Need to play around with the 1'b1, since it is not sequential code
				&& (y_out >= p1_y && y_out <= p1_y + 3'd7))
				direction_x <= 1'b0;
			
			if (x_out >= (p2_x - 1'b1)
				&& (y_out >= p2_y && y_out <= p2_y + 3'd7))
				direction_x <= 1'b1;
			
			/*
			Processing of the next position of the ball
			*/
			case ({direction_x, direction_y})
				2'b00: begin
					x_out <= x_out + 1'b1;
					y_out <= y_out + 1'b1;
				end
				2'b01: begin
					x_out <= x_out + 1'b1;
					y_out <= y_out - 1'b1;
				end
				2'b10: begin
					x_out <= x_out - 1'b1;
					y_out <= y_out + 1'b1;
				end
				2'b11: begin
					x_out <= x_out - 1'b1;
					y_out <= y_out - 1'b1;
				end
			endcase
		end
	end
endmodule

module datapath(
	input [2:0] colour,
	input clk,
	input frame_clk,
	input mv_clk,
	
	// Enable signals
	input state,
	
	input resetn
    );
	 
	 // I never used this module, since the modules: "ui, paddles, ball" takes care of datapath

endmodule

module control(
	input [1:0] go,
	input clk,
	input resetn,
	
	// Frame rate clocks
	output output_sixtyhz_clk,
	
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
				S_INIT: next_state = S_DRAW_UI;
				S_DRAW_UI: next_state = ui_drawn ? S_DRAW_PADDLES : S_DRAW_UI;
				S_DRAW_PADDLES: next_state = paddles_drawn ? S_ERASE_BALL : S_DRAW_PADDLES;
				S_DRAW_BALL: next_state = /*USER_INPUT*/1'b0 ? S_ERASE_PADDLES : S_ERASE_BALL;
				S_ERASE_PADDLES: next_state = paddles_erased ? S_DRAW_PADDLES : S_ERASE_PADDLES;
				S_ERASE_BALL: next_state = S_DRAW_BALL;
		   endcase
	end
	
	wire ui_drawn, paddles_drawn, paddles_erased;

	custom_clk ui_clk (current_state == S_DRAW_UI, clk, 26'd250, ui_drawn); // 160x + 90y = 250
	custom_clk p_clk_1 (current_state == S_DRAW_PADDLES, clk, 26'd14, paddles_drawn); // 7 + 7 = 14
	custom_clk p_clk_2 (current_state == S_ERASE_PADDLES, clk, 26'd14, paddles_erased); // 7 + 7 = 14, same thing as above
	custom_clk f_clk (1, clk, 26'd833_333, output_sixtyhz_clk);

	always@(*)
	begin: enable_signals
		
	end

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