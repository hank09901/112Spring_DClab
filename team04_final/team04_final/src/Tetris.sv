// 輸入: 時脈、重製、開始、移動、
// 輸出: VGA、音階(?)、
`include "global.sv"
module Tetris (
    input  clk, rst,
    input  start, gamestart,
    input [7:0] key_data,
    input [1:0] state_whole,
    output [39:0] blocks, grays,
    output [2:0] state_Game,
    output reg [23:0] vga,
    input [3:0] x_number,
    input [4:0] y_number,
    output [3:0] tetris_type, tetris_hold,
    output reg [2:0] attack_lines,
    input [4:0] attacked,
    output [19:0] nexts,
    output [4:0] ctr_elim,
    output lose,
    output [1:0] rotation
    //output music_level,
);
reg [4:0] actual_attacked, actual_attacked_next;
wire [4:0] ctr_garb;
wire [19:0] elimination_enable;
wire [199:0] occupied_bind;
reg  [3:0] garbage_enpty, garbage_enpty_next;
reg  [2:0] lines_next;
wire [2:0] lines;
reg  [3:0] garbage [0:9];
wire [4:0] block0_x, block0_y, block1_x, block1_y, block2_x, block2_y, block3_x, block3_y;
integer i;

always_comb begin
    for (i = 0; i < 10; i = i + 1) begin
        if (i == garbage_enpty) garbage[i] = `NON;
        else                    garbage[i] = `TRASH;
    end
end

GamePlay U1(.clk(clk), .rst(rst), .start(gamestart), .key_data(key_data), .blocks(blocks), .grays(grays), .state_Game(state_Game), .tetris_type(tetris_type), .elimination_enable(elimination_enable),
            .occupied_bind(occupied_bind), .ctr_elim(ctr_elim), .ctr_garb(ctr_garb), .state_whole(state_whole), .tetris_hold(tetris_hold), .nexts(nexts), .lose(lose), .rotation(rotation));


assign lines = elimination_enable[0] + elimination_enable[1] + elimination_enable[2] + elimination_enable[3] + elimination_enable[4] + elimination_enable[5] + elimination_enable[6]  + elimination_enable[7]
             + elimination_enable[8] + elimination_enable[9] + elimination_enable[10] + elimination_enable[11] + elimination_enable[12] + elimination_enable[13] + elimination_enable[14]
             + elimination_enable[15] + elimination_enable[16] + elimination_enable[17] + elimination_enable[18] + elimination_enable[19];  // 會消幾行 // correct at ctr_elim == 20

always_comb begin
    if (state_Game != `ELIM && state_Game != `GARB)    actual_attacked_next = 0;
    else if (ctr_elim == 5'd20 && (attacked > lines)) actual_attacked_next = attacked - lines;
    else if (ctr_elim == 5'd20 && (attacked < lines)) actual_attacked_next = 0;
    else                                              actual_attacked_next = actual_attacked;
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) actual_attacked <= 5'd0;
    else      actual_attacked <= actual_attacked_next;
end

assign attack_lines = ((lines > attacked) && (ctr_elim == 5'd20)) ? lines - attacked : 0;


assign {block0_x, block0_y, block1_x, block1_y, block2_x, block2_y, block3_x, block3_y} = blocks;


//wire [3:0] tetris_type;


// always_comb begin
//     if (ctr_elim == 5'd20) lines_next = elimination_enable[0] + elimination_enable[1] + elimination_enable[2] + elimination_enable[3] + elimination_enable[4] + elimination_enable[5] + elimination_enable[6]  + elimination_enable[7]
//              + elimination_enable[8] + elimination_enable[9] + elimination_enable[10] + elimination_enable[11] + elimination_enable[12] + elimination_enable[13] + elimination_enable[14]
//              + elimination_enable[15] + elimination_enable[16] + elimination_enable[17] + elimination_enable[18] + elimination_enable[19];
//     else lines_next = lines;
// end

// always_ff@(posedge clk or negedge rst) begin
//     if(!rst) lines <= 3'd0;
//     else     lines <= lines_next;
// end



reg [3:0] memory [0:199];
reg [3:0] memory_next [0:199];
wire [23:0] elimination_enable_extend;

assign elimination_enable_extend = {elimination_enable, 4'b0};
reg [4:0] ptr_elim, ptr_elim_next;

always_comb begin
    if (state_Game == `PLAC)    ptr_elim_next = 5'd24;
    else if (elimination_enable_extend[ptr_elim - 1] && elimination_enable_extend[ptr_elim - 2] && elimination_enable_extend[ptr_elim - 3] && elimination_enable_extend[ptr_elim - 4])
        ptr_elim_next = ptr_elim - 3'd5;
    else if (elimination_enable_extend[ptr_elim - 1] && elimination_enable_extend[ptr_elim - 2] && elimination_enable_extend[ptr_elim - 3])
        ptr_elim_next = ptr_elim - 3'd4;
    else if (elimination_enable_extend[ptr_elim - 1] && elimination_enable_extend[ptr_elim - 2])
        ptr_elim_next = ptr_elim - 2'd3;
    else if (elimination_enable_extend[ptr_elim - 1])
        ptr_elim_next = ptr_elim - 2'd2;
    else if (state_Game == `ELIM)
        ptr_elim_next = ptr_elim - 1'd1;
    else
        ptr_elim_next = 5'd25;      
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) ptr_elim <= 5'd25;
    else      ptr_elim <= ptr_elim_next;
end

always_comb begin
    for (i = 0; i < 200; i = i + 1) begin
        if      (state_Game == `PLAC && (i == (block0_x - 2) + block0_y * 10)) memory_next[i] = tetris_type;
        else if (state_Game == `PLAC && (i == (block1_x - 2) + block1_y * 10)) memory_next[i] = tetris_type;
        else if (state_Game == `PLAC && (i == (block2_x - 2) + block2_y * 10)) memory_next[i] = tetris_type;
        else if (state_Game == `PLAC && (i == (block3_x - 2) + block3_y * 10)) memory_next[i] = tetris_type;
        else if (state_Game == `ELIM && (ctr_elim == i / 10))                  memory_next[i] = memory[i - (ctr_elim + 4 - ptr_elim) * 10];
        else if (state_Game == `GARB && (ctr_garb == i / 10) && (i > 199 - actual_attacked * 10))
            memory_next[i] = garbage[i % 10];
        else if (state_Game == `GARB && (ctr_garb == i / 10) && (i <= 199 - actual_attacked * 10))
            memory_next[i] = memory[i + actual_attacked * 10];
        else if (state_whole == `IDLE) memory_next[i] = 0;
        else memory_next[i] = memory[i];
    end
    for (i = 0; i < 200; i = i + 1) begin
        if (!memory[i]) occupied_bind[i] = 0;
        else            occupied_bind[i] = 1;
    end
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) for (i = 0; i < 200; i = i + 1) memory[i] <= 3'd0;
    else      for (i = 0; i < 200; i = i + 1) memory[i] <= memory_next[i];
end

wire [7:0] index;
assign index = x_number - 2'd2 + y_number * 4'd10;

always_comb begin
    case (memory[index])
        `NON:     vga = 24'h000000;
        `Z_BLOCK: vga = `RED;
        `L_BLOCK: vga = `ORANGE;
        `O_BLOCK: vga = `YELLOW;
        `S_BLOCK: vga = `LIME;
        `I_BLOCK: vga = `CYAN;
        `J_BLOCK: vga = `BLUE;
        `T_BLOCK: vga = `PURPLE;
        `GRAY:    vga = `GREY;
        `TRASH:   vga = `TRASHH;
        default:  vga = 24'b0;
    endcase
end

// below is randomizer
reg [7:0] LFSR;
reg init = 1'b1;
//assign LFSR_out = LFSR;
wire feedback = LFSR[7];

always_ff @(posedge clk)
begin
  if (init) begin
    LFSR <= 8'b10111010;
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

reg [3:0] rand_bits = 4'hF;
//wire [2:0] tetris_tmp;
always_ff @(posedge clk) rand_bits <= {rand_bits[2:0], LFSR[3]};
//assign 
always_ff @(posedge clk)
    garbage_enpty <= garbage_enpty_next;

always_comb begin
    case (rand_bits)
        4'd0 : garbage_enpty_next = 4'd0;
        4'd1 : garbage_enpty_next = 4'd1;
        4'd2 : garbage_enpty_next = 4'd2;
        4'd3 : garbage_enpty_next = 4'd3;
        4'd4 : garbage_enpty_next = 4'd4;
        4'd5 : garbage_enpty_next = 4'd5;
        4'd6 : garbage_enpty_next = 4'd6;
        4'd7 : garbage_enpty_next = 4'd7;
        4'd8 : garbage_enpty_next = 4'd8;
        4'd9 : garbage_enpty_next = 4'd9;
        4'd10: garbage_enpty_next = 4'd0;
        4'd11: garbage_enpty_next = 4'd2;
        4'd12: garbage_enpty_next = 4'd4;
        4'd13: garbage_enpty_next = 4'd6;
        4'd14: garbage_enpty_next = 4'd8;
        4'd15: garbage_enpty_next = 4'd9;
        default: garbage_enpty_next = 4'd0;
    endcase
end






endmodule
