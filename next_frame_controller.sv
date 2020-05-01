module next_frame_controller(
	input logic Clk, Reset, EN,
	
	// Software interface
	input logic[31:0] img_id,
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
	logic [3:0] stairs_up32_0_data;
	imgROM #(.FILE("sprites/stairs-up32_0.txt")) stairs_up32_0_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_up32_0_data)
	);
	logic [3:0] stairs_up32_1_data;
	imgROM #(.FILE("sprites/stairs-up32_1.txt")) stairs_up32_1_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_up32_1_data)
	);
	logic [3:0] stairs_up32_2_data;
	imgROM #(.FILE("sprites/stairs-up32_2.txt")) stairs_up32_2_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_up32_2_data)
	);
	logic [3:0] stairs_up32_3_data;
	imgROM #(.FILE("sprites/stairs-up32_3.txt")) stairs_up32_3_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_up32_3_data)
	);
	logic [3:0] stairs_left32_0_data;
	imgROM #(.FILE("sprites/stairs-left32_0.txt")) stairs_left32_0_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_left32_0_data)
	);
	logic [3:0] stairs_left32_1_data;
	imgROM #(.FILE("sprites/stairs-left32_1.txt")) stairs_left32_1_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_left32_1_data)
	);
	logic [3:0] stairs_left32_2_data;
	imgROM #(.FILE("sprites/stairs-left32_2.txt")) stairs_left32_2_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_left32_2_data)
	);
	logic [3:0] stairs_left32_3_data;
	imgROM #(.FILE("sprites/stairs-left32_3.txt")) stairs_left32_3_rom(
		.Clk,
		.address(rom_address),
		.data(stairs_left32_3_data)
	);
	
	
	
	logic [3:0] alphanumerics_00_data;
	imgROM #(.FILE("sprites/alphanumerics_00.txt")) alphanumerics_00_rom(
		.Clk, .address(rom_address), .data(alphanumerics_00_data)
	);
	logic [3:0] alphanumerics_01_data;
	imgROM #(.FILE("sprites/alphanumerics_01.txt")) alphanumerics_01_rom(
		.Clk, .address(rom_address), .data(alphanumerics_01_data)
	);
	logic [3:0] alphanumerics_02_data;
	imgROM #(.FILE("sprites/alphanumerics_02.txt")) alphanumerics_02_rom(
		.Clk, .address(rom_address), .data(alphanumerics_02_data)
	);
	logic [3:0] alphanumerics_03_data;
	imgROM #(.FILE("sprites/alphanumerics_03.txt")) alphanumerics_03_rom(
		.Clk, .address(rom_address), .data(alphanumerics_03_data)
	);
	logic [3:0] alphanumerics_04_data;
	imgROM #(.FILE("sprites/alphanumerics_04.txt")) alphanumerics_04_rom(
		.Clk, .address(rom_address), .data(alphanumerics_04_data)
	);
	logic [3:0] alphanumerics_05_data;
	imgROM #(.FILE("sprites/alphanumerics_05.txt")) alphanumerics_05_rom(
		.Clk, .address(rom_address), .data(alphanumerics_05_data)
	);
	logic [3:0] alphanumerics_06_data;
	imgROM #(.FILE("sprites/alphanumerics_06.txt")) alphanumerics_06_rom(
		.Clk, .address(rom_address), .data(alphanumerics_06_data)
	);
	logic [3:0] alphanumerics_07_data;
	imgROM #(.FILE("sprites/alphanumerics_07.txt")) alphanumerics_07_rom(
		.Clk, .address(rom_address), .data(alphanumerics_07_data)
	);
	logic [3:0] alphanumerics_08_data;
	imgROM #(.FILE("sprites/alphanumerics_08.txt")) alphanumerics_08_rom(
		.Clk, .address(rom_address), .data(alphanumerics_08_data)
	);
	logic [3:0] alphanumerics_09_data;
	imgROM #(.FILE("sprites/alphanumerics_09.txt")) alphanumerics_09_rom(
		.Clk, .address(rom_address), .data(alphanumerics_09_data)
	);
	logic [3:0] alphanumerics_10_data;
	imgROM #(.FILE("sprites/alphanumerics_10.txt")) alphanumerics_10_rom(
		.Clk, .address(rom_address), .data(alphanumerics_10_data)
	);
	logic [3:0] alphanumerics_11_data;
	imgROM #(.FILE("sprites/alphanumerics_11.txt")) alphanumerics_11_rom(
		.Clk, .address(rom_address), .data(alphanumerics_11_data)
	);
	logic [3:0] alphanumerics_12_data;
	imgROM #(.FILE("sprites/alphanumerics_12.txt")) alphanumerics_12_rom(
		.Clk, .address(rom_address), .data(alphanumerics_12_data)
	);
	logic [3:0] alphanumerics_13_data;
	imgROM #(.FILE("sprites/alphanumerics_13.txt")) alphanumerics_13_rom(
		.Clk, .address(rom_address), .data(alphanumerics_13_data)
	);
	logic [3:0] alphanumerics_14_data;
	imgROM #(.FILE("sprites/alphanumerics_14.txt")) alphanumerics_14_rom(
		.Clk, .address(rom_address), .data(alphanumerics_14_data)
	);
	logic [3:0] alphanumerics_15_data;
	imgROM #(.FILE("sprites/alphanumerics_15.txt")) alphanumerics_15_rom(
		.Clk, .address(rom_address), .data(alphanumerics_15_data)
	);
	logic [3:0] alphanumerics_16_data;
	imgROM #(.FILE("sprites/alphanumerics_16.txt")) alphanumerics_16_rom(
		.Clk, .address(rom_address), .data(alphanumerics_16_data)
	);
	logic [3:0] alphanumerics_17_data;
	imgROM #(.FILE("sprites/alphanumerics_17.txt")) alphanumerics_17_rom(
		.Clk, .address(rom_address), .data(alphanumerics_17_data)
	);
	logic [3:0] alphanumerics_18_data;
	imgROM #(.FILE("sprites/alphanumerics_18.txt")) alphanumerics_18_rom(
		.Clk, .address(rom_address), .data(alphanumerics_18_data)
	);
	logic [3:0] alphanumerics_19_data;
	imgROM #(.FILE("sprites/alphanumerics_19.txt")) alphanumerics_19_rom(
		.Clk, .address(rom_address), .data(alphanumerics_19_data)
	);
	logic [3:0] alphanumerics_20_data;
	imgROM #(.FILE("sprites/alphanumerics_20.txt")) alphanumerics_20_rom(
		.Clk, .address(rom_address), .data(alphanumerics_20_data)
	);
	logic [3:0] alphanumerics_21_data;
	imgROM #(.FILE("sprites/alphanumerics_21.txt")) alphanumerics_21_rom(
		.Clk, .address(rom_address), .data(alphanumerics_21_data)
	);
	logic [3:0] alphanumerics_22_data;
	imgROM #(.FILE("sprites/alphanumerics_22.txt")) alphanumerics_22_rom(
		.Clk, .address(rom_address), .data(alphanumerics_22_data)
	);
	logic [3:0] alphanumerics_23_data;
	imgROM #(.FILE("sprites/alphanumerics_23.txt")) alphanumerics_23_rom(
		.Clk, .address(rom_address), .data(alphanumerics_23_data)
	);
	logic [3:0] alphanumerics_24_data;
	imgROM #(.FILE("sprites/alphanumerics_24.txt")) alphanumerics_24_rom(
		.Clk, .address(rom_address), .data(alphanumerics_24_data)
	);
	logic [3:0] alphanumerics_25_data;
	imgROM #(.FILE("sprites/alphanumerics_25.txt")) alphanumerics_25_rom(
		.Clk, .address(rom_address), .data(alphanumerics_25_data)
	);
	logic [3:0] alphanumerics_26_data;
	imgROM #(.FILE("sprites/alphanumerics_26.txt")) alphanumerics_26_rom(
		.Clk, .address(rom_address), .data(alphanumerics_26_data)
	);
	logic [3:0] alphanumerics_27_data;
	imgROM #(.FILE("sprites/alphanumerics_27.txt")) alphanumerics_27_rom(
		.Clk, .address(rom_address), .data(alphanumerics_27_data)
	);
	logic [3:0] alphanumerics_28_data;
	imgROM #(.FILE("sprites/alphanumerics_28.txt")) alphanumerics_28_rom(
		.Clk, .address(rom_address), .data(alphanumerics_28_data)
	);
	logic [3:0] alphanumerics_29_data;
	imgROM #(.FILE("sprites/alphanumerics_29.txt")) alphanumerics_29_rom(
		.Clk, .address(rom_address), .data(alphanumerics_29_data)
	);
	logic [3:0] alphanumerics_30_data;
	imgROM #(.FILE("sprites/alphanumerics_30.txt")) alphanumerics_30_rom(
		.Clk, .address(rom_address), .data(alphanumerics_30_data)
	);
	logic [3:0] alphanumerics_31_data;
	imgROM #(.FILE("sprites/alphanumerics_31.txt")) alphanumerics_31_rom(
		.Clk, .address(rom_address), .data(alphanumerics_31_data)
	);
	logic [3:0] alphanumerics_32_data;
	imgROM #(.FILE("sprites/alphanumerics_32.txt")) alphanumerics_32_rom(
		.Clk, .address(rom_address), .data(alphanumerics_32_data)
	);
	logic [3:0] alphanumerics_33_data;
	imgROM #(.FILE("sprites/alphanumerics_33.txt")) alphanumerics_33_rom(
		.Clk, .address(rom_address), .data(alphanumerics_33_data)
	);
	logic [3:0] alphanumerics_34_data;
	imgROM #(.FILE("sprites/alphanumerics_34.txt")) alphanumerics_34_rom(
		.Clk, .address(rom_address), .data(alphanumerics_34_data)
	);
	logic [3:0] alphanumerics_35_data;
	imgROM #(.FILE("sprites/alphanumerics_35.txt")) alphanumerics_35_rom(
		.Clk, .address(rom_address), .data(alphanumerics_35_data)
	);
	logic [3:0] alphanumerics_36_data;
	imgROM #(.FILE("sprites/alphanumerics_36.txt")) alphanumerics_36_rom(
		.Clk, .address(rom_address), .data(alphanumerics_36_data)
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
			32'd0  : rom_data = player32_0_data;
			32'd1  : rom_data = player32_1_data;
			32'd2  : rom_data = player32_2_data;
			32'd3  : rom_data = player32_3_data; 
			32'd4  : rom_data = monster32_0_data;
			32'd5  : rom_data = monster32_1_data;
			32'd6  : rom_data = monster32_2_data;
			32'd7  : rom_data = monster32_3_data;
			32'd8  : rom_data = player_light32_0_data;
			32'd9  : rom_data = player_light32_1_data;
			32'd10 : rom_data = player_light32_2_data;
			32'd11 : rom_data = player_light32_3_data;
			32'd12 : rom_data = spikes32_0_data;
			32'd13 : rom_data = spikes32_1_data;
			32'd14 : rom_data = spikes32_2_data;
			32'd15 : rom_data = spikes32_3_data;
			32'd16 : rom_data = tile32_0_data;
			32'd17 : rom_data = tile32_1_data;
			32'd18 : rom_data = tile32_2_data;
			32'd19 : rom_data = tile32_3_data;
			32'd20 : rom_data = wall32_0_data;
			32'd21 : rom_data = wall32_1_data;
			32'd22 : rom_data = wall32_2_data;
			32'd23 : rom_data = wall32_3_data;
			32'd24 : rom_data = stairs_up32_0_data;
			32'd24 : rom_data = stairs_up32_1_data;
			32'd24 : rom_data = stairs_up32_2_data;
			32'd24 : rom_data = stairs_up32_3_data;
			32'd24 : rom_data = stairs_left32_0_data;
			32'd24 : rom_data = stairs_left32_1_data;
			32'd24 : rom_data = stairs_left32_2_data;
			32'd24 : rom_data = stairs_left32_3_data;
			
			
			32'd50: rom_data = alphanumerics_00_data;
			32'd51: rom_data = alphanumerics_01_data;
			32'd52: rom_data = alphanumerics_02_data;
			32'd53: rom_data = alphanumerics_03_data;
			32'd54: rom_data = alphanumerics_04_data;
			32'd55: rom_data = alphanumerics_05_data;
			32'd56: rom_data = alphanumerics_06_data;
			32'd57: rom_data = alphanumerics_07_data;
			32'd58: rom_data = alphanumerics_08_data;
			32'd59: rom_data = alphanumerics_09_data;
			32'd60: rom_data = alphanumerics_10_data;
			32'd61: rom_data = alphanumerics_11_data;
			32'd62: rom_data = alphanumerics_12_data;
			32'd63: rom_data = alphanumerics_13_data;
			32'd64: rom_data = alphanumerics_14_data;
			32'd65: rom_data = alphanumerics_15_data;
			32'd66: rom_data = alphanumerics_16_data;
			32'd67: rom_data = alphanumerics_17_data;
			32'd68: rom_data = alphanumerics_18_data;
			32'd69: rom_data = alphanumerics_19_data;
			32'd70: rom_data = alphanumerics_20_data;
			32'd71: rom_data = alphanumerics_21_data;
			32'd72: rom_data = alphanumerics_22_data;
			32'd73: rom_data = alphanumerics_23_data;
			32'd74: rom_data = alphanumerics_24_data;
			32'd75: rom_data = alphanumerics_25_data;
			32'd76: rom_data = alphanumerics_26_data;
			32'd77: rom_data = alphanumerics_27_data;
			32'd78: rom_data = alphanumerics_28_data;
			32'd79: rom_data = alphanumerics_29_data;
			32'd80: rom_data = alphanumerics_30_data;
			32'd81: rom_data = alphanumerics_31_data;
			32'd82: rom_data = alphanumerics_32_data;
			32'd83: rom_data = alphanumerics_33_data;
			32'd84: rom_data = alphanumerics_34_data;
			32'd85: rom_data = alphanumerics_35_data;
			32'd86: rom_data = alphanumerics_36_data;
			
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
