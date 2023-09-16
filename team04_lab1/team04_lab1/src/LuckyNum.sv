module LuckyNum(
  input i_clk,
  input i_rst_n,
  input set,
  output [3:0] lucky_num
);
  parameter IDLE = 1'b0;
  parameter SET  = 1'b1;
  logic [3:0] lucky_num_r, lucky_num_w;
  logic [3:0] counter_r, counter_w;
  logic state_r, state_w;
  
  assign lucky_num = lucky_num_r;
//====================================================
  always_comb begin
    counter_w   = counter_r + 4'd1;
	 if(counter_r == 4'd15) counter_w = 4'd0;
    lucky_num_w = lucky_num_r;
    state_w     = state_r;
	 
	 case(state_r)
	 IDLE: begin
		if(set) begin
			state_w = SET;
			lucky_num_w = counter_r;
		end
	 end
	 SET: begin
		if(!set) state_w = IDLE;
	 end
	 endcase
  end
//=====================================================
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
      lucky_num_r <= 4'd0;
      counter_r   <= 4'd0;
		state_r     <= IDLE;
    end
    else begin
      lucky_num_r <= lucky_num_w;
      counter_r   <= counter_w;
		state_r     <= state_w;
	 end
  end
 endmodule