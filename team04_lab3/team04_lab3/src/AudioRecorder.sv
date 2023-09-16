module AudRecorder(
	input i_rst_n,
	input i_clk,		 // i_AUD_BCLK -> Bitstream clock
	input i_lrc,       // i_AUD_ADCLRCK -> ADC LR clock
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,		 // i_AUD_ADCDAT -> ADC data_r
	output [19:0] o_address,  // addr_record
	output [15:0] o_data      // data_record
);

localparam IDLE = 0;
localparam PAUSE = 1;
localparam LEFT = 2;
localparam LEFT_WAIT = 3;

logic [2:0] state_r, state_w;
logic [5:0] counter_r, counter_w;
logic [19:0] address_r, address_w;
logic [15:0] data_r, data_w;

assign o_address = address_r;
assign o_data = data_r;


always_comb begin
	address_w = address_r;
	data_w = data_r;
	counter_w = counter_r;
	state_w = state_r;
	if(address_r == 20'b1111_1111_1111_1111_1111) begin
		state_w = IDLE;
		counter_w = counter_r;
	end
	else if(state_r == IDLE) begin
		if(i_start) begin
			address_w = 0;
			data_w = 0;
			counter_w = 0;
			state_w = LEFT_WAIT;
		end
	end
	else if(state_r == LEFT_WAIT) begin
		if(i_stop) begin
			address_w = 0;
			state_w = IDLE;
		end
		else if(i_pause) begin
			state_w = PAUSE;
		end
		else if(i_lrc) begin
			state_w = LEFT;
		end
		counter_w = 0;
		data_w = 0;
	end
	else if(state_r == PAUSE) begin
		if(i_stop) begin
			state_w = IDLE;
		end
		else if(i_start) begin
			state_w = LEFT_WAIT;
		end
	end
	else if(state_r == LEFT) begin
		if(i_stop) begin
			state_w = IDLE;
		end
		else if(i_pause) begin
			state_w = PAUSE;
		end
		else if(counter_r < 16) begin
			counter_w = counter_r + 1;
			data_w = (data_r << 1) | i_data;
		end
		else if(~i_lrc) begin
			state_w = LEFT_WAIT;
			address_w = address_r + 1;
		end
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		address_r <= 0;
		data_r <= 0;
		counter_r <= 0;
		state_r <= IDLE;
	end
	else begin
		address_r <= address_w;
		data_r <= data_w;
		counter_r <= counter_w;
		state_r <= state_w;
	end
end
endmodule