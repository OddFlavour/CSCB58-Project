// Keeps score of both players and outputs to HEX display in decimal
module score_display(
	input [7:0] p1_score, p2_score,
	output reg [6:0] p1_ones, p1_tens, p2_ones, p2_tens
);

	// Need 4 bits for each of ones and tens place
	wire [3:0] i, j, a, b;

	assign i = p1_score % 10;
	assign j = p1_score / 10;

	assign a = p2_score % 10;
	assign b = p2_score / 10;

	always @(*)
        case (i)
            4'd0: p1_ones = 7'b100_0000;
            4'd1: p1_ones = 7'b111_1001;
            4'd2: p1_ones = 7'b010_0100;
            4'd3: p1_ones = 7'b011_0000;
            4'd4: p1_ones = 7'b001_1001;
            4'd5: p1_ones = 7'b001_0010;
            4'd6: p1_ones = 7'b000_0010;
            4'd7: p1_ones = 7'b111_1000;
            4'd8: p1_ones = 7'b000_0000;
            4'd9: p1_ones = 7'b001_1000;
            default: p1_ones = 7'h7f;
        endcase

	always @(*)
        case (j)
            4'd0: p1_tens = 7'b100_0000;
            4'd1: p1_tens = 7'b111_1001;
            4'd2: p1_tens = 7'b010_0100;
            4'd3: p1_tens = 7'b011_0000;
            4'd4: p1_tens = 7'b001_1001;
            4'd5: p1_tens = 7'b001_0010;
            4'd6: p1_tens = 7'b000_0010;
            4'd7: p1_tens = 7'b111_1000;
            4'd8: p1_tens = 7'b000_0000;
            4'd9: p1_tens = 7'b001_1000;
            default: p1_tens = 7'h7f;
        endcase

		always @(*)
        case (a)
            4'd0: p2_ones = 7'b100_0000;
            4'd1: p2_ones = 7'b111_1001;
            4'd2: p2_ones = 7'b010_0100;
            4'd3: p2_ones = 7'b011_0000;
            4'd4: p2_ones = 7'b001_1001;
            4'd5: p2_ones = 7'b001_0010;
            4'd6: p2_ones = 7'b000_0010;
            4'd7: p2_ones = 7'b111_1000;
            4'd8: p2_ones = 7'b000_0000;
            4'd9: p2_ones = 7'b001_1000;
            default: p2_ones = 7'h7f;
        endcase

		always @(*)
        case (b)
            4'd0: p2_tens = 7'b100_0000;
            4'd1: p2_tens = 7'b111_1001;
            4'd2: p2_tens = 7'b010_0100;
            4'd3: p2_tens = 7'b011_0000;
            4'd4: p2_tens = 7'b001_1001;
            4'd5: p2_tens = 7'b001_0010;
            4'd6: p2_tens = 7'b000_0010;
            4'd7: p2_tens = 7'b111_1000;
            4'd8: p2_tens = 7'b000_0000;
            4'd9: p2_tens = 7'b001_1000;
            default: p2_tens = 7'h7f;
        endcase

endmodule