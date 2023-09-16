module Random_Generator(
  input i_clk,
  input i_rst_n,
  input trigger,
  output [3:0] number
);
  logic [7:0] seed_r, seed_w;
  logic [3:0] number_r, number_w;
  logic [7:0] LFSR_r, LFSR_w;
  assign number = number_r;
  
  always_comb begin
    seed_w = (seed_r == 8'd63)? 8'd0 : seed_r + 8'd1;
    number_w = (trigger)? {LFSR_r[3], LFSR_r[2], LFSR_r[1], LFSR_r[0]} : number_r;
    
    if(trigger) begin
		LFSR_w = seed_r;
	 end
	 else begin
		 LFSR_w[0] = LFSR_r[7] ^ LFSR_r[5] ^ LFSR_r[3] ^ LFSR_r[4];
		 LFSR_w[1] = LFSR_r[0];
		 LFSR_w[2] = LFSR_r[1];
		 LFSR_w[3] = LFSR_r[2];
		 LFSR_w[4] = LFSR_r[3];
		 LFSR_w[5] = LFSR_r[4];
		 LFSR_w[6] = LFSR_r[5];
		 LFSR_w[7] = LFSR_r[6];
    end
  end
  
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if(!i_rst_n) begin
      seed_r <= 8'd0;
      number_r <= 4'd0;
      LFSR_r <= 8'b0;
    end
    else begin
      seed_r <= seed_w;
      number_r <= number_w;
      LFSR_r <= LFSR_w;
    end
  end
endmodule