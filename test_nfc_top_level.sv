module test_nfc_top_level(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY,
	input logic Start,
	output logic Done,
	
	// SRAM interface for frame buffers
	input logic even_frame,
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	next_frame_controller nfc (.*);

	test_memory test_sram (
		.Clk, .Reset,
		.I_O(SRAM_DQ),
		.A(SRAM_ADDRESS),
		.CE(0), .UB(0), .LB(0),
		.WE(WE_N_sync),
		.OE(OE_N_sync)
	);

	logic OE_N_sync, WE_N_sync;
	sync_r1 sync_OE(.Clk, .d(SRAM_OE_N), .q(OE_N_sync), .Reset(Reset)); // Reset to off
	sync_r1 sync_WE(.Clk, .d(SRAM_WE_N), .q(WE_N_sync), .Reset(Reset)); // Reset to off

	logic [15:0] Data_to_SRAM, Data_from_SRAM;
	tristate #(.N(16)) tristate_0 (
		.Clk,
		.tristate_output_enable(~WE_N_sync),
		.Data_write(Data_to_SRAM),
		.Data_read(Data_from_SRAM),
		.Data(SRAM_DQ)
	);
	
endmodule
