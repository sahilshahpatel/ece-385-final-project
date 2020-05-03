module palette(
	input logic [3:0] colorIdx,
	
	output logic [7:0]  VGA_R,        //VGA Red
							  VGA_G,        //VGA Green
							  VGA_B         //VGA Blue
);

	logic [23:0] color;
	assign VGA_R = color[23:16];
	assign VGA_G = color[15:8];
	assign VGA_B = color[7:0];

	always_comb begin
		unique case(colorIdx)
			default : color = 24'hFF0000; // Transparency color
			4'd1: color = 24'h05121B; // Navy for background
			4'd2: color = 24'h2D4745; // Dark green for tiles
			4'd3: color = 24'h46615B; // Light green for tiles
			4'd4: color = 24'h082026; // Dark teal for walls
			4'd5: color = 24'h223A42; // Light teal for walls
			4'd6: color = 24'h000000; // Black for player/spikes
			4'd7: color = 24'hBDBFA0; // Beige for face
			4'd8: color = 24'hFE9802; // Orange for candle
			4'd9: color = 24'h9A9A9A; // Gray for candle
			4'd10: color = 24'h16252F; // Dark blue for monsters
			4'd11: color = 24'hD624C1; // Magenta for monsters
			4'd12: color = 24'hFFFFFF; // White for candle/spikes
		endcase
	end

endmodule
