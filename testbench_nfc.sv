module testbench_nfc;

timeunit 1ns;
timeprecision 1ns;

logic Clk;
logic Reset;
logic EN = 1;

// Software interface
logic[2:0] img_id;
logic [9:0] imgX, imgY;
logic draw_start, clear_start;
logic done;
logic can_clear;

// SRAM interface for frame buffers
logic even_frame = 0;
logic step_done;
wire [15:0] SRAM_DQ;
logic SRAM_WE_N;
logic SRAM_OE_N;
logic [19:0] SRAM_ADDRESS;

test_nfc_top_level test_top (.*);


initial begin: TESTVECTORS
	clear_start = 0;
	can_clear = 0;

	Reset = 1;
	Clk = 0;
	
	for(int i = 0 ; i < 2; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
	
	Reset = 0;
	for(int i = 0 ; i < 2; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
	
	img_id = 0;
	imgX = 0;
	imgY = 0;
	draw_start = 1;
	
	for(int i = 0 ; i < 1050; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
end

endmodule
