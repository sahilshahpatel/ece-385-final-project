module test_nfc_top_level(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY,
	input logic Start,
	output logic Done,
	
	output logic step_done,
	
	// SRAM interface for frame buffers
	input logic even_frame,
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	logic sram_we_n, sram_oe_n;
	next_frame_controller nfc (
		.SRAM_WE_N(sram_we_n),
		.SRAM_OE_N(sram_oe_n),
		.*
	);

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
