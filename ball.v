module ball(input clk, input sixtyhz_clk, input resetn, input [2:0] state,

				input [7:0] p1_x, input [6:0] p1_y, // p1 is left paddle
				input [7:0] p2_x, input [6:0] p2_y, // p2 is right paddle

				input force_applied, // 0 if player is not "hitting" ball, 1 if player is "hitting" ball

				output reg [7:0] x_out, output reg [6:0] y_out,
				output reg [3:0] p1_score, output reg [3:0] p2_score,
				output reg [17:0] LEDR);

	reg direction_x;
	reg direction_y;
	reg scored;

	// Speed of ball
	// real speed;

	// initial begin
	// 	speed = 1;
	// end

	// wire [26:0] a, b, c, d, e, f;
	// assign a = 1/speed * 26'd2_272_727;
	// assign b = 1/speed * 26'd649_350;
	// assign c = 1/speed * 26'd1_250_000;
	// assign d = 1/speed * 26'd724_637;
	// assign e = 1/speed * 26'd877_192;
	// assign f = 1/speed * 26'd892_857;

	// Clocks set at different speed to track when to increment (x, y) coordinates depending on trajectory of ball
	wire clk_22_out, clk_77_out, clk_40_out, clk_69_out, clk_57_out, clk_56_out;

	custom_clk clk_22(1, clk, 26'd2_272_727, clk_22_out);
	custom_clk clk_77(1, clk, 26'd649_350, clk_77_out);

	custom_clk clk_40(1, clk, 26'd1_250_000, clk_40_out);
	custom_clk clk_69(1, clk, 26'd724_637, clk_69_out);

	custom_clk clk_57(1, clk, 26'd877_192, clk_57_out);
	custom_clk clk_56(1, clk, 26'd892_857, clk_56_out);

	// Pulses to track when to increment counter for (x, y) value of ball
	reg x_pulse, y_pulse;

	// Random (x, y) direction generated upon reset
	// wire x_random, y_random;
	// x_random = {$random} % 1;
	// y_random = {$random} % 1;
	initial begin
		mem_x <= 8'd80;
		mem_y <= 7'd75;
	end

	/*
	Everything in this always block updates at 60 FPS:
	*/
	// If ball collides within certain area of paddle, use the corresponding clk for x and y counters
	always @(posedge sixtyhz_clk)
	begin
		// Reset game state:
		if (!resetn)
		begin
			// Reset player's score
			p1_score <= 1'b0;
			p2_score <= 1'b0;
			// Upon reset of game, set angle of trajectory of ball to 45 degrees
			x_pulse <= clk_57_out;
			y_pulse <= clk_56_out;
			// Set direction of ball to go south-east
			direction_x <= 1'b0 /*x_random*/;
			direction_y <= 1'b0 /*y_random*/;
		end
		else begin
			// Left and right boundary:
			// - Increase score by 1 for winning player
			// - Reset game state
			if (mem_x == 8'd1) begin
				direction_x <= 1'b0;
				scored = 1'b1;
				p2_score <= p2_score + 1'b1;
			end else if (mem_x == 8'd158) begin
				direction_x <= 1'b1;
				scored = 1'b1;
				p1_score <= p1_score + 1'b1;
			end else begin
				scored = 1'b0;
			end

			// Top and bottom boundary
			if (mem_y <= 7'd32)
				direction_y <= 1'b0;
			if (mem_y >= 7'd119)
				direction_y <= 1'b1;

			/*
			Speed Control of Ball:
			*/

			// if (force_applied)
			// begin
			// 	if (y_out <= 6'd5 || y_out >= 6'd115)
			// 		speed = 1.5;
			// 	else if (y_out <= 6'd10 || y_out >= 6'd110)
			// 		speed = 1.25;
			// 	else if (y_out <= 6'd20 || y_out >= 6'd100)
			// 		speed = 1.15;
			// 	else
			// 		speed = 1;
			// end

			/*
			Paddle Collision and Ball Direction when Hitting Paddles:
			*/

			LEDR <= {p1_x, 1'b0, mem_x};
			// If the ball has an x-coordinate next to the LEFT paddle
			if (mem_x == p1_x + 8'd2)
			begin
				if (mem_y >= p1_y && mem_y <= (p1_y + 7'd20))
					direction_x <= 1'b0;
//				// If ball collides with top of paddle (Angle 75)
//				if (y_out == p1_y || y_out == p1_y + 7'd1) begin
//					x_pulse <= clk_22_out;
//					y_pulse <= clk_77_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b1;
//				end
//				// Angle 60
//				if (y_out == p1_y + 7'd2 || y_out == p1_y + 7'd3) begin
//					x_pulse <= clk_40_out;
//					y_pulse <= clk_69_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b1;
//				end
//				// Angle 45
//				if (y_out == p1_y + 7'd4 || y_out == p1_y + 7'd5) begin
//					x_pulse <= clk_57_out;
//					y_pulse <= clk_56_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b1;
//				end
//				// Angle 30
//				if (y_out == p1_y + 7'd6 || y_out == p1_y + 7'd7) begin
//					x_pulse <= clk_69_out;
//					y_pulse <= clk_40_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b1;
//				end
//				// Angle 15
//				if (y_out == p1_y + 7'd8 || y_out == p1_y + 7'd9) begin
//					x_pulse <= clk_77_out;
//					y_pulse <= clk_22_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b1;
//				end
//				// Angle 15 down
//				if (y_out == p1_y + 7'd10 || y_out == p1_y + 7'd11) begin
//					x_pulse <= clk_77_out;
//					y_pulse <= clk_22_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b0;
//				end
//				// Angle 30 down
//				if (y_out == p1_y + 7'd12 || y_out == p1_y + 7'd13) begin
//					x_pulse <= clk_69_out;
//					y_pulse <= clk_40_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b0;
//				end
//				// Angle 45 down
//				if (y_out == p1_y + 7'd14 || y_out == p1_y + 7'd15) begin
//					x_pulse <= clk_57_out;
//					y_pulse <= clk_56_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b0;
//				end
//				// Angle 60
//				if (y_out == p1_y + 7'd16 || y_out == p1_y + 7'd17) begin
//					x_pulse <= clk_40_out;
//					y_pulse <= clk_69_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b0;
//				end
//				// If ball collides with bottom of paddle (Angle 75)
//				if (y_out == p1_y + 7'd18 || y_out == p1_y + 7'd19) begin
//					x_pulse <= clk_22_out;
//					y_pulse <= clk_77_out;
//					direction_x <= 1'b0;
//					direction_y <= 1'b0;
//				end
			end

			// If the ball has an x-coordinate next to the RIGHT paddle
			else if (mem_x == p2_x - 8'd2)
			begin
				if (mem_y >= p2_y && mem_y <= (p2_y + 7'd20))
					direction_x <= 1'b1;
//				// If ball collides with top of paddle (Angle 75)
//				if (y_out == p2_y || y_out == p2_y + 7'd1) begin
//					x_pulse <= clk_22_out;
//					y_pulse <= clk_77_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b1;
//				end
//				// Angle 60
//				if (y_out == p2_y + 7'd2 || y_out == p2_y + 7'd3) begin
//					x_pulse <= clk_40_out;
//					y_pulse <= clk_69_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b1;
//				end
//				// Angle 45
//				if (y_out == p2_y + 7'd4 || y_out == p2_y + 7'd5) begin
//					x_pulse <= clk_57_out;
//					y_pulse <= clk_56_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b1;
//				end
//				// Angle 30
//				if (y_out == p2_y + 7'd6 || y_out == p2_y + 7'd7) begin
//					x_pulse <= clk_69_out;
//					y_pulse <= clk_40_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b1;
//				end
//				// Angle 15
//				if (y_out == p2_y + 7'd8 || y_out == p2_y + 7'd9) begin
//					x_pulse <= clk_77_out;
//					y_pulse <= clk_22_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b1;
//				end
//				// Angle 15 down
//				if (y_out == p2_y + 7'd10 || y_out == p2_y + 7'd11) begin
//					x_pulse <= clk_77_out;
//					y_pulse <= clk_22_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b0;
//				end
//				// Angle 30 down
//				if (y_out == p2_y + 7'd12 || y_out == p2_y + 7'd13) begin
//					x_pulse <= clk_69_out;
//					y_pulse <= clk_40_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b0;
//				end
//				// Angle 45 down
//				if (y_out == p2_y + 7'd14 || y_out == p2_y + 7'd15) begin
//					x_pulse <= clk_57_out;
//					y_pulse <= clk_56_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b0;
//				end
//				// Angle 60
//				if (y_out == p2_y + 7'd16 || y_out == p2_y + 7'd17) begin
//					x_pulse <= clk_40_out;
//					y_pulse <= clk_69_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b0;
//				end
//				// If ball collides with bottom of paddle (Angle 75)
//				if (y_out == p2_y + 7'd18 || y_out == p2_y + 7'd19) begin
//					x_pulse <= clk_22_out;
//					y_pulse <= clk_77_out;
//					direction_x <= 1'b1;
//					direction_y <= 1'b0;
//				end
			end

		end
	end

	reg [7:0] mem_x;
	reg [6:0] mem_y;
	/*
	Everything in this always block updates at regular clock speed:
	- Need movement of ball to update faster than 60 FPS in order to move ball more than 60 pixels/second
	*/
	/*
	Below is used to update 'x' and 'y' position of ball
	*/
	always @(posedge sixtyhz_clk)
	begin
		if (!resetn) begin
			mem_x <= 8'd80;
			mem_y <= 7'd75;
		end
		else begin
			if (scored == 1'b1) begin
				mem_x <= 8'd80;
				mem_y <= 7'd75;
			end else begin
				/*
				Movement of the ball
				*/
				case ({direction_x, direction_y})
					2'b00: begin
						mem_x <= mem_x + 1'b1;
						mem_y <= mem_y + 1'b1;
					end
					2'b01: begin
						mem_x <= mem_x + 1'b1;
						mem_y <= mem_y - 1'b1;
					end
					2'b10: begin
						mem_x <= mem_x - 1'b1;
						mem_y <= mem_y + 1'b1;
					end
					2'b11: begin
						mem_x <= mem_x - 1'b1;
						mem_y <= mem_y - 1'b1;
					end
				endcase
			end
		end
	end
	
	/*
	Below is to draw the ball
	*/
	always @(posedge clk)
	begin
		x_out <= mem_x;
		y_out <= mem_y;
	end
		

endmodule