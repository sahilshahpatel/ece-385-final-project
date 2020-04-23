module testbench_cfc;
	
	timeunit 1ns;
	timeprecision 1ns;

	logic Clk;
	logic Reset;
	logic EN = 1;
	
	
	// VGA Interface 
	logic [7:0]  VGA_R,        //VGA Red
				    VGA_G,        //VGA Green
					 VGA_B;        //VGA Blue
	logic     	 VGA_CLK,      //VGA Clock
					 VGA_SYNC_N,   //VGA Sync signal
					 VGA_BLANK_N,  //VGA Blank signal
					 VGA_VS,       //VGA virtical sync signal
					 VGA_HS;       //VGA horizontal sync signal
	
	// SRAM interface for frame buffers
	logic even_frame, frame_clk;
	logic  [15:0] DATA_from_SRAM;
	logic [15:0] DATA_to_SRAM;
   logic SRAM_WE_N;
	logic SRAM_OE_N;
	logic [19:0] SRAM_ADDRESS;
	
	test_cfc_top_level test_top (.*);
	
	initial begin: TESTVECTORS
	Reset = 1;
	Clk = 0;
	
	for(int i = 0 ; i < 2; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
	
	Reset = 0;
	
	for(int i = 0 ; i < 1050; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
	
	
endmodule
