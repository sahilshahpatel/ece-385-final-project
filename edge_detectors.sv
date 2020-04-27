module rising_edge_detector(
	input logic signal,
	input logic Clk, 
	output logic rising_edge
);

	logic prev_signal;

	always_ff @ (posedge Clk) begin
		prev_signal <= signal;
		//rising_edge <= signal & ~prev_signal;
	end

	always_comb begin
		rising_edge = signal & ~prev_signal;
	end

endmodule

module falling_edge_detector(
	input logic signal,
	input logic Clk, 
	output logic falling_edge
);

	logic prev_signal;

	always_ff @ (posedge Clk) begin
		prev_signal <= signal;
		//falling_edge <= ~signal & prev_signal;	
	end

	always_comb begin
		falling_edge = ~signal & prev_signal;
	end

endmodule