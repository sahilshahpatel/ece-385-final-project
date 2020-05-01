module test_cfc_top_level(
	input logic Clk, Reset, EN,
	
	// VGA Interface 
	output logic [7:0]  VGA_R,        //VGA Red
							  VGA_G,        //VGA Green
							  VGA_B,        //VGA Blue
	output logic     	  VGA_CLK,      //VGA Clock
							  VGA_SYNC_N,   //VGA Sync signal
							  VGA_BLANK_N,  //VGA Blank signal
							  VGA_VS,       //VGA virtical sync signal
							  VGA_HS,       //VGA horizontal sync signal
	
	output logic step_done,
	
	output logic can_clear,
	
	// SRAM interface for frame buffers
	output logic even_frame, frame_clk,
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	logic sram_we_n, sram_oe_n;
	curr_frame_controller cfc (.SRAM_WE_N(sram_we_n),.SRAM_OE_N(sram_oe_n), .*);
	
	logic OE_N_sync, WE_N_sync;
	sync_r1 sync_OE(.Clk, .d(sram_oe_n), .q(OE_N_sync), .Reset(Reset)); // Reset to off
	sync_r1 sync_WE(.Clk, .d(sram_we_n), .q(WE_N_sync), .Reset(Reset)); // Reset to off
	
	assign SRAM_WE_N = WE_N_sync;
	assign SRAM_OE_N = OE_N_sync;

	test_memory test_sram (
		.Clk, .Reset,
		.I_O(SRAM_DQ),
		.A(SRAM_ADDRESS),
		.CE(1'b0), .UB(1'b0), .LB(1'b0),
		.WE(SRAM_WE_N),
		.OE(SRAM_OE_N)
	);

	logic [15:0] Data_to_SRAM, Data_from_SRAM;
	tristate #(.N(16)) tristate_0 (
		.Clk,
		.tristate_input_enable(~SRAM_OE_N),
		.tristate_output_enable(~SRAM_WE_N),
		.Data_write(Data_to_SRAM),
		.Data_read(Data_from_SRAM),
		.Data(SRAM_DQ)
	);
	
endmodule
