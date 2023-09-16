module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	input        capture,
	input        set,
	output [3:0] lucky_num,
	output [3:0] o_random_out,
	output [3:0] previous1,
	output [3:0] previous2,
	output [17:0] LEDR
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first
// ===== States =====

parameter S_IDLE   = 2'b00;
parameter S_RUN    = 2'b01;
parameter S_MIDDLE = 2'b10;
parameter S_FINISH = 2'b11;
parameter IDLE = 1'b0;
parameter SET  = 1'b1;
// ===== Output Buffers =====

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic ready, finish;
logic [3:0] count_r,  count_w;
logic [3:0] period_r, period_w;
logic trigger;
logic [3:0] halted_num_r, halted_num_w;


logic match;
// ===== Output Assignments =====
assign trigger = period_w[0] ^ period_r[0];
assign match      = (halted_num_r == lucky_num);

Random_Generator(.i_clk(i_clk), .i_rst_n(i_rst_n), .trigger(trigger), .number(o_random_out));
LuckyNum lucky(.i_clk(i_clk), .i_rst_n(i_rst_n), .set(set), .lucky_num(lucky_num));
BingoLight bingo(.i_clk(i_clk), .i_rst_n(i_rst_n), .match(match), .light(LEDR));
CaptureKey capturekey(.i_clk(i_clk), .i_rst_n(i_rst_n), .o_random_out(o_random_out), .key(capture), .previous1(previous1), .previous2(previous2));
// ===== Combinational Circuits =====
always_comb begin
	// Default Values
  state_w        = state_r;
  count_w        = (state_r == S_IDLE || state_r == S_FINISH)? count_r : count_r + 4'd1;
  ready          = (count_r == period_r)? 1'b1 : 1'b0;
  finish         = (period_r == 4'd15)? 1'b1 : 1'b0;  
  period_w       = period_r;
  halted_num_w   = halted_num_r;
  
	// FSM
	case(state_r)
  S_IDLE: begin
    if(i_start) begin
      state_w   = S_RUN;
      period_w  = 4'd1;
      count_w   = 4'd0;
    end
  end
  S_RUN: begin
    if(finish)  begin
		state_w = S_FINISH;
		halted_num_w = o_random_out;
	 end
	 else begin
      if(ready) begin
        state_w  = S_MIDDLE;
        count_w  = 4'd0;
        period_w = period_r + 4'd1;
      end
    end
  end
  S_MIDDLE: begin
    if(finish)  begin
		state_w = S_FINISH;
		halted_num_w = o_random_out;
	 end
    else begin
      if(ready) begin
        state_w  = S_RUN;
        count_w  = 4'd0;
        period_w = period_r + 4'd1;
      end
    end
  end
  S_FINISH: begin
    halted_num_w = o_random_out;
	 count_w      = 4'd0;
    if(i_start) begin
      state_w    = S_RUN;
      period_w   = 4'd1;
    end 
  end
	endcase
  
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		state_r        <= S_IDLE;
    count_r        <= 4'd0;
	  period_r       <= 4'd1;
    halted_num_r   <= 4'd0;
	end
	else begin
		state_r        <= state_w;
    count_r        <= count_w;
	  period_r       <= period_w;
    halted_num_r   <= halted_num_w;
	end
end

endmodule
