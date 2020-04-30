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
	logic clear_start, clear_done;
	wire [15:0] SRAM_DQ;
   logic SRAM_WE_N;
	logic SRAM_OE_N;
	logic [19:0] SRAM_ADDRESS;
	
	test_cfc_top_level test_cfc (.*);
	
	// NOTE: This test won't work with cfc as without simulating the VGA_CLK. 
	//		Please uncomment the simulated VGA_CLK in cfc before testing.
	
	initial begin: TESTVECTORS
		test_cfc.cfc.VGA_CLK_reset = 1;
		Clk = 0;
		
		for(int i = 0 ; i < 4; i++) begin
			#10 Clk = 0;
			#10 Clk = 1;
		end
		
		test_cfc.cfc.VGA_CLK_reset = 0; 
		
			for(int i = 0 ; i < 4; i++) begin
			#10 Clk = 0;
			#10 Clk = 1;
		end
		
		Reset = 1;
		Clk = 0;
		
		for(int i = 0 ; i < 4; i++) begin
			#10 Clk = 0;
			#10 Clk = 1;
		end
		
		Reset = 0;
		for(int i = 0 ; i < 1048576; i++) begin
			#10 Clk = 0;
			#10 Clk = 1;
		end
	end
	
	
endmodule
