module draw_control_center(input clk, input resetn, input [2:0] state,
	input [7:0] init_x,
	input [6:0] init_y,
	
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
			S_INIT: begin
				x_out <= init_x;
				y_out <= init_y;
				colour_out <= 3'b000;
			end
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
				// Below stops the ball from erasing the middle line
				if (b_x == 8'd80)
					colour_out <= 3'b111;
				else
					colour_out <= 3'b000;
			end
		endcase
	end
endmodule