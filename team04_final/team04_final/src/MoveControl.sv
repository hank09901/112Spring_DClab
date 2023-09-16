`include "global.sv"

module MoveControl (
    input clk, rst,
    input [3:0]  tetris_type,
    input [2:0] state_Game,
    input [3:0] movement,
    input [199:0] occupied_bind,
    output touch,
    //output [2:0] tetris_type,
    output [39:0] blocks,
    output [39:0] grays,
    output reg [19:0] elimination_enable,
    output lose,
    output reg [1:0] rotation
);

parameter I = 3'd0;
parameter J = 3'd1;
parameter L = 3'd2;
parameter O = 3'd3;
parameter S = 3'd4;
parameter T = 3'd5;
parameter Z = 3'd6;
reg  [1:0] rotation_nxt;
//wire [2:0] tetris_type;

reg [13:0] occupied [0:21];
reg [13:0] occupied_next [0:21];
reg [4:0] gray0_x, gray0_y, gray1_x, gray1_y, gray2_x, gray2_y, gray3_x, gray3_y;
reg [4:0] block0_y, block1_y, block2_y, block3_y;
reg [3:0] block0_x, block1_x, block2_x, block3_x;
reg [4:0] gray0_x_next, gray0_y_next, gray1_x_next, gray1_y_next, gray2_x_next, gray2_y_next, gray3_x_next, gray3_y_next;
reg [4:0] block0_y_ntmp, block1_y_ntmp, block2_y_ntmp, block3_y_ntmp;
reg [4:0] block0_y_next, block1_y_next, block2_y_next, block3_y_next;
reg [3:0] block0_x_ntmp, block1_x_ntmp, block2_x_ntmp, block3_x_ntmp;
reg [3:0] block0_x_next, block1_x_next, block2_x_next, block3_x_next;
wire enable;
assign blocks = {1'b0, block0_x, block0_y, 1'b0, block1_x, block1_y, 1'b0, block2_x, block2_y, 1'b0, block3_x, block3_y};
assign grays  = {gray0_x,  gray0_y,  gray1_x,  gray1_y,  gray2_x,  gray2_y,  gray3_x,  gray3_y};
integer i, j, k;

//assign tetris_type = 3;
///////////// WALL KICK Declaration////////////////
logic direction;
logic [2:0] test;
logic is_occupy_1;
logic is_occupy_2;
logic is_occupy_3;
logic is_occupy_4;
logic is_occupy_5;
logic [4:0] tmpblock0_y;
logic [4:0] tmpblock1_y;
logic [4:0] tmpblock2_y;
logic [4:0] tmpblock0_y_o2;
logic [4:0] tmpblock1_y_o2;
logic [4:0] tmpblock2_y_o2;
logic [4:0] tmpblock0_y_o3;
logic [4:0] tmpblock1_y_o3;
logic [4:0] tmpblock2_y_o3;
logic [4:0] tmpblock0_y_o4;
logic [4:0] tmpblock1_y_o4;
logic [4:0] tmpblock2_y_o4;
logic [4:0] tmpblock0_y_o5;
logic [4:0] tmpblock1_y_o5;
logic [4:0] tmpblock2_y_o5;
logic [3:0] tmpblock0_x;
logic [3:0] tmpblock1_x;
logic [3:0] tmpblock2_x;
logic [3:0] tmpblock0_x_o2;
logic [3:0] tmpblock1_x_o2;
logic [3:0] tmpblock2_x_o2;
logic [3:0] tmpblock0_x_o3;
logic [3:0] tmpblock1_x_o3;
logic [3:0] tmpblock2_x_o3;
logic [3:0] tmpblock0_x_o4;
logic [3:0] tmpblock1_x_o4;
logic [3:0] tmpblock2_x_o4;
logic [3:0] tmpblock0_x_o5;
logic [3:0] tmpblock1_x_o5;
logic [3:0] tmpblock2_x_o5;
reg  [8:0] ctr;
wire [8:0] ctr_next;

assign lose = (occupied[0][5] | occupied[0][6] | occupied[0][7] | occupied[0][8]);

///////////////// WALL KICK Declaration///////////////
always_comb begin
    for (k = 0; k < 20; k = k + 1)
        elimination_enable[k] = (occupied[k] == 14'b11_1111_1111_1111);
end

always_comb begin
    for (i = 0; i < 20; i = i + 1) begin
        for (j = 2; j < 12; j = j + 1) begin
            occupied[i][j] = occupied_bind[i * 10 + j - 2];
        end
        occupied[i][0] = 1'b1;
        occupied[i][1] = 1'b1;
        occupied[i][12] = 1'b1;
        occupied[i][13] = 1'b1;        
    end
    occupied[20] = 14'b11_1111_1111_1111;
    occupied[21] = 14'b11_1111_1111_1111;    
end



assign touch = occupied[block0_y + 1][block0_x] | occupied[block1_y + 1][block1_x] | occupied[block2_y + 1][block2_x] | occupied[block3_y + 1][block3_x];
assign ctr_next = ctr + 1'b1;

always_comb begin 
    // is_occupy_2 = 1'd1;
    // is_occupy_3 = 1'd1;
    // is_occupy_4 = 1'd1;
    // is_occupy_5 = 1'd1;
    
    if(!is_occupy_1) test = 3'd0;
    else if(!is_occupy_2) test = 3'd1;
    else if(!is_occupy_3) test = 3'd2;
    else if(!is_occupy_4) test = 3'd3;
    else if(!is_occupy_5) test = 3'd4;
    else test = 3'd0;
end
// shadow
always_comb begin
    if (state_Game == `PLAC || state_Game == `LKDY || state_Game == `ELIM) begin
        gray0_x_next = 5'd0;
        gray0_y_next = 5'd0;
        gray1_x_next = 5'd0;
        gray1_y_next = 5'd0;
        gray2_x_next = 5'd0;
        gray2_y_next = 5'd0;
        gray3_x_next = 5'd0;
        gray3_y_next = 5'd0;    
    end else if (movement != 9 || state_Game == `PREP) begin
        gray0_x_next = block0_x_next;
        gray0_y_next = block0_y_next;
        gray1_x_next = block1_x_next;
        gray1_y_next = block1_y_next;
        gray2_x_next = block2_x_next;
        gray2_y_next = block2_y_next;
        gray3_x_next = block3_x_next;
        gray3_y_next = block3_y_next;
    end else if (occupied[gray0_y + 1][gray0_x] | occupied[gray1_y + 1][gray1_x] | occupied[gray2_y + 1][gray2_x] | occupied[gray3_y + 1][gray3_x]) begin
        gray0_x_next = gray0_x;
        gray0_y_next = gray0_y;
        gray1_x_next = gray1_x;
        gray1_y_next = gray1_y;
        gray2_x_next = gray2_x;
        gray2_y_next = gray2_y;
        gray3_x_next = gray3_x;
        gray3_y_next = gray3_y;
    end else begin
        gray0_x_next = gray0_x;
        gray0_y_next = gray0_y + 1;
        gray1_x_next = gray1_x;
        gray1_y_next = gray1_y + 1;
        gray2_x_next = gray2_x;
        gray2_y_next = gray2_y + 1;
        gray3_x_next = gray3_x;
        gray3_y_next = gray3_y + 1;
    end
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) begin
        gray0_x <= 5'd0;
        gray0_y <= 5'd0;
        gray1_x <= 5'd0;
        gray1_y <= 5'd0;
        gray2_x <= 5'd0;
        gray2_y <= 5'd0;
        gray3_x <= 5'd0;
        gray3_y <= 5'd0;
        ctr     <= 9'b0;
    end else begin
        gray0_x <= gray0_x_next;
        gray0_y <= gray0_y_next;
        gray1_x <= gray1_x_next;
        gray1_y <= gray1_y_next;
        gray2_x <= gray2_x_next;
        gray2_y <= gray2_y_next;
        gray3_x <= gray3_x_next;
        gray3_y <= gray3_y_next;
        ctr     <= ctr_next;
    end
end
  
reg samerotation ;
// assign samerotation = (block0_x_ntmp == block0_x) && (block1_x_ntmp == block1_x) && (block2_x_ntmp == block2_x) && (block3_x_ntmp == block3_x) &&
//                     (block0_y_ntmp == block0_y) && (block1_y_ntmp == block1_y) && (block2_y_ntmp == block2_y) && (block3_y_ntmp == block3_y);
always @(*) begin
    rotation_nxt = 2'd0;
    case (rotation)
        2'd0:begin
            if(samerotation)begin
                rotation_nxt = 2'd0;
            end
            else if(movement == 4'd6)begin
                rotation_nxt = 2'd1;
            end else if (movement == 4'd5)begin
                rotation_nxt = 2'd3;
            end else begin
                rotation_nxt = 2'd0;
            end
        end
        2'd1:begin
            if(samerotation)begin
                rotation_nxt = 2'd1;
            end
            else if(movement == 4'd6)begin
                rotation_nxt = 2'd2;
            end else if (movement == 4'd5)begin
                rotation_nxt = 2'd0;
            end else begin
                rotation_nxt = 2'd1;
            end
        end
        2'd2:begin
            if(samerotation)begin
                rotation_nxt = 2'd2;
            end
            else if(movement == 4'd6)begin
                rotation_nxt = 2'd3;                
            end else if (movement == 4'd5)begin
                rotation_nxt = 2'd1;
            end else begin
                rotation_nxt = 2'd2;
            end
        end 
        2'd3:begin
            if(samerotation)begin
                rotation_nxt = 2'd3;
            end
            else if(movement == 4'd6)begin
                rotation_nxt = 2'd0;
            end else if (movement == 4'd5)begin
                rotation_nxt = 2'd2;
            end else begin
                rotation_nxt = 2'd3;
            end
        end
        
    endcase
    if(movement==4'd8) rotation_nxt = 2'd0; 
end

always_ff @( posedge clk or negedge rst ) begin 
    if(!rst) rotation <= 2'd0;
    else    rotation <= rotation_nxt;
end
// movement: 0: left, 1: right, 3: drop, down, space, 5: leftspin, 6: rightspin, 7: hold, 8: nextpiece, 9: nothing
always_comb begin
    block0_x_ntmp = block0_x;
    block1_x_ntmp = block1_x;
    block2_x_ntmp = block2_x;
    block3_x_ntmp = block3_x;
    block0_y_ntmp = block0_y;
    block1_y_ntmp = block1_y;
    block2_y_ntmp = block2_y;
    block3_y_ntmp = block3_y;    
    samerotation = 1'd0;
    case (tetris_type)
        `I_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                      case(rotation)
                    2'd0:begin
                
                        //counter clock-wise 0->3
                        case(test)
                        3'd0:begin
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+1'd1;
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+2'd2;
                        end
                        3'd1:begin            
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y-1'd1;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block3_y;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block3_y+1'd1;
                            block0_x_ntmp = block3_x;block0_y_ntmp = block3_y+2'd2;
                        end
                        3'd2:begin
                            block3_x_ntmp = block0_x;block3_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block0_y;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block0_y+1'd1;
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y+2'd2;
                        end
                        3'd3:begin
                            block3_x_ntmp = block0_x;block3_y_ntmp = block0_y-2'd3;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block0_y-2'd2;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block0_y-1'd1;
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                        end
                        3'd4:begin                   
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block3_y+1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block3_y+2'd2;
                            block0_x_ntmp = block3_x;block0_y_ntmp = block3_y+2'd3;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
            
                    2'd1:
                    begin //counter clock-wise 1->0
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x-2'd2;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp   = block1_y;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block1_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block1_x;block0_y_ntmp   = block1_y;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x+2'd3;block3_y_ntmp = block1_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block1_x-2'd3;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x-2'd2;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp   = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp   = block0_y;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block0_y;
                            block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block0_y;
                            block3_x_ntmp = block1_x+2'd3;block3_y_ntmp = block0_y;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block1_x-2'd3;block0_y_ntmp = block3_y;
                            block1_x_ntmp = block1_x-2'd2;block1_y_ntmp = block3_y;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block3_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp   = block3_y;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
            
                    2'd2:begin
                    //counter clock-wise 2->1
                            case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-2'd2;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y-1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block3_x;block0_y_ntmp = block3_y-2'd2;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block3_y-1'd1;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y+1'd1;
                            end
                            3'd2:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y-2'd2;
                                block1_x_ntmp = block0_x;block1_y_ntmp = block0_y-1'd1;
                                block2_x_ntmp = block0_x;block2_y_ntmp = block0_y;
                                block3_x_ntmp = block0_x;block3_y_ntmp = block0_y+1'd1;
                            end
                            3'd3:begin
                                block0_x_ntmp = block3_x;block0_y_ntmp = block3_y-2'd3;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block3_y-2'd2;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block3_y-1'd1;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block0_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block0_x;block2_y_ntmp = block0_y+1'd1;
                                block3_x_ntmp = block0_x;block3_y_ntmp = block0_y+2'd2;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase
                        end 
            
                    2'd3:begin
                        //counter clock-wise 3->2
                            case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x+2'd2;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block1_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x+2'd3;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x+2'd2;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x;block3_y_ntmp   = block1_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp   = block1_y;
                                block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x-2'd2;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x-2'd3;block3_y_ntmp = block1_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x+2'd3;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block1_x+2'd2;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block1_x;block3_y_ntmp   = block3_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x;block0_y_ntmp   = block0_y;
                                block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block1_x-2'd2;block2_y_ntmp = block0_y;
                                block3_x_ntmp = block1_x-2'd3;block3_y_ntmp = block0_y;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase
                        end
           
                endcase  
                    end
                4'd6:
                    begin
                      case(rotation)
                        2'd0:begin
                        // clockwise 0->1                 
                            case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-1'd1;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+1'd1;
                                block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+2'd2;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block0_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block0_x;block2_y_ntmp = block0_y+1'd1;
                                block3_x_ntmp = block0_x;block3_y_ntmp = block0_y+2'd2;
                            end
                            3'd2:begin
                                block0_x_ntmp = block3_x;block0_y_ntmp = block3_y-1'd1;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block3_y+1'd1;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y+2'd2;
                            end
                            3'd3:begin
                                block0_x_ntmp = block3_x;block0_y_ntmp = block3_y-2'd3;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block3_y-2'd2;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block3_y-1'd1;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block0_x;block1_y_ntmp = block0_y+1'd1;
                                block2_x_ntmp = block0_x;block2_y_ntmp = block0_y+2'd2;
                                block3_x_ntmp = block0_x;block3_y_ntmp = block0_y+2'd3;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase
                
            end
                    2'd1:begin
                        // clockwise 1->2                 
                            case(test)
                            3'd0:begin
                                block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block2_y;
                                block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block2_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block2_y;
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block3_x_ntmp = block2_x-2'd3;block3_y_ntmp = block2_y;
                                block2_x_ntmp = block2_x-2'd2;block2_y_ntmp = block2_y;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block2_y;
                                block0_x_ntmp = block2_x;block0_y_ntmp   = block2_y;
                            end
                            3'd2:begin
                                block3_x_ntmp = block2_x;block3_y_ntmp   = block2_y;
                                block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block2_y;
                                block1_x_ntmp = block2_x+2'd2;block1_y_ntmp = block2_y;
                                block0_x_ntmp = block2_x+2'd3;block0_y_ntmp = block2_y;
                            end
                            3'd3:begin
                                block3_x_ntmp = block2_x-2'd3;block3_y_ntmp = block0_y;
                                block2_x_ntmp = block2_x-2'd2;block2_y_ntmp = block0_y;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block0_y;
                                block0_x_ntmp = block2_x;block0_y_ntmp   = block0_y;
                            end
                            3'd4:begin                   
                                block3_x_ntmp = block2_x;block3_y_ntmp   = block3_y;
                                block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x+2'd2;block1_y_ntmp = block3_y;
                                block0_x_ntmp = block2_x+2'd3;block0_y_ntmp = block3_y;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase
                
                        end
                        2'd2:begin
                        // clockwise 2->3                 
                                case(test)
                                3'd0:begin
                                    block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                                    block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y-1'd1;
                                    block3_x_ntmp = block2_x;block3_y_ntmp = block2_y-2'd2;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y+1'd1;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block0_y;
                                    block2_x_ntmp = block0_x;block2_y_ntmp = block0_y-1'd1;
                                    block3_x_ntmp = block0_x;block3_y_ntmp = block0_y-2'd2;
                                end
                        
                                3'd2:begin
                                    block0_x_ntmp = block3_x;block0_y_ntmp = block3_y+1'd1;
                                    block1_x_ntmp = block3_x;block1_y_ntmp = block3_y;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block3_y-1'd1;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y-2'd2;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block0_y-1'd1;
                                    block2_x_ntmp = block0_x;block2_y_ntmp = block0_y-2'd2;
                                    block3_x_ntmp = block0_x;block3_y_ntmp = block0_y-2'd3;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block3_x;block0_y_ntmp = block3_y+2'd2;
                                    block1_x_ntmp = block3_x;block1_y_ntmp = block3_y+1'd1;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block3_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y-1'd1;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                                endcase
                
                        end
                        2'd3:begin
                            // clockwise 3->0                 
                                case(test)
                                3'd0:begin
                                    block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block2_y;
                                    block1_x_ntmp = block2_x;block1_y_ntmp   = block2_y;
                                    block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x+2'd2;block3_y_ntmp = block2_y;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block2_x-2'd3;block0_y_ntmp = block2_y;
                                    block1_x_ntmp = block2_x-2'd2;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x;block3_y_ntmp   = block2_y;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block2_x;block0_y_ntmp   = block2_y;
                                    block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x+2'd2;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x+2'd3;block3_y_ntmp = block2_y;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block2_x-2'd3;block0_y_ntmp = block3_y;
                                    block1_x_ntmp = block2_x-2'd2;block1_y_ntmp = block3_y;
                                    block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block3_y;
                                    block3_x_ntmp = block2_x;block3_y_ntmp   = block3_y;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block2_x;block0_y_ntmp   = block0_y;
                                    block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block0_y;
                                    block2_x_ntmp = block2_x+2'd2;block2_y_ntmp = block0_y;
                                    block3_x_ntmp = block2_x+2'd3;block3_y_ntmp = block0_y;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                                endcase
                
                        end
                    endcase  
                end
                4'd8:
                    begin
                        block0_x_ntmp = 5;
                        block1_x_ntmp = 6;
                        block2_x_ntmp = 7;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 0;
                        block1_y_ntmp = 0;
                        block2_y_ntmp = 0;
                        block3_y_ntmp = 0;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase
        `J_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                      case (rotation)
                        2'd0:begin
                        // 0->3
                            case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp = block2_y+1'd1;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+1'd1;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x;block3_y_ntmp = block2_y-1'd1;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block2_y+1'd1;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block2_y-1'd1;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block2_y-1'd1;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block2_y-2'd2;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp = block2_y+2'd3;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+2'd3;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                                block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+2'd3;
                                block1_x_ntmp = block3_x;block1_y_ntmp = block2_y+2'd3;
                                block2_x_ntmp = block3_x;block2_y_ntmp = block2_y+2'd2;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block2_y+1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase
                        end
                
                        2'd1:begin
                        // 1->0
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block2_y;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x;block0_y_ntmp   = block1_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block2_y;
                                block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x+2'd2;block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x;block0_y_ntmp   = block2_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block3_y;
                                block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block2_x+2'd2;block3_y_ntmp = block3_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block1_y-2'd2;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block1_y-1'd1;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block1_y-1'd1;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block1_y-1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-2'd2;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block1_y-1'd1;
                                block2_x_ntmp = block2_x+1'd1;block2_y_ntmp   = block1_y-1'd1;
                                block3_x_ntmp = block2_x+2'd2;block3_y_ntmp = block1_y-1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                        end              
                        2'd2:begin
                           // 2->1
                                case(test)
                                3'd0:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block2_y-1'd1;
                                    block1_x_ntmp = block2_x;block1_y_ntmp = block2_y-1'd1;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-1'd1;
                                    block1_x_ntmp = block3_x;block1_y_ntmp = block2_y-1'd1;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block2_y+1'd1;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-2'd2;
                                    block1_x_ntmp = block3_x;block1_y_ntmp = block2_y-2'd2;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block2_y-1'd1;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block2_y;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block2_y+1'd1;
                                    block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+1'd1;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                                    block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+2'd3;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                                    block1_x_ntmp = block3_x;block1_y_ntmp = block2_y+1'd1;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block2_y+2'd2;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block2_y+2'd3;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                                endcase
                            end                
                        2'd3:begin
                            // 3->2
                                case(test)
                                    3'd0:begin
                                        block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block2_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp   = block2_y;
                                        block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block2_y;
                                    end
                                    3'd1:begin            
                                        block0_x_ntmp = block2_x;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                                        block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block2_y;
                                        block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block2_y;
                                    end
                                    3'd2:begin
                                        block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block1_y;
                                        block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block1_y;
                                    end
                                    3'd3:begin
                                        block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                        block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block3_y-1'd1;
                                        block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y-1'd1;
                                        block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block3_y-1'd1;
                                    end
                                    3'd4:begin                   
                                        block0_x_ntmp = block2_x;block0_y_ntmp = block3_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block3_y-1'd1;
                                        block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block3_y-1'd1;
                                        block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block3_y-1'd1;
                                    end
                                    default:begin
                                        block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                        block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                         samerotation = 1'd1;
                                    end
                                endcase
                            end 
                      endcase  
                    end
                4'd6:
                    begin
                      case (rotation)
                        2'd0:begin
                    // clockwise 0->1                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-2'd2;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y-2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+2'd3;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y+1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y+2'd3;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase                    
                    end
                    2'd1:begin
                         // clockwise 1->2                 
                            case(test)
                                3'd0:begin
                                    block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                    block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp   = block2_y;
                                    block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block2_y;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block2_x+2'd2;block0_y_ntmp = block3_y;
                                    block1_x_ntmp = block2_x+2'd2;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x;  block3_y_ntmp = block2_y;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block2_x+2'd2;block0_y_ntmp = block3_y+1'd1;
                                    block1_x_ntmp = block2_x+2'd2;block1_y_ntmp = block3_y;
                                    block2_x_ntmp = block2_x+1'd1;block2_y_ntmp = block3_y;
                                    block3_x_ntmp = block2_x;  block3_y_ntmp = block3_y;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block1_y;
                                    block1_x_ntmp = block2_x+1'd1;block1_y_ntmp = block1_y-1'd1;
                                    block2_x_ntmp = block2_x;block2_y_ntmp   = block1_y-1'd1;
                                    block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block1_y-1'd1;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block2_x+2'd2;block0_y_ntmp = block1_y;
                                    block1_x_ntmp = block2_x+2'd2;block1_y_ntmp = block1_y-1'd1;
                                    block2_x_ntmp = block2_x+1'd1;block2_y_ntmp   = block1_y-1'd1;
                                    block3_x_ntmp = block2_x;block3_y_ntmp = block1_y-1'd1;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                            endcase         
                    end
                    2'd2:begin
                        // clockwise 2->3                 
                            case(test)
                            3'd0:begin
                                block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+1'd1;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+1'd1;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x;block3_y_ntmp = block2_y-1'd1;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y+1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block2_y-1'd1;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y-1'd1;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block2_y-2'd2;
                            end
                            3'd3:begin
                                block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+2'd3;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+2'd3;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                                block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+2'd3;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y+2'd3;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y+2'd2;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block2_y+1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                            endcase

                    end
                    2'd3:begin
                        // clockwise 3->0                 
                            case(test)
                                3'd0:begin
                                    block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y;
                                    block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp   = block2_y;
                                    block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block2_y;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block2_x-2'd2;block0_y_ntmp = block3_y;
                                    block1_x_ntmp = block2_x-2'd2;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block2_x;  block3_y_ntmp = block2_y;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block2_x-2'd2;block0_y_ntmp = block2_y;
                                    block1_x_ntmp = block2_x-2'd2;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x-1'd1;block2_y_ntmp = block1_y;
                                    block3_x_ntmp = block2_x;  block3_y_ntmp = block1_y;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y-2'd2;
                                    block1_x_ntmp = block2_x-1'd1;block1_y_ntmp = block3_y-1'd1;
                                    block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y-1'd1;
                                    block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block3_y-1'd1;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block2_x-2'd2;block0_y_ntmp = block3_y-2'd2;
                                    block1_x_ntmp = block2_x-2'd2;block1_y_ntmp = block3_y-1'd1;
                                    block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block3_y-1'd1;
                                    block3_x_ntmp = block2_x;block3_y_ntmp = block3_y-1'd1;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                            endcase                        
                    end 
                  endcase  
                end
                4'd8:
                    begin
                        block0_x_ntmp = 6;
                        block1_x_ntmp = 6;
                        block2_x_ntmp = 7;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 0;
                        block1_y_ntmp = 1;
                        block2_y_ntmp = 1;
                        block3_y_ntmp = 1;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase        
        `L_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                      case (rotation)
                        2'd0:begin
                    // 0->3
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y-2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-2'd2;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
               
                2'd1:begin
                    // 1->0
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x+2'd2;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block1_x+2'd2;block3_y_ntmp = block0_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp   = block2_y;
                                block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x+2'd2;block3_y_ntmp = block1_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp   = block0_y-1'd1;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y-2'd2;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block1_x+1'd1;block1_y_ntmp   = block0_y-1'd1;
                                block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x+2'd2;block3_y_ntmp = block0_y-2'd2;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                
                2'd2:begin
                    // 2->1
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-2'd2;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block3_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block3_y+1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block3_y+2'd2;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block3_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block3_y;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block3_y+1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block3_y+2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block3_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                
                2'd3:begin
                     // 3->2
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x-1'd1;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x-2'd2;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block1_x-2'd2;block3_y_ntmp = block0_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block1_x-2'd2;block2_y_ntmp   = block0_y;
                                block3_x_ntmp = block1_x-2'd2;block3_y_ntmp = block0_y+1'd1;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block2_y-1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y-1'd1;
                                block2_x_ntmp = block1_x-1'd1;block2_y_ntmp   = block2_y-1'd1;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x;block0_y_ntmp = block2_y-1'd1;
                                block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block2_y-1'd1;
                                block2_x_ntmp = block1_x-2'd2;block2_y_ntmp   = block2_y-1'd1;
                                block3_x_ntmp = block1_x-2'd2;block3_y_ntmp = block2_y;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end 
           
                      endcase  
                    end
                4'd6:
                    begin
                      case (rotation)
                        2'd0:begin
                    // clockwise 0->1                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y-2'd2;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+2'd3;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+2'd3;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y+2'd3;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+2'd3;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                    
              
                2'd1:begin
                    // clockwise 1->2                 
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;  block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x+2'd2;  block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x+1'd1;  block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x;    block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x;    block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x+2'd2;  block0_y_ntmp = block2_y;
                                block1_x_ntmp = block1_x+1'd1;  block1_y_ntmp = block2_y;
                                block2_x_ntmp = block1_x;    block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x;    block3_y_ntmp = block2_y+1'd1;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block1_x;  block1_y_ntmp = block0_y-1'd1;
                                block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x+2'd2;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block1_x+1'd1;  block1_y_ntmp = block0_y-1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block0_y;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                    
                2'd2:begin
                    // clockwise 2->3                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y-2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-2'd2;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block3_y-2'd2;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block3_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block3_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block3_y;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block0_x;block0_y_ntmp = block3_y-2'd2;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block3_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block3_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block3_y;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                    
                2'd3:begin
                    // clockwise 3->0                 
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;  block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x-2'd2;  block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x-1'd1;  block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x;    block2_y_ntmp = block1_y;
                                block3_x_ntmp = block1_x;    block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x-2'd2;  block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x-1'd1;  block1_y_ntmp = block0_y;
                                block2_x_ntmp = block1_x;    block2_y_ntmp = block0_y;
                                block3_x_ntmp = block1_x;    block3_y_ntmp = block1_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block2_y-1'd1;
                                block1_x_ntmp = block1_x;  block1_y_ntmp = block2_y-1'd1;
                                block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block2_y-1'd1;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y-2'd2;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x-2'd2;block0_y_ntmp = block2_y-1'd1;
                                block1_x_ntmp = block1_x-1'd1;  block1_y_ntmp = block2_y-1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y-1'd1;
                                block3_x_ntmp = block1_x;block3_y_ntmp = block2_y-2'd2;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                end
                      endcase
                    end    
                4'd8:
                    begin
                        block0_x_ntmp = 6;
                        block1_x_ntmp = 7;
                        block2_x_ntmp = 8;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 1;
                        block1_y_ntmp = 1;
                        block2_y_ntmp = 1;
                        block3_y_ntmp = 0;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase        
        `O_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                        block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                        block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                        block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                    end
                4'd6:
                    begin
                        block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                        block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                        block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                    end
                4'd8:
                    begin
                        block0_x_ntmp = 7;
                        block1_x_ntmp = 7;
                        block2_x_ntmp = 8;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 0;
                        block1_y_ntmp = 1;
                        block2_y_ntmp = 1;
                        block3_y_ntmp = 0;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase        
        `S_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                      case (rotation)
                        2'd0:begin
                    // 0->3
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block3_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block3_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                
                2'd1:begin
                    // 1->0
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp   = block1_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp   = block0_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block0_y;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block3_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block1_y;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block1_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp   = block0_y-1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp   = block0_y-2'd2;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y-2'd2;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block0_y-1'd1;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block0_y-1'd1;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block0_y-2'd2;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block0_y-2'd2;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                
                2'd2:begin
                    // 2->1
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block3_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block1_y-2'd2;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block2_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y+1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block2_y+1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block2_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block2_y+1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                
                2'd3:begin
                     // 3->2
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block0_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block1_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block0_y;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block1_y;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block1_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block3_y-1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block3_y-1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block3_y;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y-1'd1;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block3_y-1'd1;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block3_y;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                    endcase
                end
                4'd6:
                    begin
                      case (rotation)
                        2'd0:begin
                   // clockwise 0->1                 
                            case(test)
                                3'd0:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block1_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block1_y+1'd1;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block1_y-1'd1;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+1'd1;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block2_y-1'd1;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block2_y;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block2_y+1'd1;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block1_y+2'd2;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block1_y+2'd3;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block1_y+2'd2;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+2'd2;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+2'd3;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                            endcase
                        end    
                        2'd1:begin
                             // clockwise 1->2                 
                                case(test)
                                    3'd0:begin
                                        block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block1_x;block2_y_ntmp = block3_y;
                                        block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block3_y;
                                    end
                                    3'd1:begin            
                                        block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block3_y;
                                        block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block3_y;
                                    end
                                    3'd2:begin
                                        block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block3_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block3_y+1'd1;
                                        block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block3_y+1'd1;
                                    end
                                    3'd3:begin
                                        block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block0_y-1'd1;
                                        block1_x_ntmp = block1_x;block1_y_ntmp = block0_y-1'd1;
                                        block2_x_ntmp = block1_x;block2_y_ntmp = block0_y;
                                        block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y;
                                    end
                                    3'd4:begin                   
                                        block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block0_y-1'd1;
                                        block1_x_ntmp = block2_x;block1_y_ntmp = block0_y-1'd1;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block0_y;
                                        block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block0_y;
                                    end
                                    default:begin
                                        block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                        block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                         samerotation = 1'd1;
                                    end
                                endcase
                            end
                        2'd2:begin
                             // clockwise 2->3                 
                                case(test)
                                3'd0:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block1_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block1_y-1'd1;
                                end
                                3'd1:begin            
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                                end
                                3'd2:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block1_y;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block1_y-1'd1;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-2'd2;
                                end
                                3'd3:begin
                                    block0_x_ntmp = block1_x;block0_y_ntmp = block2_y+2'd2;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block2_y+1'd1;
                                    block2_x_ntmp = block3_x;block2_y_ntmp = block2_y+1'd1;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block2_y;
                                end
                                3'd4:begin                   
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block2_y+2'd2;
                                    block1_x_ntmp = block0_x;block1_y_ntmp = block2_y+1'd1;
                                    block2_x_ntmp = block1_x;block2_y_ntmp = block2_y+1'd1;
                                    block3_x_ntmp = block1_x;block3_y_ntmp = block2_y;
                                end
                                default:begin
                                    block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                    block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                    block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                    block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                     samerotation = 1'd1;
                                end
                                endcase
                            end      
                        2'd3:begin
                            // clockwise 3->0                 
                                case(test)
                                    3'd0:begin
                                        block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block1_x;block1_y_ntmp   = block1_y;
                                        block2_x_ntmp = block1_x;block2_y_ntmp   = block3_y;
                                        block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block3_y;
                                    end
                                    3'd1:begin            
                                        block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block1_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp   = block1_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y;
                                        block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block3_y;
                                    end
                                    3'd2:begin
                                        block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block0_y;
                                        block1_x_ntmp = block2_x;block1_y_ntmp   = block0_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp   = block1_y;
                                        block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block1_y;
                                    end
                                    3'd3:begin
                                        block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block3_y-1'd1;
                                        block1_x_ntmp = block1_x;block1_y_ntmp   = block3_y-1'd1;
                                        block2_x_ntmp = block1_x;block2_y_ntmp   = block3_y-2'd2;
                                        block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block3_y-2'd2;
                                    end
                                    3'd4:begin                   
                                        block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y-1'd1;
                                        block1_x_ntmp = block2_x;block1_y_ntmp   = block3_y-1'd1;
                                        block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y-2'd2;
                                        block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block3_y-2'd2;
                                    end
                                    default:begin
                                        block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                        block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                        block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                        block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                         samerotation = 1'd1;
                                    end
                                endcase
                            end
                    endcase
                end
                4'd8:
                    begin
                        block0_x_ntmp = 6;
                        block1_x_ntmp = 7;
                        block2_x_ntmp = 7;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 1;
                        block1_y_ntmp = 1;
                        block2_y_ntmp = 0;
                        block3_y_ntmp = 0;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase        
        `T_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                begin
                    case (rotation)
                    2'd0:begin
                    // 0->3
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y-2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase 
                    end 
               
                    2'd1:begin
                    // 1->0
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block0_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block2_y;
                            block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block2_y;
                            block1_x_ntmp = block1_x+2'd2;block1_y_ntmp = block2_y;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block0_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block0_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block0_y-2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block1_x;block0_y_ntmp = block0_y-1'd1;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block1_x+2'd2;block2_y_ntmp = block0_y-1'd1;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y-2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
               
                2'd2:begin
                    // 2->1
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-2'd2;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+2'd3;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+2'd3;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase 
                    end 
                
                2'd3:begin
                   //3->2
                    case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block0_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x-2'd2;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block0_y;
                            block2_x_ntmp = block1_x-2'd2;block2_y_ntmp = block0_y;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block1_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block1_x-2'd2;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                   end 
                
                      endcase  
                    end
                4'd6:
                    begin
                      case (rotation)
                        2'd0:begin
                    // clockwise 0->1                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y-1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block0_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block0_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y-2'd2;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block0_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block3_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+2'd3;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block0_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block0_y+2'd3;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block0_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                        end  
                2'd1:begin
                    // clockwise 1->2                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block1_x+2'd2;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block1_x+2'd2;block0_y_ntmp = block2_y;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block0_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block1_x-1'd1;block2_y_ntmp = block0_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block0_y;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block1_x+2'd2;block0_y_ntmp = block0_y-1'd1;
                            block1_x_ntmp = block1_x+1'd1;block1_y_ntmp = block0_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block0_y-1'd1;
                            block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                end 
                2'd2:begin
                    // clockwise 2->3                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y-2'd2;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y+1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block1_y+2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                end
                2'd3:begin
                   // clockwise 3->0                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block1_x-2'd2;block0_y_ntmp = block1_y;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y;
                        end
                        3'd2:begin
                            block0_x_ntmp = block1_x-2'd2;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block0_y;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block0_y;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block1_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block1_x+1'd1;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block1_x;block3_y_ntmp = block2_y-2'd2;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block1_x-2'd2;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block1_x-1'd1;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block1_x;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y-2'd2;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                   
                     end 
                
                      endcase  
                    end
                4'd8:
                    begin
                        block0_x_ntmp = 6;
                        block1_x_ntmp = 7;
                        block2_x_ntmp = 8;
                        block3_x_ntmp = 7;
                        block0_y_ntmp = 1;
                        block1_y_ntmp = 1;
                        block2_y_ntmp = 1;
                        block3_y_ntmp = 0;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase        
        `Z_BLOCK:
            case (movement)
                4'd0:
                    begin
                        block0_x_ntmp = block0_x - 1'd1;
                        block1_x_ntmp = block1_x - 1'd1;
                        block2_x_ntmp = block2_x - 1'd1;
                        block3_x_ntmp = block3_x - 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd1:
                    begin
                        block0_x_ntmp = block0_x + 1'd1;
                        block1_x_ntmp = block1_x + 1'd1;
                        block2_x_ntmp = block2_x + 1'd1;
                        block3_x_ntmp = block3_x + 1'd1;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;
                    end
                4'd3:
                    begin
                        block0_y_ntmp = block0_y + 1'd1;
                        block1_y_ntmp = block1_y + 1'd1;
                        block2_y_ntmp = block2_y + 1'd1;
                        block3_y_ntmp = block3_y + 1'd1;
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                    end
                4'd5:
                    begin
                      case (rotation)
                        2'd0:begin
                     // 0->3
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y-1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block2_y-1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block1_y-1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block2_y+2'd3;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block2_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+2'd3;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+2'd2;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                
                2'd1:begin
                     // 1->0
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block2_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block3_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block0_y-2'd2;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block0_y-2'd2;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block0_y-1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block0_y-2'd2;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block0_y-2'd2;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y-1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
               
                2'd2:begin
                     // 2->1
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-2'd2;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block2_y;
                        end
                        3'd3:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block0_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+2'd3;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block3_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block1_y+2'd3;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                
                2'd3:begin
                     // 3->2
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block0_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block2_y;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block2_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp   = block0_y;
                                block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block2_y;
                                block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block2_x;block0_y_ntmp = block0_y+1'd1;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp   = block0_y+1'd1;
                                block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block0_y;
                                block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block0_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block3_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y-1'd1;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block3_y-1'd1;
                            end
                            3'd4:begin                   
                                 block0_x_ntmp = block2_x;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x-1'd1;block1_y_ntmp   = block3_y;
                                block2_x_ntmp = block2_x-1'd1;block2_y_ntmp   = block3_y-1'd1;
                                block3_x_ntmp = block2_x-2'd2;block3_y_ntmp = block3_y-1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                
                      endcase  
                    end
                4'd6:
                    begin
                      case (rotation)
                        2'd0:begin
                    // clockwise 0->1                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block2_y+1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y-1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd3:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block2_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y+2'd3;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block2_y+2'd2;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block2_y+2'd3;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                    
                2'd1:begin
                    // clockwise 1->2                 
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block3_y+1'd1;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block3_y+1'd1;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block3_y;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block3_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block2_x+1'd1;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block2_x-1'd1;block3_y_ntmp = block0_y-1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x+1'd1;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block0_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block0_y-1'd1;
                                block3_x_ntmp = block1_x-1'd1;block3_y_ntmp = block0_y-1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                    
                2'd2:begin
                    // clockwise 2->3                 
                        case(test)
                        3'd0:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block2_y-1'd1;
                        end
                        3'd1:begin            
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y+1'd1;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block2_y-1'd1;
                        end
                        3'd2:begin
                            block0_x_ntmp = block2_x;block0_y_ntmp = block2_y;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block2_y-1'd1;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block2_y-1'd1;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block2_y-2'd2;
                        end
                        3'd3:begin
                            block0_x_ntmp = block3_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block3_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block2_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        3'd4:begin                   
                            block0_x_ntmp = block2_x;block0_y_ntmp = block1_y+2'd3;
                            block1_x_ntmp = block2_x;block1_y_ntmp = block1_y+2'd2;
                            block2_x_ntmp = block0_x;block2_y_ntmp = block1_y+2'd2;
                            block3_x_ntmp = block0_x;block3_y_ntmp = block1_y+1'd1;
                        end
                        default:begin
                            block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                            block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                            block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                            block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                             samerotation = 1'd1;
                        end
                        endcase
                    end
                    
                2'd3:begin
                    // clockwise 3->0                 
                        case(test)
                            3'd0:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block2_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd1:begin            
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block3_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block3_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block2_y;
                            end
                            3'd2:begin
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block2_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block2_y;
                                block2_x_ntmp = block1_x;block2_y_ntmp = block0_y;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block0_y;
                            end
                            3'd3:begin
                                block0_x_ntmp = block2_x-1'd1;block0_y_ntmp = block3_y-2'd2;
                                block1_x_ntmp = block2_x;block1_y_ntmp   = block3_y-2'd2;
                                block2_x_ntmp = block2_x;block2_y_ntmp   = block3_y-1'd1;
                                block3_x_ntmp = block2_x+1'd1;block3_y_ntmp = block3_y-1'd1;
                            end
                            3'd4:begin                   
                                block0_x_ntmp = block1_x-1'd1;block0_y_ntmp = block3_y-2'd2;
                                block1_x_ntmp = block1_x;block1_y_ntmp   = block3_y-2'd2;
                                block2_x_ntmp = block1_x;block2_y_ntmp   = block3_y-1'd1;
                                block3_x_ntmp = block1_x+1'd1;block3_y_ntmp = block3_y-1'd1;
                            end
                            default:begin
                                block0_x_ntmp = block0_x;block0_y_ntmp = block0_y;
                                block1_x_ntmp = block1_x;block1_y_ntmp = block1_y;
                                block2_x_ntmp = block2_x;block2_y_ntmp = block2_y;
                                block3_x_ntmp = block3_x;block3_y_ntmp = block3_y;
                                 samerotation = 1'd1;
                            end
                        endcase
                    end
                    
                      endcase  
                    end
                4'd8:
                    begin
                        block0_x_ntmp = 6;
                        block1_x_ntmp = 7;
                        block2_x_ntmp = 7;
                        block3_x_ntmp = 8;
                        block0_y_ntmp = 0;
                        block1_y_ntmp = 0;
                        block2_y_ntmp = 1;
                        block3_y_ntmp = 1;
                    end
                default:
                    begin
                        block0_x_ntmp = block0_x;
                        block1_x_ntmp = block1_x;
                        block2_x_ntmp = block2_x;
                        block3_x_ntmp = block3_x;
                        block0_y_ntmp = block0_y;
                        block1_y_ntmp = block1_y;
                        block2_y_ntmp = block2_y;
                        block3_y_ntmp = block3_y;                    
                    end
            endcase
        default: begin
            block0_x_ntmp = block0_x;
            block1_x_ntmp = block1_x;
            block2_x_ntmp = block2_x;
            block3_x_ntmp = block3_x;
            block0_y_ntmp = block0_y;
            block1_y_ntmp = block1_y;
            block2_y_ntmp = block2_y;
            block3_y_ntmp = block3_y;
             samerotation = 1'd1;
        end        
    endcase


end




assign enable = !occupied[block0_y_ntmp][block0_x_ntmp] & !occupied[block1_y_ntmp][block1_x_ntmp] & !occupied[block2_y_ntmp][block2_x_ntmp] & !occupied[block3_y_ntmp][block3_x_ntmp];
always_comb begin
    if (enable) begin
        block0_x_next = block0_x_ntmp;
        block0_y_next = block0_y_ntmp;
        block1_x_next = block1_x_ntmp;
        block1_y_next = block1_y_ntmp;
        block2_x_next = block2_x_ntmp;
        block2_y_next = block2_y_ntmp;
        block3_x_next = block3_x_ntmp;
        block3_y_next = block3_y_ntmp;
    end else begin
        block0_x_next = block0_x;
        block0_y_next = block0_y;
        block1_x_next = block1_x;
        block1_y_next = block1_y;
        block2_x_next = block2_x;
        block2_y_next = block2_y;
        block3_x_next = block3_x;
        block3_y_next = block3_y;
    end
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) begin
        block0_x <= 4'd0;
        block0_y <= 4'd0;
        block1_x <= 4'd0;
        block1_y <= 4'd0;
        block2_x <= 4'd0;
        block2_y <= 4'd0;
        block3_x <= 4'd0;
        block3_y <= 4'd0;    
    end else begin
        block0_x <= block0_x_next;
        block0_y <= block0_y_next;
        block1_x <= block1_x_next;
        block1_y <= block1_y_next;
        block2_x <= block2_x_next;
        block2_y <= block2_y_next;
        block3_x <= block3_x_next;
        block3_y <= block3_y_next;
    end
