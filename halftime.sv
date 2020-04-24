module halftime(
	input logic Clk, Reset,
	output logic half_Clk
);

logic counter;

always_ff @(posedge Clk) begin
	if(Reset) begin
		counter <= 1'b0;
	end
	else begin
		counter <= counter + 1'b1;
	end
end

assign half_Clk = counter;

endmodule
