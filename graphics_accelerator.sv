module graphics_accelerator
(
	input logic Clk, Reset,
	
	// Software interface
	input logic[31:0] img_id,
	input logic [9:0] imgX, imgY,
	input logic draw_start, clear_start,
	output logic done,
	output logic frame_clk, // Used with Reset for next_frame_controller


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

	// Switch off between NFC and CFC
	logic nfc_en, cfc_en;
	assign cfc_en = ~nfc_en;
	logic nfc_step_done, cfc_step_done; // Tells us when we can switch enabled controllers
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			nfc_en <= 1'b0;
		end
		else if(nfc_en && nfc_step_done) begin
			nfc_en <= 1'b0;
		end
		else if(cfc_en && cfc_step_done) begin
			nfc_en <= 1'b1;
		end
	end

	logic OE_N_sync, WE_N_sync;
	logic sram_oe_n, sram_we_n;
	
	logic nfc_sram_oe_n, cfc_sram_oe_n;
	logic nfc_sram_we_n, cfc_sram_we_n;
	logic [19:0] nfc_sram_addr, cfc_sram_addr;
	logic [15:0] nfc_data_to_sram, cfc_data_to_sram;
	
	logic even_frame;
	logic can_clear;
	
	sync_r1 sync_OE(.Clk, .d(sram_oe_n), .q(OE_N_sync), .Reset(Reset)); // Reset to off
	sync_r1 sync_WE(.Clk, .d(sram_we_n), .q(WE_N_sync), .Reset(Reset)); // Reset to off
	
	assign SRAM_WE_N = WE_N_sync;
	assign SRAM_OE_N = OE_N_sync;
	
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	assign sram_we_n = nfc_en ? nfc_sram_we_n : cfc_sram_we_n;
	assign sram_oe_n = nfc_en ? nfc_sram_oe_n : cfc_sram_oe_n;
	assign SRAM_ADDRESS = nfc_en ? nfc_sram_addr : cfc_sram_addr;
	
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
	
	next_frame_controller next_frame_controller_0 (
		.Clk,
		.Reset(Reset),
		.EN(nfc_en),
		.even_frame,
		.draw_start,
		.clear_start,
		.done,
		.step_done(nfc_step_done),
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
		.step_done(cfc_step_done),
		.SRAM_OE_N(cfc_sram_oe_n),
		.SRAM_WE_N(cfc_sram_we_n),
		.SRAM_ADDRESS(cfc_sram_addr),
		.Data_to_SRAM(cfc_data_to_sram),
		.Data_from_SRAM,
		.* // VGA interface
	);
	
endmodule