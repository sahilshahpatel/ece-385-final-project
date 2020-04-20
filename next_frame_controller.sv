module next_frame_controller(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY,
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
	enum logic [2:0] {WAIT, WAIT_READ, READ, CALCULATE, WRITE, WAIT_WRITE, DONE} state, next_state;
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
		
		case(img_id)
			3'b000 : rom_data = main_character_data;
			3'b001 : rom_data = tile_data;
			default : rom_data = 4'h0;
		endcase
		
		
		/* NOTES:
				- instead of using DrawY and DrawX which will be changing, just set an initial sram_address and increment it (reset on VSYNC)
				- deal with read cycle delay on next_row_buffer (done now?)
		*/
		
		
		// State machine for updating nextFrame
		case (state)
			WAIT: begin				
				if(Start) begin
					next_rom_address = 8'h00;
					// Read next
					next_state = WAIT_READ;
					SRAM_OE_N = 0;
					next_sram_address = {1'b0, ~even_frame, {imgY, imgX[9:2]}}; // Frame stored row-major. 4 pix per word so ignore 2 LSB os x, y
				end
			end
			WAIT_READ: begin
				SRAM_OE_N = 0;
				next_state = READ;
			end
			READ: begin
				SRAM_OE_N = 0;
				// Read current values into write buffer so
				// 	that we can re-write them on transparency
				next_write_buffer = Data_from_SRAM;
				next_state = CALCULATE;
			end
			CALCULATE: begin
				if(rom_address[1:0] == 2'b11) begin
					SRAM_WE_N = 0;
					next_state = WRITE;
				end
				else begin
					// If current pixel is not transparent add to write_buffer
					if(rom_data != 4'h0) begin
						next_write_buffer[rom_address*4 +: 4] = rom_data;
					end
					
					next_rom_address = rom_address + 8'h01;
				end
			end
			WRITE: begin
				SRAM_WE_N = 0;
				// Write write_buffer to SRAM
				// Go to READ state if rom_address isn't all 1s
				if(rom_address == 8'hFF) begin
					// This is the last write of sprite
					next_state = DONE;
				end
				else begin
					// We have more pixels to write
					next_state = WAIT_WRITE;
				end
				
				next_sram_address = {1'b0, ~even_frame, {(imgY + rom_address[7:4]), (imgX[9:2] + rom_address[3:2])}}; // Frame stored row-major
				Data_to_SRAM = write_buffer;
				next_rom_address = rom_address + 8'h01;
			end
			WAIT_WRITE: begin
				SRAM_WE_N = 0;
				Data_to_SRAM = write_buffer;
				next_state = WAIT_READ;
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
