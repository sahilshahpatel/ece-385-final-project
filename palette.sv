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
		case(colorIdx)
			default : color = 24'hFF0000; // Transparency color
			4'h1 : color = 24'h282246; // Background navy color
			4'h2 : color = 24'h213822; // Stairs dark green
			4'h3 : color = 24'h3E6B41; // Tile medium green
			4'h4 : color = 24'h80BB84; // Tile light green
			4'h5 : color = 24'hD624C1; // Monster eyes magenta
			4'h6 : color = 24'h252525; // Character body dark grey
			4'h7 : color = 24'h000000; // Character outline black
			4'h8 : color = 24'h9A9A9A; // Spikes gray
			4'h9 : color = 24'hFF9F33; // Candle orange
			4'ha : color = 24'hFFFFFF; // Candle white
			4'hb : color = 24'h525468; // Wall dark purple-gray
			4'hc : color = 24'h8780A8; // Wall light purple-gray
		endcase
	end

endmodule
