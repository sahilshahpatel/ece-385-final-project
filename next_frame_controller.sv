module next_frame_controller(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY, // TODO: As is, this controller snaps imgX to the nearest SRAM word (i.e. only has accuracy of 4 pixels in X direction)
	input logic Start,
	output logic Done,
	
	// SRAM interface for frame buffers
	input logic even_frame,
	output logic [15:0] Data_to_SRAM,
	input logic [15:0] Data_from_SRAM,
	output logic SRAM_WE_N,
	output logic SRAM_OE_N,
	output logic [19:0] SRAM_ADDRESS
);

	// Srite ROMs in on-chip memory
	// rom_address[1:0] tells us which of 4 pixels per SRAM word
	// rom_address[3:2] tells us which column we are on
	// rom_address[7:4] tells us which row we are on
	logic [7:0] rom_address, next_rom_address;
	logic [3:0] rom_data, main_character_data, tile_data;
	imgROM #(.FILE("main-character.txt")) main_character_rom (
		.Clk,
		.address(rom_address),
		.data(main_character_data)
	);
	imgROM #(.FILE("tile.txt")) tile_rom(
		.Clk,
		.address(rom_address),
		.data(tile_data)
	);
	
	// Frame buffers in SRAM (SRAM_ADDRESS[19] == 0)
	// currentFrame = SRAM_ADDRESS[18] = even_frame
	// nextFrame = SRAM_ADDRESS[18] = ~even_frame
	// each 16-bit word from SRAM is 4 pixels

	
	// State machine to execute commands from software
	enum logic [3:0] {WAIT, WAIT_READ, WAIT_READ_2, READ, WAIT_CALCULATE, CALCULATE, WRITE, WAIT_WRITE, WAIT_WRITE_2, DONE} state, next_state;
	logic [15:0] write_buffer, next_write_buffer;
	logic [19:0] sram_address, next_sram_address;
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			// Reset state
			state <= WAIT;
			rom_address <= 0;
			write_buffer <= 0;
			sram_address <= {1'b0, even_frame, 18'b0};
;
		end
		else if(EN) begin
			// Enabled, change states
			state <= next_state;
			rom_address <= next_rom_address;
			write_buffer <= next_write_buffer;
			sram_address <= next_sram_address;
		end
		else begin
			// Not enabled -- change nothing
			state <= state;
			rom_address <= rom_address;
			write_buffer <= write_buffer;
			sram_address <= sram_address;
		end
	end
	
	always_comb begin
		// Defaults
		next_state = state;
		next_rom_address = rom_address;
		next_write_buffer = write_buffer;
		next_sram_address = sram_address;
		
		SRAM_ADDRESS = sram_address;
		SRAM_WE_N = 1;
		SRAM_OE_N = 1;
		
		Done = 0;
		Data_to_SRAM = 16'bZ;
		
		// Choose which ROM to read based on img_id
		case(img_id)
			3'b000 : rom_data = main_character_data;
			3'b001 : rom_data = tile_data;
			default : rom_data = 4'h0;
		endcase
		
		// State machine for updating nextFrame
		case (state)
			WAIT: begin				
				if(Start) begin
					next_rom_address = 8'h00;
					// Read next
					next_state = WAIT_READ;
					next_sram_address = {1'b0, ~even_frame, {imgY, imgX[9:2]}}; // Frame stored row-major. 4 pix per word so ignore 2 LSB of x
				end
			end
			WAIT_READ: begin
				SRAM_OE_N = 0;
				next_state = WAIT_READ_2;
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
			
				// Check if done with row
				if(rom_address[1:0] == 2'b11) begin
					next_state = WRITE;
					// rom_address is not incremented here because it will be in WRITE
				end
				else begin				
					next_rom_address = rom_address + 8'h01;
					next_state = WAIT_CALCULATE;
				end
			end
			WRITE: begin
				SRAM_WE_N = 0;
				
				next_sram_address = {1'b0, ~even_frame, {(imgY + rom_address[7:4]), (imgX[9:2] + rom_address[3:2])}}; // Frame stored row-major
				Data_to_SRAM = write_buffer;
				
				// Increment rom_address to next row
				next_rom_address = rom_address + 8'h01;
				
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
				
				if(rom_address == 8'h00) begin // 0 because it was incremented in WRITE and overflowed
					// This is the last write of sprite
					next_state = DONE;
				end
				else begin
					// We have more pixels to write
					next_sram_address = {1'b0, ~even_frame, {(imgY + rom_address[7:4]), (imgX[9:2] + rom_address[3:2])}}; // Frame stored row-major
					next_state = WAIT_READ;
				end
			end
			DONE: begin
				Done = 1;
				if(Start == 0) begin
					next_state = WAIT;
				end
			end
		endcase		
	end
	
endmodule