end




    









assign direction = (movement == 4'd6);

always@(*)
begin
    tmpblock0_y = 0;
    tmpblock1_y = 0;
    tmpblock2_y = 0;
    tmpblock0_x= 0;
    tmpblock1_x= 0;
    tmpblock2_x= 0;
     case (tetris_type)
        I: begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 
                    // I 0->1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;
                    tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock0_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block2_x] , occupied[tmpblock2_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block1_y-1'd1;
                    tmpblock1_y = block1_y+1'd1;
                    tmpblock2_y = block1_y+2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock2_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    // I 0->1
                    tmpblock0_x = block2_x-2'd2;
                    tmpblock1_x = block2_x-1'd1;
                    tmpblock2_x = block2_x+1'd1;
                    if(| {occupied[block2_y][tmpblock0_x],  occupied[block2_y][tmpblock1_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x = block1_x-2'd2;
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end

            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    
                    tmpblock0_y = block2_y+1'd1;
                    tmpblock1_y = block2_y-1'd1;
                    tmpblock2_y = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block2_x] , occupied[tmpblock2_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y = block1_y-2'd2;
                    tmpblock1_y = block1_y-1'd1;
                    tmpblock2_y = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock2_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x = block2_x+2'd2;
                    tmpblock1_x = block2_x-1'd1;
                    tmpblock2_x = block2_x+1'd1;
                    if(| {occupied[block2_y][tmpblock0_x],  occupied[block2_y][tmpblock1_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x = block1_x+2'd2;
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            endcase
        end
        J:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block2_x] , occupied[tmpblock0_y][block3_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;               
                    if(| {occupied[tmpblock1_y][block1_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block2_x] , occupied[tmpblock0_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 1
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    if(| {occupied[block3_y][tmpblock1_x],  occupied[block2_y][tmpblock1_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block2_y][tmpblock0_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end   
            2'd2:begin
                if(direction)begin // clockwise 2->3                1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;
                    if(| {occupied[tmpblock1_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block3_x] , occupied[tmpblock0_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;               
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block2_y][block2_x], occupied[tmpblock0_y][block2_x] , occupied[tmpblock1_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end 
            2'd3:begin
                if(direction)begin // clockwise 3->0                 1
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    if(| {occupied[block3_y][tmpblock0_x],  occupied[block2_y][tmpblock0_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block2_y][tmpblock1_x], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end         
            endcase
        end
        L:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 1
                    tmpblock0_y = block1_y-1'd1;
                    tmpblock1_y = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock1_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block1_y-1'd1;
                    tmpblock1_y = block1_y+1'd1;              
                    if(| {occupied[tmpblock0_y][block0_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock0_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 1
                    tmpblock0_x = block1_x-1'd1;
                    tmpblock1_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][tmpblock0_x], occupied[block1_y][block1_x] , occupied[block2_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock0_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][tmpblock0_x], occupied[block1_y][block1_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end   
            2'd2:begin
                if(direction)begin // clockwise 2->3                 1
                    tmpblock1_y = block1_y-1'd1;
                    tmpblock0_y = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock1_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y = block1_y-1'd1;
                    tmpblock0_y = block1_y+1'd1;              
                    if(| {occupied[tmpblock0_y][block0_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[tmpblock0_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end 
            2'd3:begin
                if(direction)begin // clockwise 3->0                 1
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock0_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][tmpblock0_x], occupied[block1_y][block1_x] , occupied[block2_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x = block1_x-1'd1;
                    tmpblock1_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][tmpblock0_x], occupied[block1_y][block1_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end         
            endcase
        end
        O:begin
           is_occupy_1 = 0;
        end
        S:begin
           case (rotation)
               2'd0:begin
                if(direction)begin // clockwise 0->1                 
                   
                    tmpblock1_y = block1_y-1'd1;
                    tmpblock0_y = block1_y+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock1_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock0_y][block3_x] , occupied[block1_y][block3_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block1_y+1'd1;
                    tmpblock1_y = block1_y-1'd1;
                    // tmpblock2_y = block1_y-2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block0_x] , occupied[block1_y][block0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock0_x = block1_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][block1_x], occupied[block3_y][block1_x] , occupied[block3_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock0_x = block1_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][block1_x], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    // I 0->1
                    tmpblock1_y = block1_y-1'd1;
                    tmpblock0_y = block1_y+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block3_x] , occupied[block1_y][block3_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y = block1_y+1'd1;
                    tmpblock0_y = block1_y-1'd1;
                    // tmpblock2_y = block1_y-2'd2;
                    if(| {occupied[tmpblock1_y][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock0_y][block1_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd3:begin
                if(direction)begin // clockwise 3->0                 
                    
                    tmpblock1_x = block1_x-1'd1;
                    tmpblock0_x = block1_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block3_y][tmpblock0_x],  occupied[block3_y][block1_x], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x = block1_x-1'd1;
                    tmpblock1_x = block1_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block1_y][tmpblock1_x],  occupied[block1_y][block1_x], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
            endcase 
        end
        T:begin
          case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 
        
                    tmpblock0_y = block1_y-1'd1;
                    tmpblock1_y = block1_y+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[block2_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block1_y+1'd1;
                    tmpblock1_y = block1_y-1'd1;
                    // tmpblock2_y = block1_y-2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y][block1_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                2
                    tmpblock0_x = block1_x-1'd1;
                    tmpblock1_x = block1_x+1'd1;
                    // tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block2_y][block1_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x = block1_x-1'd1;
                    tmpblock1_x = block1_x+1'd1;
                    // tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block1_y][block1_x] , occupied[block0_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end

            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    
                    tmpblock0_y = block1_y+1'd1;
                    tmpblock1_y = block1_y-1'd1;
                    // tmpblock2_y = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[block1_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y = block1_y-1'd1;
                    tmpblock1_y = block1_y+1'd1;
                    // tmpblock2_y = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y][block1_x] , occupied[block1_y][block0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x = block1_x+1'd1;
                    tmpblock1_x = block1_x-1'd1;
                    // tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block2_y][block1_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                     tmpblock0_x = block1_x+1'd1;
                    tmpblock1_x = block1_x-1'd1;
                    // tmpblock2_x = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x],  occupied[block1_y][tmpblock1_x], occupied[block1_y][block1_x] , occupied[block0_y][block1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
            end
            endcase  
        end
        Z:begin
            case (rotation)
               2'd0:begin
                if(direction)begin // clockwise 0->1                 
                    // I 0->1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock1_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock0_y][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y = block2_y+1'd1;
                    tmpblock1_y = block2_y-1'd1;
                    // tmpblock2_y = block1_y-2'd2;
                    if(| {occupied[tmpblock0_y][block0_x],  occupied[block2_y][block0_x], occupied[tmpblock1_y][block2_x] , occupied[block2_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block2_y][tmpblock0_x],  occupied[block2_y][block2_x], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x = block2_x-1'd1;
                    tmpblock1_x = block2_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block2_y][tmpblock1_x],  occupied[block2_y][block2_x], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    // I 0->1
                    tmpblock0_y = block2_y-1'd1;
                    tmpblock1_y = block2_y+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[tmpblock0_y][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y = block2_y+1'd1;
                    tmpblock1_y = block2_y-1'd1;
                    // tmpblock2_y = block1_y-2'd2;
                    if(| {occupied[tmpblock1_y][block0_x],  occupied[block2_y][block0_x], occupied[tmpblock0_y][block2_x] , occupied[block2_y][block2_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
               2'd3:begin
                if(direction)begin // clockwise 3->0                 
                    
                    tmpblock1_x = block2_x-1'd1;
                    tmpblock0_x = block2_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block2_y][tmpblock0_x],  occupied[block2_y][block2_x], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock1_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock1_x = block2_x-1'd1;
                    tmpblock0_x = block2_x+1'd1;
                    // tmpblock2_y = block2_y+2'd2;
                    if(| {occupied[block2_y][tmpblock1_x],  occupied[block2_y][block2_x], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock0_x]}   )
                        is_occupy_1 = 1;
                    else
                        is_occupy_1 = 0;
                end
               end
            endcase
        end
        default: begin
           is_occupy_1 = 1;
        end
    endcase   
end

// is_occupblock1_y
always@(*)
begin
    tmpblock0_y_o2 = 0;
    tmpblock1_y_o2 = 0;
    tmpblock2_y_o2 = 0;
    tmpblock0_x_o2= 0;
    tmpblock1_x_o2= 0;
    tmpblock2_x_o2= 0;
     case (tetris_type)
        I: begin
            case(rotation)
            2'd0:begin
                
                if(direction)begin // clockwise 0->1                 
                    // I 0->1
                    tmpblock0_y_o2 = block0_y-1'd1;
                    tmpblock1_y_o2 = block0_y+1'd1;
                    tmpblock2_y_o2 = block0_y+2'd2;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[tmpblock2_y_o2][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o2 = block3_y-1'd1;
                    tmpblock1_y_o2 = block3_y+1'd1;
                    tmpblock2_y_o2 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o2][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o2][block3_x] , occupied[tmpblock2_y_o2][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o2 = block2_x-1'd1;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    tmpblock2_x_o2 = block2_x-2'd3;
                    if(| {occupied[block2_y][tmpblock0_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][tmpblock2_x_o2] , occupied[block2_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x+2'd2;
                    tmpblock2_x_o2 = block1_x+2'd3;
                    if(| {occupied[block1_y][block1_x],  occupied[block1_y][tmpblock0_x_o2], occupied[block1_y][tmpblock1_x_o2] , occupied[block1_y][tmpblock2_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end

            end
            2'd2:begin
               if(direction)begin // clockwise 2->3                 
                    // I 0->1
                    tmpblock0_y_o2 = block0_y+1'd1;
                    tmpblock1_y_o2 = block0_y-1'd1;
                    tmpblock2_y_o2 = block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[tmpblock2_y_o2][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o2 = block3_y-2'd2;
                    tmpblock1_y_o2 = block3_y-1'd1;
                    tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o2][block3_x] , occupied[tmpblock2_y_o2][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                    tmpblock0_x_o2 = block2_x-1'd1;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    tmpblock2_x_o2 = block2_x-2'd3;
                    if(| {occupied[block2_y][tmpblock0_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock2_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x+2'd2;
                    tmpblock2_x_o2 = block1_x+2'd3;
                    if(| {occupied[block1_y][tmpblock0_x_o2],  occupied[block1_y][tmpblock1_x_o2], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock2_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase
        end
        J:begin
            case(rotation)
            2'd0:begin
                
                if(direction)begin // clockwise 0->1                 
                    // I 0->1
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block2_y][block1_x], occupied[tmpblock1_y_o2][block1_x] , occupied[tmpblock0_y_o2][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                  
                    if(| {occupied[tmpblock0_y_o2][block3_x],  occupied[block2_y][block3_x], occupied[tmpblock1_y_o2][block3_x] , occupied[tmpblock1_y_o2][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd1:begin
                
                if(direction)begin // clockwise 1->2                
                    
                    tmpblock0_x_o2 = block2_x+1'd1;
                    tmpblock1_x_o2 = block2_x+2'd2;
                    if(| {occupied[block3_y][tmpblock1_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][tmpblock0_x_o2] , occupied[block2_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o2 = block2_x+1'd1;
                    tmpblock1_x_o2 = block2_x+2'd2;
                    if(| {occupied[block2_y][tmpblock0_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][block2_x] , occupied[block1_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd2:begin
                
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                    if(| {occupied[tmpblock1_y_o2][block2_x],  occupied[block2_y][block1_x], occupied[tmpblock0_y_o2][block1_x] , occupied[tmpblock1_y_o2][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                  
                    if(| {occupied[tmpblock1_y_o2][block3_x],  occupied[block2_y][block3_x], occupied[tmpblock0_y_o2][block3_x] , occupied[tmpblock0_y_o2][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd3:begin
                
                if(direction)begin // clockwise 3->0                
                    
                    tmpblock0_x_o2 = block2_x-1'd1;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    if(| {occupied[block3_y][tmpblock1_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][tmpblock0_x_o2] , occupied[block2_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o2 = block2_x-1'd1;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    if(| {occupied[block2_y][tmpblock0_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][block2_x] , occupied[block1_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase
        end
        L:begin
            case(rotation)
            2'd0:begin
                
                if(direction)begin // clockwise 0->1                 
                    tmpblock1_y_o2 = block1_y-1'd1;
                    tmpblock0_y_o2 = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[tmpblock0_y_o2][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock1_y_o2 = block1_y-1'd1;
                    tmpblock0_y_o2 = block1_y+1'd1;
                  
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o2][block1_x] , occupied[tmpblock1_y_o2][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd1:begin
                
                if(direction)begin // clockwise 1->2                
                    
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x+2'd2;
                    if(| {occupied[block1_y][tmpblock1_x_o2],  occupied[block2_y][block1_x], occupied[block1_y][tmpblock0_x_o2] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x+2'd2;
                    if(| {occupied[block1_y][tmpblock1_x_o2],  occupied[block1_y][block1_x], occupied[block1_y][tmpblock0_x_o2] , occupied[block0_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd2:begin
                
                if(direction)begin // clockwise 2->3                 
                    tmpblock1_y_o2 = block1_y-1'd1;
                    tmpblock0_y_o2 = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[tmpblock1_y_o2][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o2 = block1_y-1'd1;
                    tmpblock1_y_o2 = block1_y+1'd1;
                  
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o2][block1_x] , occupied[tmpblock1_y_o2][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd3:begin
                
                if(direction)begin // clockwise 3->0                
                    
                    tmpblock0_x_o2 = block1_x-1'd1;
                    tmpblock1_x_o2 = block1_x-2'd2;
                    if(| {occupied[block1_y][tmpblock1_x_o2],  occupied[block2_y][block1_x], occupied[block1_y][tmpblock0_x_o2] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o2 = block1_x-1'd1;
                    tmpblock1_x_o2 = block1_x-2'd2;
                    if(| {occupied[block1_y][tmpblock1_x_o2],  occupied[block1_y][block1_x], occupied[block1_y][tmpblock0_x_o2] , occupied[block0_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase 
        end
        O:begin
           is_occupy_2 = 1;
        end
        S:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 
                    tmpblock0_y_o2 = block1_y-1'd1;
                    tmpblock1_y_o2 = block1_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock1_y_o2][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock0_y_o2][block0_x] , occupied[block1_y][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o2 = block1_y-1'd1;
                    tmpblock1_y_o2 = block1_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y_o2][block3_x] , occupied[block1_y][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    // I 0->1
                    // tmpblock0_x_o2 = block2_x-2'd3;
                    tmpblock1_x_o2 = block2_x-1'd1;
                    tmpblock0_x_o2 = block2_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x_o2],  occupied[block1_y][block2_x], occupied[block3_y][tmpblock1_x_o2] , occupied[block3_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock1_x_o2 = block2_x+1'd1;
                    tmpblock0_x_o2 = block2_x-1'd1;
                    // tmpblock2_x_o2 = block1_x+2'd3;
                    if(| {occupied[block1_y][block2_x],  occupied[block1_y][tmpblock0_x_o2], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end

            end
            2'd2:begin
               if(direction)begin // clockwise 2->3                 
                    tmpblock1_y_o2 = block1_y-1'd1;
                    tmpblock0_y_o2 = block1_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock1_y_o2][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock0_y_o2][block0_x] , occupied[block1_y][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y_o2 = block1_y-1'd1;
                    tmpblock0_y_o2 = block1_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block1_x],  occupied[block1_y][block1_x], occupied[tmpblock1_y_o2][block3_x] , occupied[block1_y][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock1_x_o2 = block2_x+1'd1;
                    tmpblock0_x_o2 = block2_x-1'd1;
                    
                    if(| {occupied[block1_y][tmpblock0_x_o2],  occupied[block1_y][block2_x], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock1_x_o2 = block2_x+1'd1;
                    tmpblock0_x_o2 = block2_x-1'd1;
                    
                    if(| {occupied[block0_y][tmpblock0_x_o2],  occupied[block0_y][block2_x], occupied[block1_y][block2_x] , occupied[block1_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase
        end
        T:begin
            case(rotation)
            2'd0:begin
                // Is_occupy occupblock1_y(occupied,block0_x, block0_y+5'd1, block0_x, block0_y, block0_x, block0_y-5'd1, block0_x, block0_y-5'd2, is_occupy_2 );
                if(direction)begin // clockwise 0->1                 
                    // I 0->1
                    tmpblock0_y_o2 = block0_y-1'd1;
                    tmpblock1_y_o2 = block0_y+1'd1;
                    // tmpblock2_y_o2 = block0_y+2'd2;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o2 = block1_y+1'd1;
                    tmpblock1_y_o2 = block1_y-1'd1;
                    // tmpblock2_y_o2 = block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o2][block2_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    // I 0->1
                    tmpblock0_x_o2 = block2_x-2'd3;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    tmpblock2_x_o2 = block2_x-1'd1;
                    if(| {occupied[block2_y][tmpblock0_x_o2],  occupied[block2_y][tmpblock1_x_o2], occupied[block2_y][tmpblock2_x_o2] , occupied[block2_y][block2_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x+2'd2;
                   // tmpblock2_x_o2 = block1_x+2'd3;
                    if(| {occupied[block1_y][block1_x],  occupied[block1_y][tmpblock0_x_o2], occupied[block1_y][tmpblock1_x_o2] , occupied[block0_y][tmpblock0_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end

            end
            2'd2:begin
               if(direction)begin // clockwise 2->3                 
                    // I 0->1
                    tmpblock0_y_o2 = block0_y+1'd1;
                    tmpblock1_y_o2 = block0_y-1'd1;
                    // tmpblock2_y_o2 = block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o2][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y_o2][block0_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o2 = block1_y-1'd1;
                    tmpblock1_y_o2 = block1_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o2][block2_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    // tmpblock0_x_o2 = block2_x-2'd3;
                    tmpblock0_x_o2 = block1_x-2'd2;
                    tmpblock1_x_o2 = block1_x-1'd1;
                    if(| {occupied[block1_y][tmpblock0_x_o2],  occupied[block1_y][tmpblock1_x_o2], occupied[block1_y][block1_x] , occupied[block2_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o2 = block1_x+2'd3;
                    tmpblock1_x_o2 = block1_x+2'd2;
                    tmpblock2_x_o2 = block1_x+1'd1;
                    if(| {occupied[block1_y][tmpblock0_x_o2],  occupied[block1_y][tmpblock1_x_o2], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock2_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase
        end
        Z:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                 
                    tmpblock1_y_o2 = block2_y-1'd1;
                    tmpblock0_y_o2 = block2_y+1'd1;
                
                    if(| {occupied[tmpblock1_y_o2][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock0_y_o2][block0_x] , occupied[block2_y][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock1_y_o2 = block2_y-1'd1;
                    tmpblock0_y_o2 = block2_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y_o2][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    // I 0->1
                    tmpblock0_x_o2 = block1_x-1'd1;
                    tmpblock1_x_o2 = block1_x+1'd1;
                    // tmpblock2_x_o2 = block2_x-1'd1;
                    if(| {occupied[block2_y][block1_x],  occupied[block2_y][tmpblock0_x_o2], occupied[block3_y][tmpblock1_x_o2] , occupied[block3_y][block1_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o2 = block1_x+1'd1;
                    tmpblock1_x_o2 = block1_x-1'd1;
                    // tmpblock2_x_o2 = block1_x+2'd3;
                    if(| {occupied[block0_y][block1_x],  occupied[block0_y][tmpblock0_x_o2], occupied[block2_y][block1_x] , occupied[block2_y][tmpblock0_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end

            end
            2'd2:begin
               if(direction)begin // clockwise 2->3                 
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock1_y_o2][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock0_y_o2][block0_x] , occupied[block2_y][block0_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o2 = block2_y-1'd1;
                    tmpblock1_y_o2 = block2_y+1'd1;
                    // tmpblock2_y_o2 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o2][block2_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y_o2][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock1_x_o2 = block1_x+1'd1;
                    tmpblock0_x_o2 = block1_x-1'd1;
                    
                    if(| {occupied[block3_y][tmpblock0_x_o2],  occupied[block3_y][block1_x], occupied[block2_y][block1_x] , occupied[block2_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o2 = block2_x-1'd1;
                    tmpblock1_x_o2 = block2_x-2'd2;
                    
                    
                    if(| {occupied[block0_y][tmpblock0_x_o2],  occupied[block0_y][block2_x], occupied[block2_y][tmpblock0_x_o2] , occupied[block2_y][tmpblock1_x_o2]}   )
                        is_occupy_2 = 1;
                    else
                        is_occupy_2 = 0;
                end
            end
            endcase
        end
        default: begin
           is_occupy_2 = 1;
        end
    endcase   
end

// is_occupblock2_y
always@(*)
begin
    tmpblock0_y_o3 = 0;
    tmpblock1_y_o3 = 0;
    tmpblock2_y_o3 = 0;
    tmpblock0_x_o3= 0;
    tmpblock1_x_o3= 0;
    tmpblock2_x_o3= 0;
     case (tetris_type)
        I: begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o3 = block3_y-1'd1;
                    tmpblock1_y_o3 = block3_y+1'd1;
                    tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o3][block3_x] , occupied[tmpblock2_y_o3][block3_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o3 = block0_y-1'd1;
                    tmpblock1_y_o3 = block0_y+1'd1;
                    tmpblock2_y_o3 = block0_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o3][block0_x] , occupied[tmpblock2_y_o3][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o3= block2_x+1'd1;
                    tmpblock1_x_o3= block2_x+2'd2;
                    tmpblock2_x_o3= block2_x+2'd3;
                    if(| {occupied[block2_y][block2_x],  occupied[block2_y][tmpblock0_x_o3], occupied[block2_y][tmpblock1_x_o3] , occupied[block2_y][tmpblock2_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o3= block1_x-2'd3;
                    tmpblock1_x_o3= block1_x-2'd2;
                    tmpblock2_x_o3= block1_x-1'd1;
                    if(| {occupied[block1_y][tmpblock0_x_o3],  occupied[block1_y][tmpblock1_x_o3], occupied[block1_y][tmpblock2_x_o3] , occupied[block1_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o3 = block3_y+1'd1;
                    tmpblock1_y_o3 = block3_y-1'd1;
                    tmpblock2_y_o3 = block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o3][block3_x] , occupied[tmpblock2_y_o3][block3_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o3 = block0_y-2'd2;
                    tmpblock1_y_o3 = block0_y-1'd1;
                    tmpblock2_y_o3 = block0_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o3][block0_x] , occupied[tmpblock2_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o3 = block2_x+2'd3;
                    tmpblock1_x_o3 = block2_x+2'd2;
                    tmpblock2_x_o3 = block2_x+1'd1;
                    if(| {occupied[block2_y][tmpblock0_x_o3],  occupied[block2_y][tmpblock1_x_o3], occupied[block2_y][block2_x] , occupied[block2_y][tmpblock2_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o3 = block1_x-2'd3;
                    tmpblock1_x_o3 = block1_x-2'd2;
                    tmpblock2_x_o3 = block1_x-1'd1;
                    if(| {occupied[block1_y][tmpblock0_x_o3],  occupied[block1_y][tmpblock1_x_o3], occupied[block1_y][block1_x] , occupied[block1_y][tmpblock2_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end 
            end
            endcase
        end
        J:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o3 = block2_y-2'd2;
                    tmpblock1_y_o3 = block2_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block1_x],  occupied[block2_y][block1_x], occupied[tmpblock0_y_o3][block2_x] , occupied[tmpblock1_y_o3][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o3 = block2_y-2'd2;
                    tmpblock1_y_o3 = block2_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block2_y][block2_x], occupied[tmpblock1_y_o3][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o3 = block2_x+2'd2;
                    tmpblock1_x_o3 = block2_x+1'd1;
                    tmpblock0_y_o3 = block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[block3_y][tmpblock1_x_o3], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o3 = block2_x+2'd2;
                    tmpblock1_x_o3 = block2_x+1'd1;
                    
                    if(| {occupied[block3_y][tmpblock1_x_o3],  occupied[block3_y][tmpblock0_x_o3], occupied[block3_y][block2_x] , occupied[block2_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o3 = block2_y-2'd2;
                    tmpblock1_y_o3 = block2_y-1'd1;
                    
                    if(| {occupied[tmpblock1_y_o3][block1_x],  occupied[block2_y][block1_x], occupied[tmpblock0_y_o3][block1_x] , occupied[block2_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o3 = block2_y-2'd2;
                    tmpblock1_y_o3 = block2_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[tmpblock0_y_o3][block2_x], occupied[tmpblock1_y_o3][block3_x] , occupied[block2_y][block3_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0    
                    
                    tmpblock0_x_o3 = block2_x-2'd2;
                    tmpblock1_x_o3 = block2_x-1'd1;
                    // tmpblock0_y_o3 = block3_y+1'd1;
                    if(| {occupied[block2_y][tmpblock0_x_o3],  occupied[block1_y][tmpblock1_x_o3], occupied[block1_y][block2_x] , occupied[block1_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o3 = block2_x-2'd2;
                    tmpblock1_x_o3 = block2_x-1'd1;
                    tmpblock0_y_o3 = block1_y+1'd1;
                    if(| {occupied[block1_y][tmpblock1_x_o3],  occupied[block1_y][tmpblock0_x_o3], occupied[block1_y][block2_x] , occupied[tmpblock0_y_o3][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            endcase 
        end
        L:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o3 = block1_y-2'd2;
                    tmpblock1_y_o3 = block1_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block1_y][block0_x], occupied[block1_y][block1_x] , occupied[tmpblock1_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o3 = block1_y-2'd2;
                    tmpblock1_y_o3 = block1_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o3][block2_x] , occupied[tmpblock0_y_o3][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o3 = block1_x+2'd2;
                    tmpblock1_x_o3 = block1_x+1'd1;
                    tmpblock0_y_o3 = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][block1_x],  occupied[block2_y][tmpblock1_x_o3], occupied[block2_y][block1_x] , occupied[block2_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o3 = block1_x+2'd2;
                    tmpblock1_x_o3 = block1_x+1'd1;
                    
                    if(| {occupied[block2_y][tmpblock1_x_o3],  occupied[block2_y][tmpblock0_x_o3], occupied[block2_y][block1_x] , occupied[block1_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o3 = block1_y-2'd2;
                    tmpblock1_y_o3 = block1_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock0_y_o3][block1_x] , occupied[tmpblock1_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o3 = block1_y-2'd2;
                    tmpblock1_y_o3 = block1_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o3][block2_x],  occupied[block1_y][block2_x], occupied[tmpblock1_y_o3][block2_x] , occupied[block1_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0    
                    tmpblock1_x_o3 = block1_x-2'd2;
                    tmpblock0_x_o3 = block1_x-1'd1;
                    
                    if(| {occupied[block0_y][tmpblock1_x_o3],  occupied[block0_y][tmpblock0_x_o3], occupied[block1_y][block1_x] , occupied[block0_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                    
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o3 = block1_x-2'd2;
                    tmpblock1_x_o3 = block1_x-1'd1;
                    tmpblock0_y_o3 = block0_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[block0_y][tmpblock1_x_o3], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            endcase 
        end
        O:begin
           is_occupy_3 = 1;
        end
        S:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock1_y_o3 = block2_y+1'd1;
                    tmpblock0_y_o3 = block2_y-1'd1;
                    // tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block2_y][block0_x], occupied[tmpblock1_y_o3][block1_x] , occupied[block2_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o3 = block2_y+1'd1;
                    tmpblock1_y_o3 = block2_y-1'd1;
                    // tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block2_y][block3_x], occupied[tmpblock1_y_o3][block1_x] , occupied[block2_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock1_x_o3= block2_x+1'd1;
                    tmpblock0_x_o3= block2_x-1'd1;
                    tmpblock0_y_o3= block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[tmpblock0_y_o3][block2_x], occupied[block3_y][tmpblock1_x_o3] , occupied[block3_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                   tmpblock1_x_o3= block1_x+1'd1;
                    tmpblock0_x_o3= block1_x-1'd1;
                    // tmpblock2_x_o3= block1_x-1'd1;
                    if(| {occupied[block3_y][tmpblock0_x_o3],  occupied[block1_y][tmpblock1_x_o3], occupied[block1_y][block2_x] , occupied[block3_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o3 = block1_y-1'd1;
                    tmpblock1_y_o3 = block1_y-2'd2;
                    // tmpblock2_y_o3 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock0_y_o3][block1_x] , occupied[tmpblock1_y_o3][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y_o3 = block1_y-1'd1;
                    tmpblock0_y_o3 = block1_y-2'd2;
                    // tmpblock2_y_o3 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[tmpblock1_y_o3][block3_x], occupied[block1_y][block1_x] , occupied[tmpblock1_y_o3][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o3 = block1_x-1'd1;
                    tmpblock1_x_o3 = block1_x+1'd1;
                    // tmpblock2_x_o3 = block2_x+1'd1;
                    if(| {occupied[block0_y][block1_x],  occupied[block0_y][tmpblock1_x_o3], occupied[block2_y][tmpblock0_x_o3] , occupied[block2_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o3 = block1_x-1'd1;
                    tmpblock1_x_o3 = block1_x+1'd1;
                    tmpblock0_y_o3 = block0_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock1_x_o3],  occupied[tmpblock0_y_o3][block1_x], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end 
            end
            endcase 
        end
        T:begin
           case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    // Is_occupy occupblock2_y(occupied,block3_x, block3_y+5'd1, block3_x, block3_y, block3_x, block3_y-5'd1, block3_x, block3_y-5'd2, is_occupy_3 );             
                    // I 0->1
                    tmpblock0_y_o3 = block0_y-2'd2;
                    tmpblock1_y_o3 = block0_y-1'd1;
                    // tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block3_y][block1_x], occupied[tmpblock1_y_o3][block0_x] , occupied[block0_y][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o3 = block0_y+1'd1;
                    tmpblock1_y_o3 = block0_y-1'd1;
                    tmpblock2_y_o3 = block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o3][block0_x] , occupied[tmpblock2_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o3= block1_x+1'd1;
                    tmpblock1_x_o3= block1_x+2'd2;
                    tmpblock0_y_o3= block2_y+1'd1;
                    if(| {occupied[block2_y][block1_x],  occupied[block2_y][tmpblock0_x_o3], occupied[block2_y][tmpblock1_x_o3] , occupied[tmpblock0_y_o3][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                   tmpblock0_x_o3= block1_x+1'd1;
                    tmpblock1_x_o3= block1_x+2'd2;
                    // tmpblock2_x_o3= block1_x-1'd1;
                    if(| {occupied[block2_y][tmpblock0_x_o3],  occupied[block2_y][tmpblock1_x_o3], occupied[block1_y][tmpblock0_x_o3] , occupied[block2_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o3 = block3_y+1'd1;
                    tmpblock1_y_o3 = block3_y-1'd1;
                    tmpblock2_y_o3 = block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o3][block3_x] , occupied[tmpblock2_y_o3][block3_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o3 = block0_y-2'd2;
                    tmpblock1_y_o3 = block0_y-1'd1;
                    tmpblock2_y_o3 = block0_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o3][block0_x] , occupied[tmpblock2_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o3 = block1_x-2'd2;
                    tmpblock1_x_o3 = block1_x-1'd1;
                    // tmpblock2_x_o3 = block2_x+1'd1;
                    if(| {occupied[block0_y][tmpblock0_x_o3],  occupied[block0_y][tmpblock1_x_o3], occupied[block0_y][block1_x] , occupied[block1_y][tmpblock1_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o3 = block1_x-1'd1;
                    tmpblock1_x_o3 = block1_x-2'd2;
                    tmpblock0_y_o3 = block0_y-1'd1;
                    if(| {occupied[block0_y][tmpblock0_x_o3],  occupied[block0_y][tmpblock1_x_o3], occupied[block0_y][block1_x] , occupied[tmpblock0_y_o3][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end 
            end
            endcase 
        end
        Z:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o3 = block1_y+1'd1;
                    tmpblock1_y_o3 = block1_y-1'd1;
                    // tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y_o3][block2_x] , occupied[block1_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock1_y_o3 = block1_y+1'd1;
                    tmpblock0_y_o3 = block1_y-1'd1;
                    // tmpblock2_y_o3 = block3_y+2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block1_y][block3_x], occupied[tmpblock1_y_o3][block2_x] , occupied[block1_y][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o3= block1_x+1'd1;
                    tmpblock1_x_o3= block1_x-1'd1;
                    tmpblock0_y_o3= block3_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[tmpblock0_y_o3][block1_x], occupied[block3_y][tmpblock1_x_o3] , occupied[block3_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 1->0
                   tmpblock0_x_o3= block1_x+1'd1;
                    tmpblock1_x_o3= block1_x-1'd1;
                    // tmpblock2_x_o3= block1_x-1'd1;
                    if(| {occupied[block3_y][tmpblock0_x_o3],  occupied[block2_y][tmpblock1_x_o3], occupied[block2_y][block1_x] , occupied[block3_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o3 = block2_y-1'd1;
                    tmpblock1_y_o3 = block2_y-2'd2;
                    // tmpblock2_y_o3 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block0_x],  occupied[block2_y][block2_x], occupied[tmpblock0_y_o3][block2_x] , occupied[tmpblock1_y_o3][block0_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o3 = block2_y-1'd1;
                    tmpblock1_y_o3 = block2_y-2'd2;
                    // tmpblock2_y_o3 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][block3_x],  occupied[block2_y][block3_x], occupied[tmpblock0_y_o3][block2_x] , occupied[tmpblock1_y_o3][block2_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o3 = block1_x-1'd1;
                    tmpblock1_x_o3 = block1_x+1'd1;
                    
                    // tmpblock2_x_o3 = block2_x+1'd1;
                    if(| {occupied[block0_y][block1_x],  occupied[block0_y][tmpblock1_x_o3], occupied[block2_y][tmpblock0_x_o3] , occupied[block2_y][block1_x]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock1_x_o3 = block2_x-1'd1;
                    tmpblock0_x_o3 = block2_x-2'd2;
                    tmpblock0_y_o3 = block0_y+1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock1_x_o3],  occupied[tmpblock0_y_o3][block2_x], occupied[block0_y][tmpblock1_x_o3] , occupied[block0_y][tmpblock0_x_o3]}   )
                        is_occupy_3 = 1;
                    else
                        is_occupy_3 = 0;
                end 
            end
            endcase 
        end
        default: begin
           is_occupy_3=1;
        end
    endcase   
end
//is_occupblock3_y
always@(*)begin
    tmpblock0_y_o4 = 0;
    tmpblock1_y_o4 = 0;
    tmpblock2_y_o4 = 0;
    tmpblock0_x_o4= 0;
    tmpblock1_x_o4= 0;
    tmpblock2_x_o4= 0;
     case (tetris_type)
        I: begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1       
                    
                    tmpblock0_y_o4 = block3_y-2'd3;
                    tmpblock1_y_o4 = block3_y-2'd2;
                    tmpblock2_y_o4 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][block3_x],  occupied[tmpblock1_y_o4][block3_x], occupied[tmpblock2_y_o4][block3_x] , occupied[block3_y][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o4 = block0_y-2'd3;
                    tmpblock1_y_o4 = block0_y-2'd2;
                    tmpblock2_y_o4 = block0_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][block0_x],  occupied[tmpblock1_y_o4][block0_x], occupied[tmpblock2_y_o4][block0_x] , occupied[block0_y][block0_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x-2'd2;
                    tmpblock2_x_o4 = block2_x-2'd3;
                    if(| {occupied[block0_y][tmpblock0_x_o4],  occupied[block0_y][tmpblock1_x_o4], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock2_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o4 = block1_x+1'd1;
                    tmpblock1_x_o4 = block1_x+2'd2;
                    tmpblock2_x_o4 = block1_x+2'd3;
                    if(| {occupied[block0_y][tmpblock0_x_o4],  occupied[block0_y][tmpblock1_x_o4], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock2_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    tmpblock0_y_o4 = block0_y-1'd1;
                    tmpblock1_y_o4 = block0_y-2'd2;
                    tmpblock2_y_o4 = block0_y-2'd3;
                    if(| {occupied[block0_y][block0_x],  occupied[tmpblock0_y_o4][block0_x], occupied[tmpblock1_y_o4][block0_x] , occupied[tmpblock2_y_o4][block0_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o4 = block3_y-2'd3;
                    tmpblock1_y_o4 = block3_y-2'd2;
                    tmpblock2_y_o4 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][block3_x],  occupied[block3_y][block3_x], occupied[tmpblock1_y_o4][block3_x] , occupied[tmpblock2_y_o4][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x-2'd3;
                    tmpblock2_x_o4 = block2_x-2'd2;
                    if(| {occupied[block3_y][tmpblock0_x_o4],  occupied[block3_y][tmpblock1_x_o4], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock2_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o4 = block1_x+1'd1;
                    tmpblock1_x_o4 = block1_x+2'd2;
                    tmpblock2_x_o4 = block1_x+2'd3;
                    if(| {occupied[block3_y][tmpblock0_x_o4],  occupied[block3_y][tmpblock1_x_o4], occupied[block3_y][block1_x] , occupied[block3_y][tmpblock2_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            endcase
        end
        J:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o4 = block2_y+1'd1;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock2_y_o4 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o4][block3_x],  occupied[tmpblock0_y_o4][block2_x], occupied[tmpblock1_y_o4][block2_x] , occupied[tmpblock2_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock2_y_o4 = block2_y+1'd1;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock0_y_o4 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock0_y_o4][block2_x], occupied[tmpblock1_y_o4][block2_x] , occupied[tmpblock2_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x+1'd1;
                    tmpblock0_y_o4 = block1_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block2_x] , occupied[block1_y][tmpblock1_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x+1'd1;
                    tmpblock0_y_o4 = block1_y-1'd1;
                    tmpblock1_y_o4 = block1_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block2_x] , occupied[tmpblock1_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock2_y_o4 = block2_y+1'd1;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock0_y_o4 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o4][block3_x],  occupied[tmpblock0_y_o4][block2_x], occupied[tmpblock1_y_o4][block2_x] , occupied[tmpblock2_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o4 = block2_y+1'd1;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock2_y_o4 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock0_y_o4][block2_x], occupied[tmpblock1_y_o4][block2_x] , occupied[tmpblock2_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0    
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x+1'd1;
                    tmpblock0_y_o4 = block3_y-1'd1;
                    tmpblock1_y_o4 = block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block2_x] , occupied[tmpblock1_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                    
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x+1'd1;
                    tmpblock0_y_o4 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block2_x] , occupied[block3_y][tmpblock1_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            endcase
        end
        L:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o4 = block1_y+1'd1;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+2'd3;
                    
                    if(| {occupied[tmpblock2_y_o4][block2_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[tmpblock2_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock2_y_o4 = block1_y+1'd1;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock0_y_o4 = block1_y+2'd3;
                    
                    if(| {occupied[tmpblock2_y_o4][block0_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[tmpblock2_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o4 = block1_x-1'd1;
                    tmpblock1_x_o4 = block1_x+1'd1;
                    tmpblock0_y_o4 = block0_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block1_x] , occupied[block0_y][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o4 = block1_x-1'd1;
                    tmpblock1_x_o4 = block1_x+1'd1;
                    tmpblock0_y_o4 = block0_y-1'd1;
                    tmpblock1_y_o4 = block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block1_x] , occupied[tmpblock1_y_o4][tmpblock1_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o4 = block3_y-1'd1;
                    tmpblock1_y_o4 = block3_y-2'd2;
                    // tmpblock2_y_o4 = block1_y+2'd3;
                    
                    if(| {occupied[block3_y][block2_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[block3_y][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o4 = block3_y+1'd1;
                    tmpblock1_y_o4 = block3_y+2'd2;
                
                    
                    if(| {occupied[tmpblock1_y_o4][block0_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[block3_y][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0    
                    tmpblock0_x_o4 = block1_x-1'd1;
                    tmpblock1_x_o4 = block1_x+1'd1;
                    tmpblock0_y_o4 = block2_y-1'd1;
                    tmpblock1_y_o4 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block1_x] , occupied[tmpblock1_y_o4][tmpblock1_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                    
                     
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o4 = block1_x-1'd1;
                    tmpblock1_x_o4 = block1_x+1'd1;
                    tmpblock0_y_o4 = block2_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block1_x] , occupied[block2_y][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
        endcase
        end
        O:begin
           is_occupy_4 = 1;
        end
        S:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                       
                    tmpblock2_y_o4 = block1_y+2'd3;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock0_y_o4 = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock1_y_o4][block1_x], occupied[tmpblock2_y_o4][block3_x] , occupied[tmpblock1_y_o4][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock2_y_o4 = block2_y+2'd3;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock0_y_o4 = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block0_x],  occupied[tmpblock1_y_o4][block0_x], occupied[tmpblock2_y_o4][block1_x] , occupied[tmpblock1_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock1_x_o4= block1_x+1'd1;
                    tmpblock0_x_o4= block1_x-1'd1;
                    tmpblock0_y_o4= block0_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock1_x_o4],  occupied[tmpblock0_y_o4][block1_x], occupied[block0_y][tmpblock0_x_o4] , occupied[block0_y][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock1_x_o4= block1_x+1'd1;
                    tmpblock0_x_o4= block1_x-1'd1;
                    tmpblock0_y_o4= block0_y-1'd1;
                    tmpblock1_y_o4= block0_y-2'd2;
                    if(| {occupied[tmpblock1_y_o4][tmpblock1_x_o4],  occupied[tmpblock1_y_o4][block1_x], occupied[tmpblock0_y_o4][block1_x] , occupied[tmpblock0_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    tmpblock0_y_o4 = block2_y+1'd1;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    
                    if(| {occupied[tmpblock1_y_o4][block1_x],  occupied[tmpblock0_y_o4][block1_x], occupied[block2_y][block3_x] , occupied[tmpblock0_y_o4][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y_o4 = block2_y+1'd1;
                    tmpblock0_y_o4 = block2_y+2'd2;
                    // tmpblock2_y_o4 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o4][block1_x],  occupied[block2_y][block1_x], occupied[tmpblock1_y_o4][block0_x] , occupied[tmpblock0_y_o4][block0_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                    
                    tmpblock1_x_o4= block1_x+1'd1;
                    tmpblock0_x_o4= block1_x-1'd1;
                    tmpblock0_y_o4= block3_y-1'd1;
                    tmpblock1_y_o4= block3_y-2'd2;
                    if(| {occupied[tmpblock1_y_o4][tmpblock1_x_o4],  occupied[tmpblock1_y_o4][block1_x], occupied[tmpblock0_y_o4][block1_x] , occupied[tmpblock0_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock1_x_o4= block1_x+1'd1;
                    tmpblock0_x_o4= block1_x-1'd1;
                    tmpblock0_y_o4= block3_y-1'd1;
                    // tmpblock1_y_o4= block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock1_x_o4],  occupied[tmpblock0_y_o4][block1_x], occupied[block3_y][tmpblock0_x_o4] , occupied[block3_y][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            
            endcase 
        end
        T:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1       
                    
                    tmpblock0_y_o4 = block1_y+2'd3;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock1_y_o4][block1_x], occupied[tmpblock2_y_o4][block1_x] , occupied[tmpblock1_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o4 = block1_y+2'd3;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock1_y_o4][block1_x], occupied[tmpblock2_y_o4][block1_x] , occupied[tmpblock1_y_o4][block0_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o4= block2_x-2'd3;
                    tmpblock1_x_o4= block2_x-2'd2;
                    tmpblock2_x_o4= block2_x-1'd1;
                    // tmpblock0_y_o4= block2_y+2'd2;
                    if(| {occupied[tmpblock0_y_o4][block0_y],  occupied[tmpblock0_y_o4][block0_y], occupied[tmpblock0_y_o4][block0_y] , occupied[tmpblock0_y_o4][block0_y]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o4= block1_x+1'd1;
                    tmpblock1_x_o4= block1_x-1'd1;
                    tmpblock0_y_o4= block0_y-1'd1;
                    tmpblock1_y_o4= block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][block1_x],  occupied[tmpblock0_y_o4][tmpblock0_x_o4], occupied[tmpblock0_y_o4][tmpblock1_x_o4] , occupied[tmpblock1_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    tmpblock0_y_o4 = block1_y+1'd1;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o4][block2_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[tmpblock2_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o4 = block1_y+1'd1;
                    tmpblock1_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o4][block0_x],  occupied[tmpblock0_y_o4][block1_x], occupied[tmpblock1_y_o4][block1_x] , occupied[tmpblock2_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o4 = block2_x-1'd1;
                    tmpblock1_x_o4 = block2_x+1'd1;
                    tmpblock0_y_o4 = block2_y-1'd1;
                    tmpblock1_y_o4 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][tmpblock1_x_o4], occupied[tmpblock0_y_o4][block1_x] , occupied[tmpblock1_y_o4][block1_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o4 = block1_x+2'd3;
                    tmpblock1_x_o4 = block1_x+2'd2;
                    tmpblock2_x_o4 = block1_x+1'd1;
                    if(| {occupied[block3_y][tmpblock0_x_o4],  occupied[block3_y][tmpblock1_x_o4], occupied[block3_y][block1_x] , occupied[block3_y][tmpblock2_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            endcase

        end
        Z:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                       
                    tmpblock0_y_o4 = block2_y+2'd3;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock2_y_o4 = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block2_x],  occupied[tmpblock1_y_o4][block2_x], occupied[tmpblock2_y_o4][block3_x] , occupied[tmpblock1_y_o4][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o4 = block2_y+2'd3;
                    tmpblock1_y_o4 = block2_y+2'd2;
                    tmpblock2_y_o4 = block2_y+1'd1;
                    if(| {occupied[tmpblock0_y_o4][block0_x],  occupied[tmpblock1_y_o4][block0_x], occupied[tmpblock2_y_o4][block2_x] , occupied[tmpblock1_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o4= block2_x+1'd1;
                    tmpblock1_x_o4= block2_x-1'd1;
                    tmpblock0_y_o4= block0_y-1'd1;
                    if(| {occupied[tmpblock0_y_o4][tmpblock1_x_o4],  occupied[tmpblock0_y_o4][block2_x], occupied[block0_y][tmpblock0_x_o4] , occupied[block0_y][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o4= block2_x+1'd1;
                    tmpblock1_x_o4= block2_x-1'd1;
                    tmpblock0_y_o4= block0_y-1'd1;
                    tmpblock1_y_o4= block0_y-2'd2;
                    if(| {occupied[tmpblock1_y_o4][tmpblock1_x_o4],  occupied[tmpblock1_y_o4][block2_x], occupied[tmpblock0_y_o4][block2_x] , occupied[tmpblock0_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                    tmpblock1_y_o4 = block1_y+1'd1;
                    tmpblock0_y_o4 = block1_y+2'd2;
                    tmpblock2_y_o4 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o4][block2_x],  occupied[tmpblock0_y_o4][block2_x], occupied[tmpblock2_y_o4][block3_x] , occupied[tmpblock0_y_o4][block3_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock1_y_o4 = block1_y+1'd1;
                    tmpblock0_y_o4 = block1_y+2'd2;
                    // tmpblock2_y_o4 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o4][block0_x],  occupied[block1_y][block0_x], occupied[tmpblock1_y_o4][block2_x] , occupied[tmpblock0_y_o4][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o4= block2_x+1'd1;
                    tmpblock1_x_o4= block2_x-1'd1;
                    tmpblock0_y_o4= block3_y-1'd1;
                    tmpblock1_y_o4= block3_y-2'd2;
                    if(| {occupied[tmpblock1_y_o4][tmpblock1_x_o4],  occupied[tmpblock1_y_o4][block2_x], occupied[tmpblock0_y_o4][block2_x] , occupied[tmpblock0_y_o4][tmpblock0_x_o4]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock1_x_o4= block2_x+1'd1;
                    tmpblock0_x_o4= block2_x-1'd1;
                    tmpblock0_y_o4= block3_y-1'd1;
                    // tmpblock1_y_o4= block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o4][tmpblock0_x_o4],  occupied[tmpblock0_y_o4][block2_x], occupied[block3_y][tmpblock1_x_o4] , occupied[block3_y][block2_x]}   )
                        is_occupy_4 = 1;
                    else
                        is_occupy_4 = 0;
                end  
            end
            endcase
        end
        default: begin
           is_occupy_4 = 1;
        end
    endcase   
end
//is_occupy5
always@(*)
begin
    tmpblock0_y_o5 = 0;
    tmpblock1_y_o5 = 0;
    tmpblock2_y_o5 = 0;
    tmpblock0_x_o5= 0;
    tmpblock1_x_o5= 0;
    tmpblock2_x_o5= 0;
     case (tetris_type)
        I: begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1   
                    // Is_occupy occupy5(occupied,block0_x, block0_y, block0_x, block0_y-5'd1, block0_x, block0_y-5'd2, block0_x, block0_y-5'd3, is_occupy_5 );                
                    // I 0->1
                    tmpblock0_y_o5 = block0_y+1'd1;
                    tmpblock1_y_o5 = block0_y+2'd2;
                    tmpblock2_y_o5 = block0_y+2'd3;
                    if(| {occupied[block0_y][block0_x],  occupied[tmpblock0_y_o5][block0_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o5 = block3_y+1'd1;
                    tmpblock1_y_o5 = block3_y+2'd2;
                    tmpblock2_y_o5 = block3_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block3_x],  occupied[tmpblock0_y_o5][block3_x], occupied[tmpblock2_y_o5][block3_x] , occupied[block3_y][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o5= block1_x+1'd1;
                    tmpblock1_x_o5= block1_x+2'd2;
                    tmpblock2_x_o5= block2_x+2'd3;
                  
                    if(| {occupied[block3_y][tmpblock0_x_o5],  occupied[block3_y][tmpblock1_x_o5], occupied[block3_y][tmpblock2_x_o5] , occupied[block3_y][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o5= block1_x-1'd1;
                    tmpblock1_x_o5= block1_x-2'd2;
                    tmpblock2_x_o5= block1_x-2'd3;
                    if(| {occupied[block3_y][tmpblock0_x_o5],  occupied[block3_y][tmpblock1_x_o5], occupied[block3_y][block1_x] , occupied[block3_y][tmpblock2_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o5 = block3_y+1'd1;
                    tmpblock1_y_o5 = block3_y+2'd2;
                    tmpblock2_y_o5 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o5][block3_x],  occupied[tmpblock1_y_o5][block3_x], occupied[tmpblock2_y_o5][block3_x] , occupied[block3_y][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o5 = block0_y+1'd1;
                    tmpblock1_y_o5 = block0_y+2'd2;
                    tmpblock2_y_o5 = block0_y-1'd1;
                    if(| {occupied[tmpblock1_y_o5][block0_x],  occupied[tmpblock0_y_o5][block0_x], occupied[tmpblock2_y_o5][block0_x] , occupied[block0_y][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o5= block2_x+1'd1;
                    tmpblock1_x_o5= block2_x+2'd2;
                    tmpblock2_x_o5= block2_x+2'd3;
                    if(| {occupied[block0_y][tmpblock0_x_o5],  occupied[block0_y][tmpblock1_x_o5], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock2_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5= block1_x-1'd1;
                    tmpblock1_x_o5= block1_x-2'd2;
                    tmpblock2_x_o5= block1_x-2'd3;
                    if(| {occupied[block0_y][tmpblock0_x_o5],  occupied[block0_y][tmpblock1_x_o5], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock2_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end 
            end
            endcase
        end
        J:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock2_y_o5 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block1_x],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock1_y_o5][block1_x] , occupied[tmpblock2_y_o5][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock2_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock0_y_o5= block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block3_x],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock1_y_o5][block3_x] , occupied[tmpblock2_y_o4][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o5 = block2_x+1'd1;
                    tmpblock1_x_o5 = block2_x+2'd2;
                    tmpblock0_y_o5 = block1_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[block1_y][tmpblock1_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o5 = block2_x+1'd1;
                    tmpblock1_x_o5 = block2_x+2'd2;
                    tmpblock0_y_o5 = block1_y-1'd1;
                    tmpblock1_y_o5 = block1_y-2'd2;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[tmpblock1_y_o5][block2_x]}   )
                    is_occupy_5 = 1;
                    else
                    is_occupy_5 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock2_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock0_y_o5 = block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block1_x],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock1_y_o5][block1_x] , occupied[tmpblock2_y_o5][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->0
                    tmpblock2_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock0_y_o5= block2_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block3_x],  occupied[tmpblock2_y_o5][block2_x], occupied[tmpblock1_y_o5][block3_x] , occupied[tmpblock2_y_o4][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                      
                    tmpblock0_x_o5 = block2_x-1'd1;
                    tmpblock1_x_o5 = block2_x-2'd2;
                    tmpblock0_y_o5 = block3_y-1'd1;
                    tmpblock1_y_o5 = block3_y-2'd2;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[tmpblock1_y_o5][tmpblock1_x_o5]}   )
                    is_occupy_5 = 1;
                    else
                    is_occupy_5 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5 = block2_x-1'd1;
                    tmpblock1_x_o5 = block2_x-2'd2;
                    tmpblock0_y_o5 = block3_y-1'd1;
                    // tmpblock1_y_o5 = block1_y-2'd2;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[block3_y][block2_x]}   )
                    is_occupy_5 = 1;
                    else
                    is_occupy_5 = 0;
                end
            end
            endcase
        end
        L:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1    
                    
                    tmpblock0_y_o5 = block1_y+1'd1;
                    tmpblock1_y_o5 = block1_y+2'd2;
                    tmpblock2_y_o5 = block1_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block0_x],  occupied[tmpblock2_y_o5][block1_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock2_y_o5 = block1_y+1'd1;
                    tmpblock1_y_o5 = block1_y+2'd2;
                    tmpblock0_y_o5= block1_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block2_x],  occupied[tmpblock2_y_o5][block1_x], occupied[tmpblock1_y_o5][block2_x] , occupied[tmpblock2_y_o4][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2    
                    
                    tmpblock0_x_o5 = block1_x+1'd1;
                    tmpblock1_x_o5 = block1_x+2'd2;
                    tmpblock0_y_o5 = block0_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block1_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[block0_y][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o5 = block1_x+1'd1;
                    tmpblock1_x_o5 = block1_x+2'd2;
                    tmpblock0_y_o5 = block0_y-1'd1;
                    tmpblock1_y_o5 = block0_y-2'd2;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block1_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[tmpblock1_y_o5][tmpblock1_x_o5]}   )
                    is_occupy_5 = 1;
                    else
                    is_occupy_5 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3    
                    
                    tmpblock0_y_o5 = block3_y-1'd1;
                    tmpblock1_y_o5 = block3_y-2'd2;
                    // tmpblock2_y_o5 = block1_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block0_x],  occupied[block3_y][block1_x], occupied[tmpblock1_y_o5][block0_x] , occupied[block3_y][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o5 = block3_y+1'd1;
                    tmpblock1_y_o5 = block3_y+2'd2;
                    // tmpblock0_y_o5= block1_y+2'd3;
                    
                    if(| {occupied[tmpblock0_y_o5][block2_x],  occupied[tmpblock1_y_o5][block1_x], occupied[tmpblock1_y_o5][block2_x] , occupied[block3_y][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0    
                    
                    tmpblock0_x_o5 = block1_x-1'd1;
                    tmpblock1_x_o5 = block1_x-2'd2;
                    tmpblock0_y_o5 = block2_y-1'd1;
                    tmpblock1_y_o5 = block2_y-2'd2;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block1_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[tmpblock1_y_o5][block1_x]}   )
                    is_occupy_5 = 1;
                    else
                    is_occupy_5 = 0;
                    
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5 = block1_x-1'd1;
                    tmpblock1_x_o5 = block1_x-2'd2;
                    tmpblock0_y_o5 = block2_y-1'd1;
                    
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][block1_x], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[block2_y][tmpblock1_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            endcase
        end
        O:begin
           is_occupy_5 = 0;
        end
        S:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                      
                    tmpblock0_y_o5 = block1_y+1'd1;
                    tmpblock1_y_o5 = block1_y+2'd2;
                    tmpblock2_y_o5 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block1_x],  occupied[tmpblock0_y_o5][block0_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o5 = block1_y+1'd1;
                    tmpblock1_y_o5 = block1_y+2'd2;
                    tmpblock2_y_o5 = block1_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block3_x],  occupied[tmpblock0_y_o5][block1_x], occupied[tmpblock1_y_o5][block1_x] , occupied[tmpblock2_y_o5][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                   
                    tmpblock0_x_o5= block2_x+1'd1;
                    tmpblock1_x_o5= block2_x-1'd1;
                    tmpblock0_y_o5= block0_y-1'd1;
                    // tmpblock1_y_o3= block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[tmpblock0_y_o3][block2_x], occupied[block0_y][block2_x] , occupied[block0_y][tmpblock1_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock1_x_o5= block2_x+1'd1;
                    tmpblock0_x_o5= block2_x-1'd1;
                    tmpblock0_y_o5= block0_y-1'd1;
                    tmpblock1_y_o5= block0_y-2'd2;
                    if(| {occupied[tmpblock1_y_o3][tmpblock1_x_o3],  occupied[tmpblock1_y_o3][block2_x], occupied[tmpblock0_y_o3][block2_x] , occupied[tmpblock0_y_o3][tmpblock0_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                      
                    tmpblock0_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    // tmpblock2_y_o5 = block2_y+2'd3;
                    if(| {occupied[block2_y][block1_x],  occupied[tmpblock0_y_o5][block0_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock0_y_o5][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    // tmpblock2_y_o5 = block2_y+2'd3;
                    if(| {occupied[block2_y][block3_x],  occupied[tmpblock0_y_o5][block3_x], occupied[tmpblock1_y_o5][block1_x] , occupied[tmpblock0_y_o5][block1_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd3:begin
                if(direction)begin // clockwise 3->2                 
                    tmpblock1_x_o5= block2_x+1'd1;
                    tmpblock0_x_o5= block2_x-1'd1;
                    tmpblock0_y_o5= block3_y-1'd1;
                    tmpblock1_y_o5= block3_y-2'd2;
                    if(| {occupied[tmpblock1_y_o3][tmpblock1_x_o3],  occupied[tmpblock1_y_o3][block2_x], occupied[tmpblock0_y_o3][block2_x] , occupied[tmpblock0_y_o3][tmpblock0_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                    
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5= block2_x+1'd1;
                    tmpblock1_x_o5= block2_x-1'd1;
                    tmpblock0_y_o5= block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o3][tmpblock0_x_o3],  occupied[tmpblock0_y_o3][block2_x], occupied[block3_y][block2_x] , occupied[block3_y][tmpblock1_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            endcase
        end
        T:begin
          case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1   
                    
                    tmpblock0_y_o5 = block0_y+1'd1;
                    tmpblock1_y_o5 = block0_y+2'd2;
                    tmpblock2_y_o5 = block0_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block1_x],  occupied[tmpblock0_y_o5][block0_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o5 = block3_y-1'd1;
                    tmpblock1_y_o5 = block3_y-2'd2;
                    tmpblock2_y_o5 = block3_y-2'd3;
                    if(| {occupied[block3_y][block3_x],  occupied[tmpblock0_y_o5][block3_x], occupied[tmpblock1_y_o5][block3_x] , occupied[tmpblock2_y_o5][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                    tmpblock0_x_o5= block2_x+1'd1;
                    tmpblock1_x_o5= block2_x+2'd2;
                    tmpblock2_x_o5= block2_x+2'd3;
                    // tmpblock0_y_o5= block2_y-1'd1;
                    if(| {occupied[block3_y][block2_x],  occupied[block3_y][tmpblock0_x_o5], occupied[block3_y][tmpblock1_x_o5] , occupied[block3_y][tmpblock2_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o5= block1_x+1'd1;
                    tmpblock1_x_o5= block1_x+2'd2;
                    tmpblock0_y_o5= block0_y-1'd1;
                    tmpblock1_y_o5= block0_y-2'd2;
                    if(| {occupied[tmpblock0_y_o5][block1_x],  occupied[tmpblock0_y_o5][tmpblock0_x_o5], occupied[tmpblock0_y_o5][tmpblock1_x_o5] , occupied[tmpblock1_y_o5][tmpblock0_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o5 = block3_y+2'd2;
                    tmpblock1_y_o5 = block3_y+1'd1;
                    tmpblock2_y_o5 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o5][block3_x],  occupied[tmpblock1_y_o5][block3_x], occupied[block3_y][block3_x] , occupied[tmpblock2_y_o5][block3_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o5 = block0_y-1'd1;
                    tmpblock1_y_o5 = block0_y+1'd1;
                    tmpblock2_y_o5 = block0_y+2'd2;
                    if(| {occupied[tmpblock0_y_o5][block0_x],  occupied[block0_y][block0_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o5 = block1_x-1'd1;
                    tmpblock1_x_o5 = block1_x-2'd2;
                    tmpblock0_y_o5 = block2_y-1'd1;
                    tmpblock1_y_o5 = block2_y-2'd2;
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][tmpblock1_x_o5], occupied[tmpblock0_y_o5][block1_x] , occupied[tmpblock1_y_o5][tmpblock0_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5 = block1_x-2'd3;
                    tmpblock1_x_o5 = block1_x-2'd2;
                    tmpblock2_x_o5 = block1_x-1'd1;
                    if(| {occupied[block0_y][tmpblock0_x_o5],  occupied[block0_y][tmpblock1_x_o5], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock2_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end 
            end
            endcase  
        end
        Z:begin
            case(rotation)
            2'd0:begin
                if(direction)begin // clockwise 0->1                      
                    tmpblock0_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock2_y_o5 = block2_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block2_x],  occupied[tmpblock0_y_o5][block2_x], occupied[tmpblock1_y_o5][block0_x] , occupied[tmpblock2_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 0->3
                    tmpblock0_y_o5 = block2_y+1'd1;
                    tmpblock1_y_o5 = block2_y+2'd2;
                    tmpblock2_y_o5 = block2_y+2'd3;
                    if(| {occupied[tmpblock1_y_o5][block3_x],  occupied[tmpblock0_y_o5][block3_x], occupied[tmpblock1_y_o5][block2_x] , occupied[tmpblock2_y_o5][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end
            end
            2'd1:begin
                if(direction)begin // clockwise 1->2                 
                   
                    tmpblock0_x_o5= block1_x+1'd1;
                    tmpblock1_x_o5= block1_x-1'd1;
                    tmpblock0_y_o5= block0_y-1'd1;
                    // tmpblock1_y_o3= block3_y-2'd2;
                    if(| {occupied[tmpblock0_y_o3][tmpblock1_x_o3],  occupied[tmpblock0_y_o3][block1_x], occupied[block0_y][block1_x] , occupied[block0_y][tmpblock0_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 1->0
                    tmpblock0_x_o5= block1_x+1'd1;
                    tmpblock1_x_o5= block1_x-1'd1;
                    tmpblock0_y_o5= block0_y-1'd1;
                    tmpblock1_y_o5= block0_y-2'd2;
                    if(| {occupied[tmpblock1_y_o3][tmpblock1_x_o3],  occupied[tmpblock1_y_o3][block1_x], occupied[tmpblock0_y_o3][block1_x] , occupied[tmpblock0_y_o3][tmpblock0_x_o3]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            2'd2:begin
                if(direction)begin // clockwise 2->3                 
                   
                    tmpblock0_y_o5 = block1_y+2'd2;
                    tmpblock1_y_o5 = block1_y+1'd1;
                    tmpblock2_y_o5 = block1_y+2'd3;
                    if(| {occupied[tmpblock0_y_o5][block2_x],  occupied[tmpblock2_y_o5][block2_x], occupied[tmpblock0_y_o5][block0_x] , occupied[tmpblock1_y_o5][block0_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 2->1
                    tmpblock0_y_o5 = block1_y+2'd2;
                    tmpblock1_y_o5 = block1_y+1'd1;
                    // tmpblock2_y_o5 = block3_y-1'd1;
                    if(| {occupied[tmpblock0_y_o5][block3_x],  occupied[tmpblock1_y_o5][block3_x], occupied[block1_y][block2_x] , occupied[tmpblock1_y_o5][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            2'd3:begin
                if(direction)begin // clockwise 3->0                 
                   
                    tmpblock0_x_o5= block1_x+1'd1;
                    tmpblock1_x_o5= block1_x-1'd1;
                    tmpblock0_y_o5= block3_y-1'd1;
                    tmpblock1_y_o5= block3_y-2'd2;
                    if(| {occupied[tmpblock1_y_o5][tmpblock1_x_o5],  occupied[tmpblock1_y_o5][block1_x], occupied[tmpblock0_y_o5][block1_x] , occupied[tmpblock0_y_o5][tmpblock0_x_o5]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end else begin //counter clock-wise 3->2
                    tmpblock0_x_o5= block2_x-1'd1;
                    tmpblock1_x_o5= block2_x-2'd2;
                    tmpblock0_y_o5= block3_y-1'd1;
                    // tmpblock1_y_o3= block3_y-5'd2
                    if(| {occupied[tmpblock0_y_o5][tmpblock0_x_o5],  occupied[tmpblock0_y_o5][tmpblock1_x_o5], occupied[block3_y][tmpblock0_x_o5] , occupied[block3_y][block2_x]}   )
                        is_occupy_5 = 1;
                    else
                        is_occupy_5 = 0;
                end  
            end
            endcase
        end
        default: begin
           is_occupy_5 = 1;
        end
    endcase   
end

endmodule