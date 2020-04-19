module avalon_graphics_interface(
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [2:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [15:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [15:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [15:0] EXPORT_DATA		// Exported Conduit Signal

	// VGA Interface 
	output logic [7:0]  VGA_R,        //VGA Red
							  VGA_G,        //VGA Green
							  VGA_B,        //VGA Blue
	output logic      VGA_CLK,      //VGA Clock
							VGA_SYNC_N,   //VGA Sync signal
							VGA_BLANK_N,  //VGA Blank signal
							VGA_VS,       //VGA virtical sync signal
							VGA_HS       //VGA horizontal sync signal
							
	// SRAM interface for frame buffers
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_UB_N,
	output logic SRAM_LB_N,
	output logic SRAM_CE_N,
	output logic SRAM_OE_N,
	output logic SRAM_WE_N,
	output logic [19:0] SRAM_ADDRESS
);

	// Register map:
	//		0: Which image are we drawing?
	//		1: imgX	(9:0)
	//		2: imgY	(9:0)
	//		3: Start (0)
	//		4: Done	(0)
	logic [31:0] registers [5];
	
	always_comb begin
		// Defaults
		AVL_READDATA = 32'bZ;
		if(AVL_CS) begin // if chip is selected
			if(AVL_READ) begin
				// Perform read
				AVL_READDATA = registers[AVL_ADDR];
			end
		end
	end

	always_ff @(posedge CLK) begin
		if(AVL_CS) begin // if chip is selected
			if(AVL_WRITE) begin
				// Perform write on enabled bits
				if(AVL_BYTE_EN[0])
					registers[AVL_ADDR][7:0] <= AVL_WRITEDATA[7:0];
				if(AVL_BYTE_EN[1])
					registers[AVL_ADDR][15:8] <= AVL_WRITEDATA[15:8];
			end
		end
		
		registers[4] <= {15'b0, Done}; // Load in aes_done
		
		if(RESET) begin
			registers[3] <= 0;
			registers[4] <= 0;
		end
	end

	assign EXPORT_DATA = 0; 

	
	
	graphics_accelerator2 graphics (
		.Clk,
		.Reset(RESET),
		.img_id(registers[0][2:0]),
		.imgX(registers[1][9:0]),
		.imgY(registers[2][9:0]),
		.Start(registers[3][0]),
		.Done(registers[4][0]),
		.* // VGA and SRAM signals
	);

endmodule
