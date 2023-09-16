module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0, // Record/Pause
	input i_key_1, // Play/Pause
	input i_key_2, // Stop
	input [2:0] i_speed, // design how user can decide mode on your own
	input i_fast,
	input i_slow_0,
	input i_slow_1,
	output [2:0] o_state,
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	 /*input        i_clk_800k,
	 inout  [7:0] o_LCD_DATA,
	 output       o_LCD_EN,
	 output       o_LCD_RS,
	 output       o_LCD_RW,
	 output       o_LCD_ON,*/
	// output       o_LCD_BLON,

	// LED
	output  [8:0] o_ledg,
	output [17:0] o_ledr,
	output [5:0] o_time
);

//-------------------------------------------------------------------
// design the FSM and state_rs as you like
parameter S_I2C        = 0;
parameter S_IDLE       = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

logic i2c_oen, i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic [2:0] state_r, state_w;
logic init_finished;
logic init_start;
logic record_start;
logic record_pause;
logic record_stop;
logic play_start;
logic play_pause;
logic play_stop;
logic play_en;
logic [8:0] ledg, ledg_nxt;
logic [17:0] ledr, ledr_nxt;
logic [25:0] counter_r, counter_w;
logic [5:0] time_r, time_w;
//-------------------------------------------------------------------
assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;  // 0 is write, 1 is read
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;
assign o_ledg = ledg;
assign o_ledr = ledr;
assign o_state = state_r;
assign init_start	= (state_r == S_I2C);
assign record_start = i_key_0 && ((state_r == S_IDLE) || state_r == S_RECD_PAUSE);
assign record_pause = i_key_0 && (state_r  == S_RECD);
assign record_stop  = i_key_2 && ((state_r == S_RECD) || (state_r == S_RECD_PAUSE));

assign play_en		=  (state_r == S_PLAY);
assign play_start   = i_key_1 && (state_r == S_IDLE || state_r == S_PLAY_PAUSE);
assign play_pause   = i_key_1 && (state_r == S_PLAY);
assign play_stop    = i_key_2 && (state_r == S_PLAY || state_r == S_PLAY_PAUSE);

assign o_time = time_r;
// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(init_start),
	.o_finished(init_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(play_start),
	.i_pause(play_pause),
	.i_stop(play_stop),
	.i_speed(i_speed),
	.i_fast(i_fast),
	.i_slow_0(i_slow_0), // constant interpolation
	.i_slow_1(i_slow_1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_stop_addr(addr_record),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
	//.o_state(o_state)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(play_en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(record_start),
	.i_pause(record_pause),
	.i_stop(record_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);
/*
reg [1:0] state_LCD, state_LCD_next;

parameter S_ADDR = 0;
parameter S_CGRO = 1;
parameter S_NOTH = 2;
parameter S_CLER = 3;
*/
always_comb begin 
	state_w = state_r;
	counter_w = counter_r;
	time_w = time_r;
	
	if(state_r == S_RECD || state_r == S_PLAY) begin
		counter_w = counter_r + 1;
	end
	if(state_r == S_IDLE) begin
		counter_w = 0;
		time_w = 0;
	end
	if(counter_r == 26'd12000000) begin
		counter_w = 0;
		time_w = time_r + 1;
	end
	
	
	case (state_r)
		S_I2C:begin
			if(init_finished) begin
				state_w 	 = S_IDLE;
			end else begin
				state_w		 = state_r;
			end
		end 
		S_IDLE:begin
			if(i_key_0) 	 state_w = S_RECD;		
			else if(i_key_1) state_w = S_PLAY;		
			else			 state_w = state_r;		
		end
		S_RECD:begin
			if(i_key_0) 	 state_w = S_RECD_PAUSE;
			else if(i_key_2) state_w = S_IDLE;
			else			 state_w = state_r;
		end
		S_RECD_PAUSE:begin
			if(i_key_0) 	 state_w = S_RECD;
			else if(i_key_2) state_w = S_IDLE;
			else			 state_w = state_r;
		end
		S_PLAY:begin
			if(i_key_1) 	 state_w = S_PLAY_PAUSE;
			else if(i_key_2) state_w = S_IDLE;
			else			 state_w = state_r;
		end
		S_PLAY_PAUSE:begin
			if(i_key_1) 	 state_w = S_PLAY;
			else if(i_key_2) state_w = S_IDLE;
			else			 state_w = state_r;
		end
		default: begin
			state_w  	 = state_r;
		end
	endcase
	

end
always_ff @( posedge i_AUD_BCLK or negedge i_rst_n ) begin 
	if(!i_rst_n) begin
		state_r <= S_I2C;
		counter_r <= 0;
		time_r <= 0;
	end else begin
		state_r <= state_w;
		counter_r <= counter_w;
		time_r <= time_w;
	end
end


always_comb begin
	// design your control here
	ledg_nxt = ledg;
	ledr_nxt = ledr;
	
	if(state_r == S_I2C) begin
		ledr_nxt = 18'b0;
		ledg_nxt = 9'b111111111;
	end
	if(state_r == S_IDLE) begin
		ledr_nxt = 18'b0;
		ledg_nxt = 9'b111111111;
	end
	else if(state_r == S_RECD) begin
		ledg_nxt = 9'b0;
		case(time_r)
			6'd2: ledr_nxt[2] = 1;
			6'd4: ledr_nxt[3] = 1;
			6'd6: ledr_nxt[4] = 1;
			6'd8: ledr_nxt[5] = 1;
			6'd10: ledr_nxt[6] = 1;
			6'd12: ledr_nxt[7] = 1;
			6'd14: ledr_nxt[8] = 1;
			6'd16: ledr_nxt[9] = 1;
			6'd18: ledr_nxt[10] = 1;
			6'd20: ledr_nxt[11] = 1;
			6'd22: ledr_nxt[12] = 1;
			6'd24: ledr_nxt[13] = 1;
			6'd26: ledr_nxt[14] = 1;
			6'd28: ledr_nxt[15] = 1;
			6'd30: ledr_nxt[16] = 1;
			6'd32: ledr_nxt[17] = 1;
		endcase
	end
	else if(state_r == S_RECD_PAUSE) begin
		ledr_nxt = ledr;
		ledg_nxt = 9'b111111111;
	end
	else if(state_r == S_PLAY) begin
		ledg_nxt = 9'b0;
		case(time_r)
			6'd2: ledr_nxt[2] = 1;
			6'd4: ledr_nxt[3] = 1;
			6'd6: ledr_nxt[4] = 1;
			6'd8: ledr_nxt[5] = 1;
			6'd10: ledr_nxt[6] = 1;
			6'd12: ledr_nxt[7] = 1;
			6'd14: ledr_nxt[8] = 1;
			6'd16: ledr_nxt[9] = 1;
			6'd18: ledr_nxt[10] = 1;
			6'd20: ledr_nxt[11] = 1;
			6'd22: ledr_nxt[12] = 1;
			6'd24: ledr_nxt[13] = 1;
			6'd26: ledr_nxt[14] = 1;
			6'd28: ledr_nxt[15] = 1;
			6'd30: ledr_nxt[16] = 1;
			6'd32: ledr_nxt[17] = 1;
		endcase
	end
	else if(state_r == S_PLAY_PAUSE) begin
		ledr_nxt = ledr;
		ledg_nxt = 9'b111111111;
	end
	
end	

always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		ledg <= 0;
		ledr <= 0;
	end
	else begin
		ledg <= ledg_nxt;
		ledr <= ledr_nxt;
	end
end



endmodule


