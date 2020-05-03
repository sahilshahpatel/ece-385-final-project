module next_frame_controller(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[3:0] spritesheetX, // 256 cols = 16 sprites (16x16 each)
	input logic [2:0] spritesheetY, // 128 rows = 8 sprites (16x16 each)
	input logic [9:0] imgX, imgY, // TODO: As is, this controller snaps imgX to the nearest SRAM word (i.e. only has accuracy of 4 pixels in X direction)
	input logic draw_start, clear_start,
	output logic done,
	
	output logic step_done, // Tells graphics_accelerator when it can switch controllers
	
	// SRAM interface for frame buffers
	output logic even_frame,
	output logic [15:0] Data_to_SRAM,
	input logic [15:0] Data_from_SRAM,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	// Spritesheet ROM in on-chip memory	
	// rom_address[14:8] is row of spritesheet
	// rom_address[7:4] is column of sprite on sprite sheet
	// rom_address[3:0] is which pixel within column
	logic [14:0] rom_address, next_rom_address;
	logic [3:0] rom_data;
	spritesheetROM #(.FILE("spritesheet.txt")) spritesheet
	(
		.Clk,
		.address(rom_address),
		.data(rom_data)
	);
	
	// Frame buffers in SRAM (SRAM_ADDRESS[19] == 0)
	// currentFrame = SRAM_ADDRESS[18] = even_frame
	// nextFrame = SRAM_ADDRESS[18] = ~even_frame
	// each 16-bit word from SRAM is 4 pixels
	logic next_even_frame;
	
	// State machine to execute commands from software
	enum logic [3:0] {WAIT, WAIT_READ, WAIT_READ_2, READ, WAIT_CALCULATE, CALCULATE, WRITE, WAIT_WRITE, WAIT_WRITE_2, CLEAR_SYNC, CLEAR, CLEAR_WAIT, ROW_DONE, DONE} state, next_state;
	logic [15:0] write_buffer, next_write_buffer;
	logic [19:0] sram_address, next_sram_address;
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			// Reset state
			state <= WAIT;
			rom_address <= 0;
			write_buffer <= 0;
			sram_address <= {1'b0, even_frame, 18'b0};
			even_frame <= 0;
		end
		else if(EN) begin
			// Enabled, change states
			state <= next_state;
			rom_address <= next_rom_address;
			write_buffer <= next_write_buffer;
			sram_address <= next_sram_address;
			even_frame <= next_even_frame;
		end
		else begin
			// Not enabled -- change nothing (exception: leave done state if applicable)
			if(state == DONE) begin
				state <= next_state;
			end
			else begin
				state <= state;
			end
			rom_address <= rom_address;
			write_buffer <= write_buffer;
			sram_address <= sram_address;
			even_frame <= even_frame;
		end
	end
	
	always_comb begin
		// Defaults
		step_done = 0;
		
		next_even_frame = even_frame;
		
		next_state = state;
		next_rom_address = rom_address;
		next_write_buffer = write_buffer;
		next_sram_address = sram_address;
		
		SRAM_ADDRESS = sram_address;
		SRAM_WE_N = 1;
		SRAM_OE_N = 1;
		
		done = 0;
		Data_to_SRAM = 16'bZ;
		
		// State machine for updating nextFrame
		case (state)
			WAIT: begin
				step_done = 1; // We can pause here for CFC			
				
				if(clear_start) begin
					next_even_frame = ~even_frame; // Switch CFB and NFB
					next_sram_address = {1'b0, even_frame, 18'b0}; // Clear the new NFB
					next_state = CLEAR_SYNC;
				end
				else if(draw_start) begin
					// Software specified which sprite, so we shift by 16
					next_rom_address = {{spritesheetY, 4'b0}, {spritesheetX, 4'b0}};

					next_state = WAIT_READ;
					next_sram_address = {1'b0, ~even_frame, {imgY, imgX[9:2]}}; // Frame stored row-major. 4 pix per word so ignore 2 LSB of x
				end
			end
			WAIT_READ: begin
				SRAM_OE_N = 0;
				next_state = WAIT_READ_2;
				next_sram_address = {1'b0, ~even_frame, {(imgY + rom_address[8 +: 4]), (imgX[9:2] + rom_address[2 +: 2])}}; // Frame stored row-major
			end
			WAIT_READ_2: begin
				SRAM_OE_N = 0;
				next_state = READ;
			end
			READ: begin
				SRAM_OE_N = 0;
				// Read current values into write buffer so
				// 	that we can re-write them on transparency
				
				next_write_buffer = Data_from_SRAM;
				next_state = WAIT_CALCULATE;
			end
			WAIT_CALCULATE: begin
				next_state = CALCULATE; // Waits for rom_data to be valid
			end
			CALCULATE: begin
				// If current pixel is not transparent add to write_buffer
				if(rom_data != 4'h0) begin
					next_write_buffer[{rom_address[1:0], 2'b00} +: 4] = rom_data;
				end
			
				// Check if done with SRAM row
				if(rom_address[1:0] == 2'b11) begin
					next_state = WRITE;
					// rom_address is not incremented here because it will be in WRITE
				end
				else begin
					next_rom_address[1:0] = rom_address[1:0] + 2'd1;
					next_state = WAIT_CALCULATE;
				end
			end
			WRITE: begin
				SRAM_WE_N = 0;
				Data_to_SRAM = write_buffer;
				
				next_state = WAIT_WRITE;
			end
			WAIT_WRITE: begin
				SRAM_WE_N = 0;
				Data_to_SRAM = write_buffer;
				next_state = WAIT_WRITE_2;
			end
			WAIT_WRITE_2: begin
				SRAM_WE_N = 1; // Disable writing for next state (synchronized)
				Data_to_SRAM = write_buffer;
				
				if(rom_address[8 +: 4] == 4'hf && rom_address[2 +: 2] == 2'b11) begin
					// This is the last write of sprite
					next_state = DONE;
				end
				else begin
					// We have more pixels to write
					
					if(rom_address[3:0] == 4'hf) begin
						// Increment rom_address to next row and reset column
						next_rom_address = {rom_address[8 +: 7] + 7'd1, {spritesheetX, 4'b0}};
					end
					else begin
						// Move right to the next 4 pixels
						next_rom_address[3:0] = rom_address[3:0] + 4'd1;
					end
					
					next_state = WAIT_READ;
				end
			end
			CLEAR_SYNC: begin
				SRAM_WE_N = 1'b0;
				
				next_state = CLEAR;
			end
			CLEAR: begin
				SRAM_WE_N = 1'b0;
				Data_to_SRAM = 16'h1111;
				
				next_sram_address[17:0] = sram_address[17:0] + 18'd1;
				
				// If we are done with the row, go to clear_wait
				if(sram_address[7:0] == 8'hFF) begin
					next_state = CLEAR_WAIT;
				end
			end
			CLEAR_WAIT: begin
				// WE_N will be low from synchronizer
				Data_to_SRAM = 16'h1111;
				
				step_done = 1;
				next_state = ROW_DONE;
			end
			ROW_DONE: begin				
				// If we cleared the buffer, we are done
				if(sram_address[17:0] == 18'b0) begin
					next_state = DONE;
				end
				else begin
					next_state = CLEAR_SYNC;
				end
			end
			DONE: begin
				step_done = 1; // We can pause here for CFC
				
				done = 1;
				if(draw_start == 0 && clear_start == 0) begin
					next_state = WAIT;
				end
			end
		endcase		
	end
	
endmodule
