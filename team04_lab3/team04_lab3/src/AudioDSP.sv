module AudDSP(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,		// for 暫停
	input i_stop,		// for 停止
	input [2:0] i_speed,
	input i_fast,
	input i_slow_0,
	input i_slow_1,
	input i_daclrck,    // i_AUD_DACLRCK
	input [15:0]i_sram_data,  // data_play
	input [19:0] i_stop_addr,
	output [15:0]o_dac_data,  // dac_data_r
	output [19:0]o_sram_addr  // addr_play
	//output [2:0] o_state
);
parameter S_IDLE = 2'd0;
parameter S_PLAY = 2'd1;
parameter S_PAUSE = 2'd2;

// enum  { S_IDLE, S_PLAY, S_PAUSE } States; 
logic [1:0] state, state_next;
logic signed [15:0] dac_data_r, dac_data_w;
logic signed [15:0] prev_data_r, prev_data_w;
logic [19:0] sram_addr_r, sram_addr_w;
logic [3:0]counter_r, counter_w;
logic prev_daclrck_r, prev_daclrck_w;
logic [3:0] speed;
 //output
assign o_dac_data = (i_daclrck == 0) ? dac_data_w : 16'bZ;
assign o_sram_addr = sram_addr_w;
assign speed = i_speed + 1;
//assign o_state = state;
// ======= FSM　========== //
always_comb begin 
	
	case (state)
		S_IDLE:begin
			if (i_start) state_next = S_PLAY;
			else 		 state_next = S_IDLE;
		
		end
		S_PLAY: begin
			if (i_stop || (sram_addr_r >= i_stop_addr))		state_next = S_IDLE;
			else if (i_pause) 	state_next = S_PAUSE;
			else 		 	    state_next = S_PLAY;
		end
		S_PAUSE:begin
			if(i_start)     state_next = S_PLAY;
			else if(i_stop) state_next = S_IDLE;
			else			state_next = S_PAUSE;
		end					
		default: state_next = state;
	endcase
	
end
// ====== Combinational circuit =========//
always_comb begin 
	prev_daclrck_w = i_daclrck;
	case(state) 
		S_IDLE:begin
			prev_data_w = 16'b0;
			counter_w = 4'b0;
			if (i_start) begin
				dac_data_w = i_sram_data;
				sram_addr_w = sram_addr_r;
			end
			else 		 begin 
				dac_data_w = 16'dZ;
				sram_addr_w = 20'd0;
			end
		end
		S_PLAY: begin
			// if((i_stop || (sram_addr_r >= i_stop_addr)) && i_slow_1) begin
			// 	dac_data_w 	= prev_data_r;
			// 	sram_addr_w = 20'd0;
			// 	prev_data_w = 16'b0;
			// 	counter_w 	= 4'd0;
			// end
			if (i_stop || (sram_addr_r >= i_stop_addr))       begin
				dac_data_w 	= 16'dZ;
				sram_addr_w = 20'd0;
				prev_data_w = 16'b0;
				counter_w	= 4'd0;
			end
			else if (i_pause) begin
				dac_data_w 	= 16'dZ;
				sram_addr_w = sram_addr_r;
				prev_data_w = prev_data_r;
				counter_w 	= counter_r;
			end
			else begin
				if(i_slow_1)  begin
					// dac_data_w = ;//線性內插
					dac_data_w =(counter_r == 4'd4)? prev_data_r :(prev_data_r * ($signed(speed) - $signed(counter_r)) + $signed(i_sram_data) * $signed(counter_r)) / ($signed(speed));
					if (counter_r > i_speed) begin
						counter_w = (prev_daclrck_r && ~i_daclrck)? 4'd1 : counter_r;
						sram_addr_w = (prev_daclrck_r && ~i_daclrck)? sram_addr_r + 20'd1 : sram_addr_r;
						prev_data_w = (~prev_daclrck_r && i_daclrck)? $signed(i_sram_data) : prev_data_r;  //ready to change channel
					end else begin
						sram_addr_w = sram_addr_r;
						counter_w = (prev_daclrck_r && ~i_daclrck)? (counter_r + 4'd1) : counter_r;
						prev_data_w = prev_data_r;
					end
				end
				else   		  begin
					dac_data_w = i_sram_data;  //i_slow0 i_fast normal
					prev_data_w = 16'b0;
					if(i_fast) begin   		//fast 
						counter_w = 4'd0;
						sram_addr_w = (prev_daclrck_r && ~i_daclrck)? (sram_addr_r + i_speed + 20'd1) : sram_addr_r; //change to left channel
					end else if(i_slow_0)begin  // i_slow0
						if (counter_r > i_speed) begin
							sram_addr_w = (prev_daclrck_r && ~i_daclrck)? sram_addr_r + 20'd1 : sram_addr_r;
							counter_w = (prev_daclrck_r && ~i_daclrck)? 4'd1 : counter_r;
						end else begin
							sram_addr_w = sram_addr_r;
							counter_w = (prev_daclrck_r && ~i_daclrck)? (counter_r + 4'd1) : counter_r;
						end
					end
					else begin // normal
                        sram_addr_w = (prev_daclrck_r && ~i_daclrck)? (sram_addr_r + 20'd1) : sram_addr_r;
                        counter_w = 4'd0;
					end
				end
			end
		end
		S_PAUSE:begin
			dac_data_w = 16'bZ;
			if(i_start)     begin
				counter_w 	= counter_r;
				prev_data_w = prev_data_r;
				sram_addr_w = sram_addr_r;
			end
			else if(i_stop ) begin
				counter_w 	= 4'd0;
				prev_data_w = 16'd0;
				sram_addr_w = 20'd0;
			end
			else			begin // S_PAUSE
				counter_w 	= counter_r;
				prev_data_w = prev_data_r;
				sram_addr_w =sram_addr_r;
			end
		end	
		default :begin
			dac_data_w  = 16'bZ;
			counter_w   = 4'b0;
			prev_data_w = 16'd0;
			sram_addr_w = sram_addr_r;
		end
		endcase
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin 
	if(~i_rst_n)begin
		state <= S_IDLE;
		sram_addr_r <= 20'd0;
		dac_data_r  <= 16'bZ;     //斷路
		prev_data_r <= 16'd0;
		counter_r 	<= 4'b0;
		prev_daclrck_r <= 0;
	end else begin
		state <= state_next;
		sram_addr_r <= sram_addr_w;
		dac_data_r  <= dac_data_w;
		prev_data_r <= prev_data_w;
		counter_r	<= counter_w;
		prev_daclrck_r <= prev_daclrck_w;
	end
	
end
endmodule