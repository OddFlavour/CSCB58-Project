module paddles(input clk, input sixtyhz_clk, input resetn, input [2:0] state,
					
					input inc_p1_y,
					input dec_p1_y,

					input inc_p2_y,
					input dec_p2_y,
					
					output reg [7:0] paddle1_x,
					output reg [6:0] paddle1_y,
		
					output reg [7:0] paddle2_x,
					output reg [6:0] paddle2_y,
					
					output reg [7:0] x_out, output reg [6:0] y_out
					);
//
//	reg [7:0] paddle1_x;
//	reg [6:0] paddle1_y;
//	
//	reg [7:0] paddle2_x;
//	reg [6:0] paddle2_y;

	reg [4:0] counter;
	reg drawn_paddle_1;
	
	initial begin
		// Initially, set paddles to starting position
		
		paddle1_x <= 8'd5;
		paddle1_y <= 7'd75;
		
		paddle2_x <= 8'd155;
		paddle2_y <= 7'd75;
		
	end
	
	/*
	This clock is used to update the positions of the paddles
	*/
	// Update x and y values however only at 60hz
	always@(posedge sixtyhz_clk)
	begin
		// Upon reset, reset paddles to initial position
		if (!resetn) begin
			// DEFINE CONSTANTS
			paddle1_x <= 8'd5;
			paddle1_y <= 7'd75;
			
			paddle2_x <= 8'd155;
			paddle2_y <= 7'd75;
		end else begin

			if (state != 3'd4 && state != 3'd5) begin
				// 2 bits, 0 = no inc, 1 = +ve inc, 2 = -ve inc

				// PADDLE 1 CONTROL:

				// If user input is "1", increase y position
				if (inc_p1_y == 1'd1) begin
					// Edge detection - bottom edge
					if ((paddle1_y + 7'd20) < 7'd119) begin
						paddle1_y <= paddle1_y + 1'b1;
					end
				end
				// If user input is "2", decrease y position
				else if (dec_p1_y == 1'd1) begin
					// Edge detection - top edge
					if (paddle1_y > 7'd31) begin
						paddle1_y <= paddle1_y - 1'b1;
					end
				end

				// PADDLE 2 CONTROL:
				if (inc_p2_y == 1'd1) begin
					// Edge detection - bottom edge
					if ((paddle2_y + 7'd20) < 7'd119) begin
						paddle2_y <= paddle2_y + 1'b1;
					end
				end else if (dec_p2_y == 1'd1) begin
					// Edge detection - top edge
					if (paddle2_y > 7'd31) begin
						paddle2_y <= paddle2_y - 1'b1;
					end
				end
			end
		end
	end

	/*
	This clock is used to draw the paddles
	*/
	always@(posedge clk)
	begin
		if (!resetn || state != 3'd4) begin
			drawn_paddle_1 <= 1'b0;
			counter <= 5'b0;
		// If we are in the states to draw or erase paddles
		end else begin
			// paddle 1
			if (drawn_paddle_1 == 1'b0) begin
				x_out <= paddle1_x;
				y_out <= paddle1_y + counter;
				if (counter == 5'd20) begin
					drawn_paddle_1 <= 1'b1;
					counter <= 5'b0;
				end else begin
					counter <= counter + 1'b1;
				end
			// paddle 2
			end else if (drawn_paddle_1 == 1'b1) begin
				x_out <= paddle2_x;
				y_out <= paddle2_y + counter;
				if (counter == 5'd20) begin
					drawn_paddle_1 <= 1'b0;
					counter <= 5'b0;
				end else begin
					counter <= counter + 1'b1;
				end
			end
		end
	end

endmodule