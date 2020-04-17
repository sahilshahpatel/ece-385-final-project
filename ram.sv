/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module  imgROM
(
		input [ADDRESS_DEPTH-1:0] address,
		input Clk,

		output logic [BIT_DEPTH-1:0] data
);

	parameter BIT_DEPTH = 4;
	parameter PIXELS = 256;
	parameter ADDRESS_DEPTH = 8;
	parameter FILE = "main-character.txt";

	// mem has width of 4 bits and a total of 16x16=256 addresses (pixels)
	logic [BIT_DEPTH-1:0] mem [0:PIXELS-1];

	initial
	begin
		 $readmemh("tools/png-to-hex/on-chip-memory/sprite_bytes/" + FILE, mem);
	end


	always_ff @ (posedge Clk) begin
		data <= mem[address];
	end

endmodule

module  rowRAM
(
	input	Clk,
	input [ADDRESS_DEPTH-1:0] write_address, read_address,
	input we,

	input logic [BIT_DEPTH-1:0] data_in,
	output logic [BIT_DEPTH-1:0] data_out
);

	parameter BIT_DEPTH = 16; // 4 pixels
	parameter ADDRESSABILITY = 256;
	parameter ADDRESS_DEPTH = 8;

	logic [BIT_DEPTH-1:0] mem [0:ADDRESSABILITY-1];

	always_ff @ (posedge Clk) begin
		if (we) begin
			mem[write_address] <= data_in;
		end
		data_out <= mem[read_address];
	end

endmodule

