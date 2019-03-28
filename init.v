module init(input clk, input resetn, input [2:0] state, output reg [7:0] x_out, output reg [6:0] y_out);

	always@(posedge clk)
	begin
		if (!resetn || state != 3'd0) begin
			x_out <= 0;
			y_out <= 0;
		end else if (y_out != 7'd120) begin
			if (x_out != 8'd159) begin
				x_out <= x_out + 1'b1;
			end else begin
				x_out <= 0;
				y_out <= y_out + 1'b1;
			end
		end else begin
			x_out <= 0;
			y_out <= 0;
		end
	end
	
endmodule