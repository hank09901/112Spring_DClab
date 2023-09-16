module CLK25HZ(
	input i_clk,
	input i_rst_n,
	output clk25HZ
);

logic [21:0]counter_w, counter_r;
logic clk_w, clk_r;
assign clk25HZ = clk_r;

always_comb begin
	clk_w = clk_r;
	counter_w = counter_r + 22'd1;
	if(counter_r == 22'd1000000) begin
		clk_w = ~clk_r;
		counter_w = 22'd0;
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		counter_r <= 22'd0;
		clk_r     <= 1'd0;
	end
	else begin
		counter_r <= counter_w;
		clk_r     <= clk_w;
	end
end

endmodule