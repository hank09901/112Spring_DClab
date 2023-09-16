module Rsa256Core #(
	parameter Datawidth = 256
) (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
// Port Declaration
logic [Datawidth-1:0] t_init, t_w, t_r, m_r, m_w, mt_mont,  tt_mont, o_m_w, o_m_r;
logic [8:0]	count_w, count_r;
logic [1:0] state, state_next;
logic o_mod_finished, o_mont1_finished, o_mont2_finished, o_finished_w, o_finished_r;
logic i_mont_start_w, i_mont_start_r, i_mod_start_w, i_mod_start_r;
// logic i_mont_start2_w, i_mont_start2_r;
// operations for RSA256 decryption
// namely, the Montgomery algorithm
ModuleProduct U1(
    .clk(i_clk),
    .rst(i_rst),
	// .i_start(i_mod_start_w),
    .N(i_n),
    .y(i_a),
    .state(state),
    .state_next(state_next),
    .m(t_init),
    .finished(o_mod_finished)
);
MontgemoryAlgorithm U2(
   	.i_clk(i_clk),
   	.i_start(i_mont_start_r),
    .i_rst(i_rst),
    .i_N(i_n),
    .i_a(m_r),
    .i_b(t_r),
    .o_m(mt_mont),
    .o_finished(o_mont1_finished)
);
MontgemoryAlgorithm U3(
   	.i_clk(i_clk),
   	.i_start(i_mont_start_r),
    .i_rst(i_rst),
    .i_N(i_n),
    .i_a(t_r),
    .i_b(t_r),
    .o_m(tt_mont),
    .o_finished(o_mont2_finished)
);
//Parameter declaration
parameter S_IDLE = 2'd0;
parameter S_PREP = 2'd1;
parameter S_MONT = 2'd2;
parameter S_CALC = 2'd3;

// output assignment 
assign o_finished = o_finished_r;
assign o_a_pow_d  = o_m_r  ;

// FSM
always_comb begin 	
	state_next 				= state;
	i_mont_start_w 			= i_mont_start_r;
	i_mod_start_w 			= i_mod_start_r;
	o_finished_w 			= o_finished_r;
	o_m_w					= o_m_r;
	case (state)
		S_IDLE:begin
			i_mont_start_w 	= 0;
			o_finished_w 	= 0;
			o_m_w			= 0;
			state_next  	= state;
			if(i_start && o_finished == 0)begin
				state_next  = S_PREP;
				i_mod_start_w = 1;
			end
		end
		S_PREP:begin
			state_next 		= state;
			i_mont_start_w 	= i_mont_start_r;
			if(o_mod_finished)begin
				state_next     = S_MONT;
				i_mont_start_w = 1;
				i_mod_start_w  = 0;
			end
		end
		S_MONT:begin
			state_next   	= state;
			// i_mont_start_w  = i_mont_start_r;	
			i_mont_start_w = 0;	
			if(o_mont1_finished & o_mont2_finished)begin
				state_next     = S_CALC;	
				// i_mont_start_w = 0;			
			end
		end
		S_CALC: 
			if (count_r == 9'd256) begin
				state_next = S_IDLE;
				o_m_w	   = m_r;	
				o_finished_w = 1;
				i_mont_start_w = 0;
			end 
			else begin
				state_next = S_MONT;
				i_mont_start_w = 1; 
			end
			// state_next = S_MONT;
			// i_mont_start_w = 1; 
			// if (count_r == 8'd256) begin
			// 	o_finished_w = 1;
			// 	state_next = S_IDLE;
			// 	state_next = S_IDLE;
			// 	o_m_w	   = m_r;	
			// 	// o_finished_w = 1;
			// 	i_mont_start_w = 0;
			// end else if ((count_r == 16'd256)) begin
			// 	o_finished_w = 1;
			// 	state_next = S_IDLE;
			// end 
			

	endcase
end
//Counter
always_comb begin
	count_w = count_r;
	if(state == S_IDLE)begin
		count_w = 0;
	end else if (state == S_MONT && count_r == 9'd256) begin
		count_w = 0;
	end else if(state == S_MONT && (o_mont1_finished & o_mont2_finished))begin
		count_w = count_r + 1;
	end
end

// Computing t
always_comb begin 
	t_w = t_r;
	if((state == S_PREP) & o_mod_finished)begin
		t_w = t_init;
	end else if (state== S_MONT && o_mont2_finished) begin
		t_w = tt_mont;
	end
	
end

// Computing m 
always_comb begin 
	m_w = m_r;
	// if(state == S_IDLE || (state == S_CALC && count_r == 9'd256))begin
	// 	m_w = 1;
	if(state == S_IDLE )begin
		m_w = 1;
	end else if(state == S_MONT && i_d[count_r]  & o_mont1_finished ) begin			
		m_w = mt_mont;				
	end 
	
end

always_ff @( posedge i_clk or posedge i_rst ) begin 
	if(i_rst) begin
		state <= S_IDLE;
		count_r	<= 0;
		t_r		<= 0;
		m_r		<= 1;
		i_mont_start_r <= 0;
		i_mod_start_r <= 0;
		o_finished_r <= 0;
		o_m_r		 <= 0;
	end else begin
		state <= state_next;
		count_r <= count_w;
		t_r		<= t_w;
		m_r		<= m_w;
		i_mont_start_r <= i_mont_start_w;
		i_mod_start_r <= i_mod_start_w;
		o_finished_r <= o_finished_w;
		o_m_r		 <= o_m_w;
	end
end

endmodule
