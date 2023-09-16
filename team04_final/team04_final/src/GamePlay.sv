`include "global.sv"

module GamePlay (
    input clk, rst, start,
    input [1:0] state_whole,
    input [7:0] key_data,
    input [199:0] occupied_bind,
    //input down,
    output [39:0] blocks, grays,
    output [19:0] nexts,
    output [2:0] state_Game,
    output reg [3:0] tetris_type, tetris_hold,
    output [19:0] elimination_enable,
    output [4:0] ctr_elim, ctr_garb,
    output lose,
    output [1:0] rotation
);
wire down, left, right, space, hold, touch, nextpiece, tt, leftspin, rightspin;
reg drop, drop_next, space_delay_next, space_delay, hold_enable_next, hold_enable;
reg [3:0] tetris_type_next, tetris_hold_next;
reg [3:0] movement; // 0: left, 1: right, 2: down, 3: drop, 4: space, 5: leftspin, 6: rightspin, 7: hold, 8: nextpiece, 9: nothing 
reg [29:0] ctr, ctr_next;
reg [3:0] tetris_next [0:4];
reg [3:0] tetris_next_next [0:4];

integer i;
FSM_Game U0 (.clk(clk), .rst(rst), .start(start), .touch(touch), .space(space_delay), .lose(lose), .state(state_Game), .ctr_elim(ctr_elim), .ctr_garb(ctr_garb), .hold(tt));
MoveControl U1 (.clk(clk), .rst(rst), .state_Game(state_Game), .movement(movement), .blocks(blocks), .grays(grays), .touch(touch), .tetris_type(tetris_type), .elimination_enable(elimination_enable),
                .occupied_bind(occupied_bind), .lose(lose), .rotation(rotation));

assign tt = hold_enable & hold;
assign nextpiece = (state_Game == `PREP);
assign left      = ((key_data == 8'h3A)) && (state_whole == `PLAY);
assign right     = ((key_data == 8'h49)) && (state_whole == `PLAY);
assign down      = ((key_data == 8'h41)) && (state_whole == `PLAY);
assign space     = ((key_data == `KEY_SPACE));
assign hold      = ((key_data == `KEY_RSHIFT || key_data == `KEY_LSHIFT));
assign drop      = (state_Game == `DROP) && (space_delay || ctr == 30'd49_999_999 || down);
assign leftspin  = (key_data == 8'h1A);
assign rightspin = (key_data == 8'h21 || key_data == 8'h42 || key_data == 8'h4B);
assign nexts     = {tetris_next[4], tetris_next[3], tetris_next[2], tetris_next[1], tetris_next[0]};

always_comb begin
    // tetris_hold_next
    if (hold_enable && hold)      tetris_hold_next = tetris_type;
    else                          tetris_hold_next = tetris_hold;

    // hold_enable_next
    if (state_whole == `CTWN)     hold_enable_next = 1'b1;
    else if (state_Game == `PLAC) hold_enable_next = 1'b1;
    else if (hold_enable && hold) hold_enable_next = 1'b0;
    else                          hold_enable_next = hold_enable;

    // space_delay_next
    if (state_Game != `DROP && state_Game != `LKDY)      space_delay_next = 1'b0;
    else if (space)               space_delay_next = 1'b1;
    else                          space_delay_next = space_delay;

    // ctr_next
    if (state_Game == `PREP)        ctr_next = 1;
    else if (ctr == 30'd49_999_999) ctr_next = 0;
    else if (state_Game == `DROP)   ctr_next = ctr + 30'b1;
    else                            ctr_next = 0;
end

always_comb begin
    if (state_whole == `ENDS) movement = 4'd9;
    else if (nextpiece)      movement = 4'd8;
    else if (drop)      movement = 4'd3;
    else if (left)      movement = 4'd0;
    else if (right)     movement = 4'd1;
    else if (leftspin)  movement = 4'd5;
    else if (rightspin) movement = 4'd6;
    else                movement = 4'd9;
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) begin
        ctr <= 0;
        hold_enable <= 1'b0;
        space_delay <= 1'b0;
        tetris_hold <= 3'b0;
    end else begin
        ctr <= ctr_next;
        hold_enable <= hold_enable_next;
        space_delay <= space_delay_next;
        tetris_hold <= tetris_hold_next;
    end
end

reg [7:0] LFSR;

reg init = 1'b1;

//assign LFSR_out = LFSR;

wire feedback = LFSR[7];

always_ff @(posedge clk)
begin
  if (init) begin
    LFSR <= 8'b10101010;
    init <= 1'b0;
  end
  else begin
    LFSR[0] <= feedback;
    LFSR[1] <= LFSR[0];
    LFSR[2] <= LFSR[1] ^ feedback;
    LFSR[3] <= LFSR[2] ^ feedback;
    LFSR[4] <= LFSR[3] ^ feedback;
    LFSR[5] <= LFSR[4];
    LFSR[6] <= LFSR[5];
    LFSR[7] <= LFSR[6];
  end
end

reg [2:0] rand_bits;
wire [2:0] tetris_tmp;

assign tetris_tmp = (rand_bits[2:0] == 3'b000) ? `I_BLOCK : rand_bits[2:0];
always_ff @(posedge clk or negedge rst) 
    if (!rst) rand_bits <= 3'b111;
    else      rand_bits <= {rand_bits[1:0], LFSR[3]};
//assign 
always_ff @(posedge clk or negedge rst)
    if (!rst) tetris_type <= 3;
    else      tetris_type <= tetris_type_next;
always_comb begin
    if (state_whole == 2'b01)                     tetris_type_next = tetris_next[0];
    else if (hold_enable && hold && !tetris_hold) tetris_type_next = tetris_next[0];
    else if (hold_enable && hold)                 tetris_type_next = tetris_hold;
    else if (state_Game == `LOSE)                 tetris_type_next = tetris_next[0];
    else                                          tetris_type_next = tetris_type;
end

always_comb begin
    if (state_whole == `IDLE) begin
        tetris_next_next[0] = 4'b0;
        tetris_next_next[1] = 4'b0;
        tetris_next_next[2] = 4'b0;
        tetris_next_next[3] = 4'b0;
        tetris_next_next[4] = 4'b0;
    end else if (state_whole == `CTWN) begin
        tetris_next_next[0] = tetris_next[1];
        tetris_next_next[1] = tetris_next[2];
        tetris_next_next[2] = tetris_next[3];
        tetris_next_next[3] = tetris_next[4];
        tetris_next_next[4] = tetris_tmp;
    end else if (hold_enable && hold && !tetris_hold) begin
        tetris_next_next[0] = tetris_next[1];
        tetris_next_next[1] = tetris_next[2];
        tetris_next_next[2] = tetris_next[3];
        tetris_next_next[3] = tetris_next[4];
        tetris_next_next[4] = tetris_tmp;
    end else if (hold_enable && hold) begin
        tetris_next_next[0] = tetris_next[0];
        tetris_next_next[1] = tetris_next[1];
        tetris_next_next[2] = tetris_next[2];
        tetris_next_next[3] = tetris_next[3];
        tetris_next_next[4] = tetris_next[4];        
    end else if (state_Game == `LOSE) begin
        tetris_next_next[0] = tetris_next[1];
        tetris_next_next[1] = tetris_next[2];
        tetris_next_next[2] = tetris_next[3];
        tetris_next_next[3] = tetris_next[4];
        tetris_next_next[4] = tetris_tmp;
    end else begin
        tetris_next_next[0] = tetris_next[0];
        tetris_next_next[1] = tetris_next[1];
        tetris_next_next[2] = tetris_next[2];
        tetris_next_next[3] = tetris_next[3];
        tetris_next_next[4] = tetris_next[4]; 
    end

end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) for (i = 0; i < 5; i = i + 1) tetris_next[i] <= 4'b0000;
    else      for (i = 0; i < 5; i = i + 1) tetris_next[i] <= tetris_next_next[i];
end
endmodule