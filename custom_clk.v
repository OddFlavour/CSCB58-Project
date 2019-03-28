// Custom clock that sends out one pulse after reaching the threshold
module custom_clk(input enable, input default_clk, input [25:0] threshold, output reg pulse);
	
	reg [25:0] counter;

	always@(posedge default_clk)
	begin
		if (counter >= (threshold - 1'b1)) begin
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