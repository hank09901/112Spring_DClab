module AudPlayer(
	input i_rst_n,       
	input i_bclk,			// i_AUD_BCLK 
	input i_daclrck,       // i_AUD_DACLRCK
	input i_en,				// 
	input signed [15:0] i_dac_data,    // dac_data
	output o_aud_dacdat  // o_AUD_DACDAT
);
	localparam IDLE = 0;
	localparam LEFT_WAIT = 1;
	localparam LEFT = 2;
	
	// register
	//logic signed [15:0] i_data_r, i_data_w;
	logic o_data_r, o_data_w;
	logic [5:0] counter_r, counter_w;
	logic [2:0] state_r, state_w;
	
	// wire
	assign o_aud_dacdat = o_data_w;
	
always_comb begin
	o_data_w = o_data_r;
	counter_w = counter_r;
	state_w = state_r;
	
	case(state_r) 
		IDLE: begin
			if(i_en) begin
				if(~i_daclrck) begin
					counter_w = 1;
					o_data_w = i_dac_data[15-counter_r];
					state_w = LEFT;
				end
			end
		end
		LEFT: begin
			o_data_w = i_dac_data[15-counter_r];
			if(counter_r < 15) begin
				counter_w = counter_r + 1;
			end
			else begin
				counter_w = 0;
				state_w = LEFT_WAIT;
			end
		end
		LEFT_WAIT: begin
			if(i_daclrck) begin
				state_w = IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_bclk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		o_data_r <= 0;
		counter_r <= 0;
		state_r <= LEFT_WAIT;
	end
	else begin
		o_data_r <= o_data_w;
		counter_r <= counter_w;
		state_r <= state_w;
	end
end

endmodule