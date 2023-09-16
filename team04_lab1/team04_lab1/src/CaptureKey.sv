module CaptureKey(
  input i_clk,
  input i_rst_n,
  input [3:0] o_random_out,
  input key,
  output [3:0] previous1,
  output [3:0] previous2
);
  logic state_r, state_w;
  logic [3:0] previous1_r, previous1_w;
  logic [3:0] previous2_r, previous2_w;
  assign previous1 = previous1_r;
  assign previous2 = previous2_r;
  
  always_comb begin
	 previous1_w = previous1_r;
	 previous2_w = previous2_r;
	 state_w = state_r;
	 
	 case(state_r)
	 1'b0: begin
		if(key) begin
			state_w     = 1'b1;
			previous1_w = o_random_out;
			previous2_w = previous1_r;
		end
	 end
	 1'b1: begin
		if(!key) begin
			state_w     = 1'b0;
		end
	 end
	 endcase

	 
  end
  
  always_ff @(posedge i_clk, negedge i_rst_n) begin
	 if(!i_rst_n) begin
		previous1_r <= 4'd0;
		previous2_r <= 4'd0;
		state_r     <= 1'b0;
	 end
	 else begin
		previous1_r <= previous1_w;
		previous2_r <= previous2_w;
		state_r     <= state_w;
	 end
		
  end
endmodule