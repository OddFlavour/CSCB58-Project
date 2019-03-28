module ui(input clk, input resetn, input [2:0] state, output reg [7:0] x_out, output reg [6:0] y_out);

	reg horizontal_done;
	
	always@(posedge clk)
	begin
		if (!resetn || state != 3'd1) begin // active low reset
			x_out <= 8'b0;
			y_out <= 7'd30; // some constant for start of horizontal line
			horizontal_done <= 1'b0;
		end else if (!horizontal_done) begin
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