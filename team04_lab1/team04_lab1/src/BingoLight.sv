module BingoLight(
  input i_clk,
  input i_rst_n,
  input match,
  output [17:0] light
);

  logic [17:0] light_r, light_w;
  assign light = light_r;
  assign light_w = (match)? ~light_r : 18'b0;
  
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
		light_r <= 18'b0;
	 end
	 else begin
		light_r <= light_w;
	 end
  end
   
endmodule
