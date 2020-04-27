module curr_frame_controller(
	input logic Clk, Reset, EN,
	
	output logic step_done, // Tells graphics_accelerator when it can switch controllers
	
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
	//logic VGA_CLK_reset; // For simulation only
	//halftime vga_clk_simulator (.Clk, .Reset(VGA_CLK_reset), .half_Clk(VGA_CLK)); // For simulation only
	vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));

	logic new_frame; // Frame_clk but it stays until both controllers have recieved the message.
	falling_edge_detector frame_clk_detector(.signal(VGA_VS), .Clk, .falling_edge(frame_clk));
	
	logic [9:0] DrawX, DrawY;
	VGA_controller vga_controller_instance(.Clk, .Reset(Reset), .VGA_HS, .VGA_VS, .VGA_CLK, .VGA_BLANK_N, .VGA_SYNC_N, .DrawX, .DrawY);
	
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
	logic [7:0] read_col_counter, clear_col_counter;
	logic [9:0] read_row_counter, clear_row_counter;
	
	palette palette_0 (
		.colorIdx(row_buffer_out[{DrawX[1:0], 2'b00} +: 4]), // 2 LSB specifcy pixel within word
		.VGA_R, .VGA_G, .VGA_B
	); // Outputs VGA RGB based on color palette
	
	// sram_address[7:0] is col counter (256 16-bit/4-pixel words in each row of SRAM)
	// sram_address[17:8] is row counter (1024 rows of SRAM)
	logic [19:0] sram_address, next_sram_address;
	assign col_counter = sram_address[7:0];
	assign row_counter = sram_address[17:8];
	
	enum logic [2:0] {DONE, CLEAR_SYNC, CLEAR, CLEAR_WAIT, READ_SYNC, READ, READ_WAIT, ROW_DONE} state, next_state;
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			even_frame <= 0;
		
			state <= DONE;
			sram_address <= {1'b0, 1'b0, 18'b0};
			
			new_frame <= frame_clk;
		end
		else if (EN) begin
			// Enabled -- progress state machine
			state <= next_state;
			sram_address <= next_sram_address;
			
			new_frame <= frame_clk;
			
			if(frame_clk) begin
				even_frame <= ~even_frame;
			end
		end
		else begin
			// Not enabled -- pause state machine
			state <= state;
			sram_address <= sram_address;
			
			if(frame_clk == 1) begin
				new_frame <= frame_clk;
			end
			else begin
				new_frame <= new_frame;
			end
			
			if(frame_clk) begin
				even_frame <= ~even_frame;
			end
		end
	end
	
	always_comb begin
		// Defaults
		step_done = 0;
		
		// State variables retain value by default
		next_state = state;
		next_sram_address = sram_address;
		
		// SRAM is totally inactive in default state
		SRAM_OE_N = 1;
		SRAM_WE_N = 1;
		SRAM_ADDRESS = 20'h00DEF;
		Data_to_SRAM = 16'h0DEF;
		
		// Row buffer is not writing by default
		row_buffer_we = 0;
		row_buffer_addr = 0;
		row_buffer_in = 0;
	
		case (state)
			DONE: begin
				if(new_frame) begin
					next_state = READ_SYNC;
				end

				step_done = 1; // We can pause here for NFC
			end
			READ_SYNC: begin //accounts for sync delay
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				next_state = READ;
				next_sram_address = {1'b0, even_frame, 18'b0};
			end 
			READ: begin
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				SRAM_ADDRESS = sram_address;
				
				if(col_counter != 0) begin // Don't write to row buffer on first -- have to wait for memory.
					row_buffer_we = 1;
					row_buffer_addr = col_counter - 8'd1; // Write to the previous 
					row_buffer_in = Data_from_SRAM;
				end
				
				
				if(col_counter == 8'hff) begin
					next_state = READ_WAIT;
				end
				else begin
					next_sram_address = sram_address + 20'd1; // Increments address (and col_counter) but not for last one to preserve row
				end
			end
			READ_WAIT: begin // Handles memory delay for last read  				
				SRAM_OE_N = 0;
				SRAM_WE_N = 1;
				SRAM_ADDRESS = sram_address;
				
				row_buffer_we = 1;
				row_buffer_addr = col_counter;
				row_buffer_in = Data_from_SRAM;
				
				next_state = CLEAR_SYNC;
			end
			CLEAR_SYNC: begin			
				SRAM_WE_N = 0;
				next_sram_address = {1'b0, even_frame, row_counter, 8'b0}; // Reset to beginning of the just-read row
				next_state = CLEAR;
			end
			CLEAR: begin			
				SRAM_WE_N = 0;
				SRAM_ADDRESS = sram_address;
				
				Data_to_SRAM = 16'h1111; // 4 pixels of background color
				
				// Keep clearing until done with row
				if(col_counter == 8'hFF) begin
					next_state = CLEAR_WAIT;
				end
				else begin
					next_sram_address = sram_address + 20'd1;
				end
			end
			CLEAR_WAIT: begin
				// SRAM_WE_N will be low b/c of synchronizer
				SRAM_ADDRESS = sram_address;
				Data_to_SRAM = 16'h1111;
				
				next_sram_address = sram_address + 20'd1; // clear_sram_address wasn't incremented on last CLEAR
				
				next_state = ROW_DONE;		
			end
			ROW_DONE: begin
				if(row_counter == 10'b0) begin // If last row is done, move to DONE
					next_state = DONE;
				end
				else if(VGA_HS == 0) begin // During horizontal blanking is when we start fetching the next row
					next_state = READ_SYNC;
				end
				
				step_done = 1; // We can pause here for NFC
			end
		endcase
	end
		
endmodule
