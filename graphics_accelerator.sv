module graphics_accelerator
(
	input logic Clk, Reset,
	
	input logic[2:0] img_id,
	input logic [9:0] imgX, imgY,
	input logic Start,
	output logic Done,

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
	inout wire [15:0] SRAM_DQ,
	output logic SRAM_UB_N,
	output logic SRAM_LB_N,
	output logic SRAM_CE_N,
	output logic SRAM_OE_N,
	output logic SRAM_WE_N,
	output logic [19:0] SRAM_ADDRESS
);

	// Use PLL to generate the 25MHZ VGA_CLK.
	// You will have to generate it on your own in simulation.
	vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));

	logic frame_clk;
	rising_edge_detector frame_clk_detector(.signal(VGA_VS), .Clk, .rising_edge(frame_clk));

	logic even_frame;
	always_ff @(posedge frame_clk) begin
		even_frame <= ~even_frame; // Tells us about order of frame buffers
	end
	
	logic [9:0] DrawX, DrawY;
	VGA_controller vga_controller_instance(.Clk, .Reset(Reset), .VGA_HS, .VGA_VS, .VGA_CLK, .VGA_BLANK_N, .VGA_SYNC_N, .DrawX, .DrawY);

	//ball ball_instance(.Clk, .Reset(~KEY[0]), .frame_clk, .DrawX, .DrawY, .is_ball, .keycode(keycode[3:0]));

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
	
	// Handle fetching currentFrame during horizontal blanking time (HSYNC == 0)
	// Handle software interface to nextFrame during rest of time.
	logic [7:0] row_buffer_addr;
	logic [15:0] row_buffer_out, row_buffer_in;
	logic row_buffer_we;
	rowRAM row_buffer(
		.Clk,
		.we(row_buffer_we),
		.write_address(row_buffer_addr),
		.read_address(row_buffer_addr),
		.data_in(row_buffer_in),
		.data_out(row_buffer_out)
	);
	logic [7:0] col_counter;
	logic [9:0] row_counter;
	logic [1:0] row_buffer_done, next_row_buffer_done; // Also accounts for 1-cycle read delay
	
	// row_sram_address[7:0] is col counter (256 16-bit/4-pixel words in each row of SRAM)
	// row_sram_address[17:8] is row counter (1024 rows of SRAM)
	// row_sram_address[19:18] is 2'b00 or 2'b01 based on even_frame
	logic [19:0] row_sram_address, next_row_sram_address;
	assign col_counter = row_sram_address[9:4];
	assign row_counter = row_sram_address[19:0];

	
	// Synchronize memory outputs
	logic OE_N_sync, WE_N_sync;
	sync_r1 sync_OE(.Clk, .d(SRAM_OE_N), .q(OE_N_sync), .Reset(Reset)); // Reset to off
	sync_r1 sync_WE(.Clk, .d(SRAM_WE_N), .q(WE_N_sync), .Reset(Reset)); // Reset to off
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	
	// Connect to SRAM via tristate
	logic [15:0] Data_to_SRAM, Data_from_SRAM;
	tristate #(.N(16)) tristate_0 (
		.Clk,
		.tristate_input_enable(~OE_N_sync),
		.tristate_output_enable(~WE_N_sync),
		.Data_write(Data_to_SRAM),
		.Data_read(Data_from_SRAM),
		.Data(SRAM_DQ)
	);
	
	// State machine to execute commands from software
	enum logic [2:0] {FETCH_ROW, WAIT, WAIT_READ, READ, CALCULATE, WRITE, WAIT_WRITE, DONE} state, next_state;
	logic [15:0] write_buffer, next_write_buffer;
	logic [19:0] sram_address, next_sram_address;
	
	always_ff @(posedge Clk) begin
		if(Reset) begin
			even_frame <= 0;
			state <= WAIT;
			rom_address <= 0;
			write_buffer <= 0;
			sram_address <= 0;
			row_buffer_done <= 0;
			row_sram_address <= 0;
		end
		else begin
			state <= next_state;
			rom_address <= next_rom_address;
			write_buffer <= next_write_buffer;
			sram_address <= next_sram_address;
			row_buffer_done <= next_row_buffer_done;
			row_sram_address <= next_row_sram_address;
		end
	end
	
	always_comb begin
		// Defaults
		next_state = state;
		next_rom_address = rom_address;
		next_write_buffer = write_buffer;
		
		next_row_sram_address = row_sram_address;
		next_sram_address = sram_address;
		
		row_buffer_we = 0;
		next_row_buffer_done = row_buffer_done;
		
		SRAM_ADDRESS = sram_address;
		SRAM_WE_N = 1;
		SRAM_OE_N = 1;
		
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
			FETCH_ROW: begin
				if(row_buffer_done != 2'b11) begin
					SRAM_OE_N = 0;
					SRAM_ADDRESS = row_sram_address;
					
					// Reads are one cycle delayed
					if(col_counter != 0) begin
						row_buffer_we = 1;
						row_buffer_addr = row_sram_address[7:0];
						row_buffer_in = Data_from_SRAM;
					end
					if(col_counter == 8'hFF) begin
						next_row_buffer_done = 2'b01;
					end
					
					if(row_buffer_done == 2'b01) begin
						next_row_buffer_done = 2'b11;
					end
					else begin
						next_row_sram_address = row_sram_address + 1;
					end
				end
				
				if(VGA_HS == 1 && row_buffer_done == 2'b11) begin
					next_state = WAIT;
				end
			end
			WAIT: begin
				// If vertical blanking clear currentFrame
				if(VGA_VS == 0) begin
					next_row_sram_address = {1'b0, even_frame, 0};
				end
				
				// If horizontal blanking fetch currentFrame row for row_buffer
				else if(VGA_HS == 0) begin
					next_state = FETCH_ROW;
				end
				
				// If not horizontal blanking, handle software
				else if(Start) begin
					next_rom_address = 8'h00;
					// Read next
					next_state = WAIT_READ;
					SRAM_OE_N = 0;
					next_sram_address = {1'b0, ~even_frame, {imgY, imgX}}; // Frame stored row-major
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
				write_buffer <= Data_from_SRAM;
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
					
					next_rom_address = rom_address + 1;
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
				
				next_sram_address = {1'b0, ~even_frame, {(imgY + rom_address[7:4]), (imgX + rom_address[3:2])}}; // Frame stored row-major
				Data_to_SRAM = write_buffer;
				next_rom_address = rom_address + 1;
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
