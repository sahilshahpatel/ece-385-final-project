module halftime(
	input logic Clk,
	output logic half_Clk
);

logic [1:0] counter;

always_ff @(posedge Clk) begin
	counter <= counter + 2'b01;
end

assign half_Clk = counter[1];

endmodule
