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
    
	wire draw, erase;
	wire sixtyhz_clock, movement_clock;

    // Instansiate datapath
	datapath d0(
			.colour(SW[9:7]),
			.clk(CLOCK_50),
			.frame_clk(sixtyhz_clock),
			.mv_clk(movement_clock),
			
			.draw(draw),
			.erase(erase),
			
			.resetn(KEY[0]),
			.x_out(x),
			.y_out(y),
			.colour_out(colour),
			.LEDR(LEDR));

    // Instansiate FSM control
    control c0(
			.go({SW[16], SW[17]}),
			.clk(CLOCK_50),
			.resetn(KEY[0]),
			.frame_clk(sixtyhz_clock),
			.output_move_clk(movement_clock),
			
			.draw(draw),
			.erase(erase),
			);
    
endmodule

module custom_clk(input default_clk, input [25:0] threshold, output reg pulse);
	
	reg [25:0] counter;

	always@(posedge default_clk)
	begin
		if (counter >= threshold) begin
			counter <= 0;
			pulse <= 1;
		end else begin
			counter <= counter + 1'b1;
			pulse <= 0;
		end
	end
endmodule
			
module datapath(
	input [2:0] colour,
	input clk,
	input frame_clk,
	input mv_clk,
	
	input draw, erase,
	
	input resetn,
	output reg [7:0] x_out,
	output reg [6:0] y_out,
	output reg [2:0] colour_out,
	output [17:0] LEDR
    );

	reg direction_x, direction_y;

	always@(posedge clk)
	begin
		if (!resetn)
			colour_out <= 3'b100;
		if (draw)
			colour_out <= 3'b100;
		if (erase)
			colour_out <= 3'b000;
	end
	
	assign LEDR[0] = direction_y;
	assign LEDR[1] = direction_x;
	
	always@(posedge mv_clk)
	begin
		if (!resetn)
		begin
			x_out <= 0;
			y_out <= 0;
		end else begin
			if (x_out < 0)
				direction_x <= 0;
			if (x_out > 160)
				direction_x <= 1;
			if (y_out < 0)
				direction_y <= 0;
			if (y_out > 120)
				direction_y <= 1;
				
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

module control(
	input [1:0] go,
	input clk,
	input resetn,
	output frame_clk,
	output output_move_clk,
	
	output reg draw, erase
	);

	reg [2:0] current_state, next_state;

	localparam S_DRAW      = 3'd0,
					S_ERASE      = 3'd1;
	
	always@(clk)
	begin: state_table
		   next_state = S_DRAW;

		   case (current_state)
				S_DRAW: next_state = frame_clk ? S_ERASE : S_DRAW;
				S_ERASE: next_state = frame_clk ? S_DRAW : S_ERASE;
		   endcase
	end

	custom_clk f_clk (clk, 26'd833_333, frame_clk);
	
	custom_clk mv_clk (frame_clk, 26'd5, output_move_clk);

	always@(*)
	begin: enable_signals
		draw <= 0;
		erase <= 0;
		
		case (current_state)
			S_DRAW: draw <= 1;
			S_ERASE: erase <= 1;
		endcase
	end

	always@(posedge clk)
	begin: state_FFs
		if (!resetn) begin
			current_state <= S_DRAW;
		end
		else begin
			current_state <= next_state;
		end
	end
		
		
endmodule