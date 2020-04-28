module next_frame_controller(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[4:0] img_id,
	input logic [9:0] imgX, imgY, // TODO: As is, this controller snaps imgX to the nearest SRAM word (i.e. only has accuracy of 4 pixels in X direction)
	input logic Start,
	output logic Done,
	
	output logic step_done, // Tells graphics_accelerator when it can switch controllers
	
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
	logic [3:0] rom_data;
	
	logic [3:0] player32_0_data;
	imgROM #(.FILE("sprites/player32_0.txt")) player32_0_rom(
		.Clk,
		.address(rom_address),
		.data(player32_0_data)
	);
	
	logic [3:0] player32_1_data;
	imgROM #(.FILE("sprites/player32_1.txt")) player32_1_rom(
		.Clk,
		.address(rom_address),
		.data(player32_1_data)
	);
	
	logic [3:0] player32_2_data;
	imgROM #(.FILE("sprites/player32_2.txt")) player32_2_rom(
		.Clk,
		.address(rom_address),
		.data(player32_2_data)
	);
	
	logic [3:0] player32_3_data;
	imgROM #(.FILE("sprites/player32_3.txt")) player32_3_rom(
		.Clk,
		.address(rom_address),
		.data(player32_3_data)
	);
	
	logic [3:0] monster32_0_data;
	imgROM #(.FILE("sprites/monster32_0.txt")) monster32_0_rom(
		.Clk,
		.address(rom_address),
		.data(monster32_0_data)
	);
	logic [3:0] monster32_1_data;
	imgROM #(.FILE("sprites/monster32_1.txt")) monster32_1_rom(
		.Clk,
		.address(rom_address),
		.data(monster32_1_data)
	);
	logic [3:0] monster32_2_data;
	imgROM #(.FILE("sprites/monster32_2.txt")) monster32_2_rom(
		.Clk,
		.address(rom_address),
		.data(monster32_2_data)
	);
	logic [3:0] monster32_3_data;
	imgROM #(.FILE("sprites/monster32_3.txt")) monster32_3_rom(
		.Clk,
		.address(rom_address),
		.data(monster32_3_data)
	);
	logic [3:0] player_light32_0_data;
	imgROM #(.FILE("sprites/player-light32_0.txt")) player_light32_0_rom(
		.Clk,
		.address(rom_address),
		.data(player_light32_0_data)
	);
	logic [3:0] player_light32_1_data;
	imgROM #(.FILE("sprites/player-light32_1.txt")) player_light32_1_rom(
		.Clk,
		.address(rom_address),
		.data(player_light32_1_data)
	);
	logic [3:0] player_light32_2_data;
	imgROM #(.FILE("sprites/player-light32_2.txt")) player_light32_2_rom(
		.Clk,
		.address(rom_address),
		.data(player_light32_2_data)
	);
	logic [3:0] player_light32_3_data;
	imgROM #(.FILE("sprites/player-light32_3.txt")) player_light32_3_rom(
		.Clk,
		.address(rom_address),
		.data(player_light32_3_data)
	);
	logic [3:0] spikes32_0_data;
	imgROM #(.FILE("sprites/spikes32_0.txt")) spikes32_0_rom(
		.Clk,
		.address(rom_address),
		.data(spikes32_0_data)
	);
	logic [3:0] spikes32_1_data;
	imgROM #(.FILE("sprites/spikes32_1.txt")) spikes32_1_rom(
		.Clk,
		.address(rom_address),
		.data(spikes32_1_data)
	);
	logic [3:0] spikes32_2_data;
	imgROM #(.FILE("sprites/spikes32_2.txt")) spikes32_2_rom(
		.Clk,
		.address(rom_address),
		.data(spikes32_2_data)
	);
	logic [3:0] spikes32_3_data;
	imgROM #(.FILE("sprites/spikes32_3.txt")) spikes32_3_rom(
		.Clk,
		.address(rom_address),
		.data(spikes32_3_data)
	);
	logic [3:0] tile32_0_data;
	imgROM #(.FILE("sprites/tile32_0.txt")) tile32_0_rom(
		.Clk,
		.address(rom_address),
		.data(tile32_0_data)
	);
	logic [3:0] tile32_1_data;
	imgROM #(.FILE("sprites/tile32_1.txt")) tile32_1_rom(
		.Clk,
		.address(rom_address),
		.data(tile32_1_data)
	);
	logic [3:0] tile32_2_data;
	imgROM #(.FILE("sprites/tile32_2.txt")) tile32_2_rom(
		.Clk,
		.address(rom_address),
		.data(tile32_2_data)
	);
	logic [3:0] tile32_3_data;
	imgROM #(.FILE("sprites/tile32_3.txt")) tile32_3_rom(
		.Clk,
		.address(rom_address),
		.data(tile32_3_data)
	);
	logic [3:0] wall32_0_data;
	imgROM #(.FILE("sprites/wall32_0.txt")) wall32_0_rom(
		.Clk,
		.address(rom_address),
		.data(wall32_0_data)
	);
	logic [3:0] wall32_1_data;
	imgROM #(.FILE("sprites/wall32_1.txt")) wall32_1_rom(
		.Clk,
		.address(rom_address),
		.data(wall32_1_data)
	);
	logic [3:0] wall32_2_data;
	imgROM #(.FILE("sprites/wall32_2.txt")) wall32_2_rom(
		.Clk,
		.address(rom_address),
		.data(wall32_2_data)
	);
	logic [3:0] wall32_3_data;
	imgROM #(.FILE("sprites/wall32_3.txt")) wall32_3_rom(
		.Clk,
		.address(rom_address),
		.data(wall32_3_data)
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
		step_done = 0;
		
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
			5'd0  : rom_data = player32_0_data;
			5'd1  : rom_data = player32_1_data;
			5'd2  : rom_data = player32_2_data;
			5'd3  : rom_data = player32_3_data; 
			5'd4  : rom_data = monster32_0_data;
			5'd5  : rom_data = monster32_1_data;
			5'd6  : rom_data = monster32_2_data;
			5'd7  : rom_data = monster32_3_data;
			5'd8  : rom_data = player_light32_0_data;
			5'd9  : rom_data = player_light32_1_data;
			5'd10 : rom_data = player_light32_2_data;
			5'd11 : rom_data = player_light32_3_data;
			5'd12 : rom_data = spikes32_0_data;
			5'd13 : rom_data = spikes32_1_data;
			5'd14 : rom_data = spikes32_2_data;
			5'd15 : rom_data = spikes32_3_data;
			5'd16 : rom_data = tile32_0_data;
			5'd17 : rom_data = tile32_1_data;
			5'd18 : rom_data = tile32_2_data;
			5'd19 : rom_data = tile32_3_data;
			5'd20 : rom_data = wall32_0_data;
			5'd21 : rom_data = wall32_1_data;
			5'd22 : rom_data = wall32_2_data;
			5'd23 : rom_data = wall32_3_data;
			
			default : rom_data = 4'h0;
		endcase
		
		// State machine for updating nextFrame
		case (state)
			WAIT: begin
				step_done = 1; // We can pause here for CFC			
				
				if(Start) begin
					next_rom_address = 8'h00;

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
				step_done = 1; // We can pause here for CFC
				
				Done = 1;
				if(Start == 0) begin
					next_state = WAIT;
				end
			end
		endcase		
	end
	
endmodule
