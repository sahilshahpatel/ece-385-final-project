module avalon_graphics_interface(
	// Avalon Clock Input
	input logic Clk,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [2:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data

	// VGA Interface 
	output logic [7:0]  VGA_R,        //VGA Red
							  VGA_G,        //VGA Green
							  VGA_B,        //VGA Blue
	output logic      VGA_CLK,      //VGA Clock
							VGA_SYNC_N,   //VGA Sync signal
							VGA_BLANK_N,  //VGA Blank signal
							VGA_VS,       //VGA virtical sync signal
							VGA_HS,       //VGA horizontal sync signal
							
	// SRAM interface for frame buffers
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_UB_N,
	output logic SRAM_LB_N,
	output logic SRAM_CE_N,
	output logic SRAM_OE_N,
	output logic SRAM_WE_N,
	output logic [19:0] SRAM_ADDRESS
);
	
	logic [31:0] registers [7];

	// Register map:
	//		0: spritesheetX	(3:0)
	//		1: spritesheetY	(2:0)
	//		2: imgX	(9:0)
	//		3: imgY	(9:0)
	//		4: Draw Start (0)
	//		5: Clear Start (0)
	//		6: Done	(0)
	
	logic done, frame_clk;
	graphics_accelerator graphics (
		.Clk,
		.Reset(RESET),
		.spritesheetX(registers[0][3:0]),
		.spritesheetY(registers[1][2:0]),
		.imgX(registers[2][9:0]),
		.imgY(registers[3][9:0]),
		.draw_start(registers[4][0]),
		.clear_start(registers[5][0]),
		.done(done),
		.frame_clk,
		.* // VGA and SRAM signals
	);
	
	always_comb begin
		// Defaults
		AVL_READDATA = 32'b0;
		if(AVL_CS) begin // if chip is selected
			if(AVL_READ) begin
				// Perform read
				AVL_READDATA = registers[AVL_ADDR];
			end
		end
	end

	always_ff @(posedge Clk) begin
		if(RESET) begin
			registers[3] <= 32'd0;
			registers[4] <= 32'd0;
			registers[5] <= 32'd0;
		end
		else begin
			// Handle writes
			if(AVL_CS && AVL_WRITE) begin
				// Perform write on enabled bits
				if(AVL_ADDR != 6) begin // register 6 is read only
					if(AVL_BYTE_EN[0])
						registers[AVL_ADDR][7:0] <= AVL_WRITEDATA[7:0];
					if(AVL_BYTE_EN[1])
						registers[AVL_ADDR][15:8] <= AVL_WRITEDATA[15:8];
				end
			end
			
			// Read-only registers
			registers[6] <= {31'b0, done}; // Load in done
		end
	end
endmodule
