module MontgemoryAlgorithm (
    input   i_clk,
    input   i_start,
    input   i_rst,
    input   [255:0] i_N,
    input   [255:0] i_a,
    input   [255:0] i_b,
    output  [255:0] o_m,
    output  o_finished
  );

  // ===== Parameter declaration ===== //
  parameter S_IDLE = 1'd0;
  parameter S_PROC = 1'd1;

  // ===== Port declaration ===== //
  logic state_next, state;
  logic finish_w, finish_r;
  logic [257:0] o_m_w, o_m_r;
  logic [7:0] count_r, count_w;
  logic [257:0] tmp_m_w;
  logic [257:0] tmp_m_w2;

  // ===== output assignment ===== //
  assign o_finished = finish_r;
  assign o_m        = (finish_r==1) ? o_m_r[255:0] : 0;


  // FSM
  always_comb
  begin
    state_next       = state;  
    finish_w         = finish_r;
    
    case (state)  
    S_IDLE:begin
      finish_w       = 0;    
      state_next     = state;    
      
      if(i_start)begin
          state_next = S_PROC;
      end
    end
    S_PROC:begin       
      state_next     = state;
      finish_w       = finish_r; 
         
      if (count_r == 8'd255) begin
          state_next = S_IDLE;
          finish_w   = 1;
      end
     end
   endcase
  end

  // Counter
  always_comb begin 
    count_w = count_r;
    if (state == S_IDLE)    count_w = 0;
    else if(state == S_PROC)   count_w = count_r + 1;  
	  else count_w = count_r;
  end
  // Computing m

  always_comb begin 
    tmp_m_w = o_m_r;
    tmp_m_w2 = o_m_r;
    o_m_w   = o_m_r;
    
    if (state == S_IDLE) begin
      
      tmp_m_w = 0;
      tmp_m_w2 = 0;
      o_m_w   = 0;
    
    end else if (state == S_PROC) begin
      
      // m = m + b
      tmp_m_w = o_m_r;
      if(i_a[count_r]) begin
          tmp_m_w  = o_m_r + i_b;
      end
      
      // m = m/2
      tmp_m_w2 = tmp_m_w >> 1 ;
      if(tmp_m_w[0] == 1)begin
          // m = m + N
          tmp_m_w2 = (tmp_m_w + i_N) >> 1 ;
      end


      o_m_w       = tmp_m_w2;
      if (count_r == 8'd255 && tmp_m_w2 >= i_N) begin
        // m = m - N
        o_m_w     = tmp_m_w2 - i_N ;
      end
      
    end
  end
  // sequential circuits
  always_ff @(posedge i_clk or posedge i_rst)
  begin
    if(i_rst)
    begin
      state <= S_IDLE;
      o_m_r <= 0;
      count_r <= 0;
      finish_r <= 0;
    end
    else
    begin
      state <= state_next;
      o_m_r <= o_m_w;
      count_r <= count_w;
      finish_r <= finish_w;
    end
  end
endmodule