module curr_frame_controller(
	input logic Clk, Reset, EN,
	
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
	output logic even_frame, frame_clk,
	output logic [15:0] Data_to_SRAM,
	input logic [15:0] Data_from_SRAM,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	// Use PLL to generate the 25MHZ VGA_CLK.
	// You will have to generate it on your own in simulation.
	vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));

	rising_edge_detector frame_clk_detector(.signal(VGA_VS), .Clk, .rising_edge(frame_clk));

	always_ff @(posedge frame_clk) begin
		if(Reset) begin
			even_frame <= 0;
		end
		else begin
			even_frame <= ~even_frame; // Tells us about order of frame buffers
		end
	end
	
	logic [9:0] DrawX, DrawY;
	VGA_controller vga_controller_instance(.Clk, .Reset(Reset), .VGA_HS, .VGA_VS, .VGA_CLK, .VGA_BLANK_N, .VGA_SYNC_N, .DrawX, .DrawY);
	
	palette palette_0 (
		.colorIdx(row_buffer_out[DrawX[1:0]]), // 2 LSB specifcy pixel within word
		.VGA_R, .VGA_G, .VGA_B
	); // Outputs VGA RGB based on color palette
	
	// Frame buffers in SRAM (SRAM_ADDRESS[19] == 0)
	// currentFrame = SRAM_ADDRESS[18] = even_frame
	// nextFrame = SRAM_ADDRESS[18] = ~even_frame
	// each 16-bit word from SRAM is 4 pixels
	
	// Store next row of current frame buffer in row_buffer
	logic [7:0] row_buffer_addr;
	logic [15:0] row_buffer_out, row_buffer_in;
	logic row_buffer_we;
	rowRAM row_buffer(
		.Clk,
		.we(row_buffer_we),
		.write_address(row_buffer_addr),
		.read_address(DrawX[9:2]), // Upper 8 bits specify which 16-bit column
		.data_in(row_buffer_in),
		.data_out(row_buffer_out)
	);
	logic [7:0] col_counter;
	logic [9:0] row_counter;
	
	// sram_address[7:0] is col counter (256 16-bit/4-pixel words in each row of SRAM)
	// sram_address[17:8] is row counter (1024 rows of SRAM)
	logic [19:0] sram_address, next_sram_address;
	assign col_counter = sram_address[7:0];
	assign row_counter = sram_address[9:0];
	
	enum logic [2:0] {DONE, READ_SYNC, READ, READ_WAIT, CLEAR} state, next_state;
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			state <= DONE;
			sram_address <= {1'b0, even_frame, 18'b0}; 
		end
		else if (EN) begin
			// Enabled -- progress state machine
			state <= next_state;
			sram_address <= next_sram_address;
		end
		else begin
			// Not enabled -- pause state machine
			state <= state;
			sram_address <= sram_address;
		end
	end
	
	always_comb begin
		// Defaults
		next_state = state;
		next_sram_address = sram_address;
		
		SRAM_OE_N = 1;
		SRAM_WE_N = 1;
		SRAM_ADDRESS = 0;
		
		row_buffer_we = 0;
		row_buffer_addr = 0;
		row_buffer_in = 0;
	
		case (state)
			READ_SYNC: begin //accounts for sync delay
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				next_state = READ;
			end 
			READ: begin
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				SRAM_ADDRESS = sram_address;
				
				if(col_counter != 0) begin // Don't write to row buffer on first -- have to wait for memory.
					row_buffer_we = 1;
					row_buffer_addr = col_counter - 1; // Write to the previous 
					row_buffer_in = Data_from_SRAM;
				end
				
				next_sram_address = sram_address + 1; // Increments address (and col_counter)
				
				if(col_counter == 8'hff) begin
					next_state = READ_WAIT;
				end
				else begin
					next_state = READ;
				end
			end
			READ_WAIT: begin // Handles memory delay for last read  
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				SRAM_ADDRESS = sram_address - 1;
				
				row_buffer_we = 1;
				row_buffer_addr = col_counter - 1;
				row_buffer_in = Data_from_SRAM;
				
				next_state = DONE;
			end
			DONE: begin
				if(frame_clk) begin
					next_state = CLEAR;
				end
			end
			CLEAR: begin
				next_state = READ_SYNC; // TODO: Remove this and replace with clearing nextFrame buffer back to neutral background
				//TODO:at the end we will need to reset sram  based on even frame again.
			end
		endcase
	end
		
endmodule
