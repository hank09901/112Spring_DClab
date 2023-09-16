module keyboard (
  input clk,
  input ps2_data,
  input ps2_clk,
  input rst,
  input speed,
  output reg [2:0] move_speed,
  output reg [7:0] led_g	//separated by nibles to express the key pressed
);


parameter idle    = 2'b01;
parameter receive = 2'b10;
parameter ready   = 2'b11;
parameter waiting = 2'b00;

reg [1:0]  state=idle;
reg [15:0] rxtimeout=16'b0000000000000000;
reg [10:0] rxregister=11'b11111111111;
reg [1:0]  datasr=2'b11;
reg [1:0]  clksr=2'b11;
reg [7:0]  rxdata;
reg [24:0] counter;
wire [24:0] wait_time;
reg datafetched;
reg [2:0] move_speed_next;

always_ff@(posedge clk or negedge rst) begin
	if (!rst) move_speed <= 3'd4;
	else	  move_speed <= move_speed_next;
end

always_comb begin
	if (speed) move_speed_next = move_speed + 1'b1;
	else	   move_speed_next = move_speed;
end

assign wait_time = (4000000 - move_speed * 500000);

always_ff @(posedge clk or negedge rst) 
begin 
  if(!rst) begin
	  rxtimeout <= 16'b0;
	  rxregister <= 11'b11111111111;
	  datasr <= 2'b11;
	  clksr <= 2'b11;
	  state <= idle;
	  datafetched <= 0;
	  counter <= 0;
//	  dataready <= 0;
  end
  else begin
	  rxtimeout<=rxtimeout+1;
	  datasr <= {datasr[0],ps2_data};
	  clksr  <= {clksr[0],ps2_clk};

	  

	  if(clksr==2'b10)
		 rxregister<= {datasr[1],rxregister[10:1]};


	  case (state) 
		 idle: 
		 begin
			rxregister <=11'b11111111111;
			led_g <= 8'b11111111;
			rxtimeout  <=16'b0000000000000000;
			datafetched <= 0;
			if(datasr[1]==0 && clksr[1]==1)
			begin
			  state<=receive;
			end   
		 end
		 
		 receive:
		 begin
			led_g <= 8'b11111111;
			if(rxtimeout==50000)
			  state<=idle;
			else if(rxregister[0]==0)
			begin
//			  dataready<=1;
			  //rxdata<=rxregister[8:1];
			  //rxdata <= 8'b11111111;
			  
			  state<=ready;
			  datafetched<=1;
			end
		 end
		 
		 ready: 
		 begin
			if(datafetched==1)
			begin
			  state     <=waiting;
			  //rxdata <= rxregister[8:1];
			  led_g <= rxregister[8:1];
			  datafetched <= 0;
//			  dataready <=0;
			end 
		 end  
		 waiting: begin
		 	led_g <= 0;
			if(counter == wait_time) begin
				counter <= 0;
				state <= idle;
			end
			else begin
				counter <= counter + 1;
				state <= waiting;
			end
		 end
	  endcase
	end
end 


endmodule