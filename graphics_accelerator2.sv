module graphics_accelerator2
(
	input logic Clk, Reset,
	
	// Software interface
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY,
	input logic Start,
	output logic Done,

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

	logic OE_N_sync, WE_N_sync;
	sync_r1 sync_OE(.Clk, .d(SRAM_OE_N), .q(OE_N_sync), .Reset(Reset)); // Reset to off
	sync_r1 sync_WE(.Clk, .d(SRAM_WE_N), .q(WE_N_sync), .Reset(Reset)); // Reset to off
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	assign SRAM_WE_N = nfc_en ? nfc_sram_we_n : cfc_sram_we_n;
	assign SRAM_OE_N = nfc_en ? nfc_sram_oe_n : cfc_sram_oe_n;
	assign SRAM_ADDRESS = nfc_en ? nfc_sram_addr : cfc_sram_addr;
	
	// Split clock time between software interface and VGA output
	logic half_Clk;
	halftime halftime_0 (.Clk, .half_Clk);
	
	logic nfc_en, cfc_en;
	assign nfc_en = half_Clk;
	assign cfc_en = ~half_Clk;
	
	logic nfc_sram_oe_n, cfc_sram_oe_n;
	logic nfc_sram_we_n, cfc_sram_we_n;
	logic [19:0] nfc_sram_addr, cfc_sram_addr;
	
	logic nfc_data_to_sram, cfc_data_to_sram;
	
	logic even_frame;
	
	next_frame_controller next_frame_controller_0 (
		.Clk,
		.Reset(Reset || new_frame),
		.EN(nfc_en),
		.even_frame,
		.SRAM_OE_N(nfc_sram_oe_n),
		.SRAM_WE_N(nfc_sram_we_n),
		.SRAM_ADDRESS(nfc_sram_addr),
		.Data_to_SRAM(nfc_data_to_sram),
		.Data_from_SRAM,
		.* // Software interface
	);
	
	curr_frame_controller curr_frame_controller_0 (
		.Clk,
		.Reset,
		.EN(cfc_en),
		.even_frame,
		.frame_clk,
		.SRAM_OE_N(cfc_sram_oe_n),
		.SRAM_WE_N(cfc_sram_we_n),
		.SRAM_ADDRESS(cfc_sram_addr),
		.Data_to_SRAM(cfc_data_to_sram),
		.Data_from_SRAM,
		.* // VGA interface
	);

	logic frame_clk;
	logic new_frame; // Used with Reset for next_frame_controller
	rising_edge_detector new_frame_detector (.signal(frame_clk), .Clk, .rising_edge(new_frame));

	// Connect to SRAM via tristate
	logic [15:0] Data_to_SRAM, Data_from_SRAM;
	assign Data_to_SRAM = nfc_en ? nfc_data_to_sram : cfc_data_to_sram;
	tristate #(.N(16)) tristate_0 (
		.Clk,
		.tristate_input_enable(~OE_N_sync),
		.tristate_output_enable(~WE_N_sync),
		.Data_write(Data_to_SRAM),
		.Data_read(Data_from_SRAM),
		.Data(SRAM_DQ)
	);
	
endmodule
