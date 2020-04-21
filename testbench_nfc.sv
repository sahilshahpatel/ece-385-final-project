module testbench_nfc;

timeunit 1ns;
timeprecision 1ns;

logic Clk;
logic Reset;
logic EN = 1;

// Software interface
logic[2:0] img_id;
logic [9:0] imgX, imgY;
logic Start;
logic Done;

// SRAM interface for frame buffers
logic even_frame = 0;
wire [15:0] SRAM_DQ;
logic SRAM_WE_N;
logic SRAM_OE_N;
logic [19:0] SRAM_ADDRESS;

test_nfc_top_level test_top (.*);


initial begin: TESTVECTORS
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
	Start = 1;
	
	for(int i = 0 ; i < 50; i++) begin
		#10 Clk = 0;
		#10 Clk = 1;
	end
end

endmodule
