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
	logic step_done;
	wire [15:0] SRAM_DQ;
   logic SRAM_WE_N;
	logic SRAM_OE_N;
	logic [19:0] SRAM_ADDRESS;
	
	test_cfc_top_level test_cfc (.*);
	
	// NOTE: This test won't work with cfc as normal b/c frame_clk won't work so it
	// 	will stay in DONE state. Change the reset state value to CLEAR to test.
	//		Also won't work without simulating the VGA_CLK, which we're not sure how
	//		to do since it is an output of the CFC
	
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
	end
	
	
endmodule
