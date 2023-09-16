/************************************************************************
 * Author        : Wen Chunyang
 * Email         : 1494640955@qq.com
 * Create time   : 2018-04-08 16:57
 * Last modified : 2018-04-08 16:57
 * Filename      : vga.v
 * Description   : 
 * *********************************************************************/
`include "global.sv"
module  vga(
        input clk,
        input rst_n,
        input [19:0] nexts1, nexts2,
        input [39:0] blocks1, blocks2, grays1, grays2,
        input [1:0] state_whole,
        input [23:0] player1_vga, player2_vga,
        input [3:0] tetris_type1, tetris_type2, tetris_hold1, tetris_hold2,
        output [3:0] x_number1, x_number2,
        output [4:0] y_number1, y_number2,
        output [9:0] x_img, y_img,
        input [23:0] pixel,
        input [27:0] cnt,
        input lose1, lose2,
        //vga
        output  reg   [7:0]   vga_r,
        output  reg   [7:0]   vga_g,
        output  reg   [7:0]   vga_b,
        output  wire vga_hs,
        output  wire vga_vs,
        output  wire vga_blank,
        output  wire vga_sync,
        output  wire vga_clk
);
//=====================================================================\
// ********** Define Parameter and Internal Signals *************
//=====================================================================/
//ADV7123 t输出延迟=t6+t8=7.5+15=22.5ns
// 640*480@60Hz fclk=25MHz,Tclk=40ns,20ns>7.5ns,所以数据不需要提前一个时钟输出,按正常时序即可
parameter   LinePeriod      =       800                         ;
parameter   H_SyncPulse     =       96                          ;
parameter   H_BackPorch     =       48                          ;
parameter   H_ActivePix     =       640                         ;
parameter   H_FrontPorch    =       16                          ;
parameter   Hde_start       =       H_SyncPulse + H_BackPorch   ;   // 144
parameter   Hde_end         =       Hde_start + H_ActivePix     ;   // 144 + 640

parameter   FramePeriod     =       525                         ;
parameter   V_SyncPulse     =       2                           ;
parameter   V_BackPorch     =       33                          ;
parameter   V_ActivePix     =       480                         ;
parameter   V_FrontPorch    =       10                          ;
parameter   Vde_start       =       V_SyncPulse + V_BackPorch   ; // 35
parameter   Vde_end         =       Vde_start + V_ActivePix     ; 

/*
// 1024*768@60Hz fclk=65MHz,Tclk=15.38ns,Tclk/2约等于7.5ns,所以数据要提前一个时钟输出,从而使数据对齐，具体是否需要提前移动一个时钟，还是以实际测试为准
parameter   LinePeriod      =       1344                        ;
parameter   H_SyncPulse     =       136                         ;
parameter   H_BackPorch     =       160                         ;
parameter   H_ActivePix     =       1024                        ;
parameter   H_FrontPorch    =       24                          ;
parameter   Hde_start       =       H_SyncPulse + H_BackPorch -1;//提前一个周期发送数据，从而使数据对齐 
parameter   Hde_end         =       Hde_start + H_ActivePix     ;//注意Hde_start已经提前了一个周期，所以这里就不能再减一了，否则就相当于减二了 
parameter   FramePeriod     =       806                         ;
parameter   V_SyncPulse     =       6                           ;
parameter   V_BackPorch     =       29                          ;
parameter   V_ActivePix     =       768                         ;
parameter   V_FrontPorch    =       3                           ;
parameter   Vde_start       =       V_SyncPulse + V_BackPorch   ; 
parameter   Vde_end         =       Vde_start + V_ActivePix     ; 
*/

parameter   Red_Wide        =       20                          ;
parameter   Green_block     =       100                         ;
reg hsync;
reg vsync;

reg [10: 0] h_cnt;
wire add_h_cnt;
wire end_h_cnt;
reg [ 9: 0] v_cnt;
wire add_v_cnt; 
wire end_v_cnt;
//wire red_area;
//wire green_area; 
//wire blue_area; 

//======================================================================
// ***************      Main    Code    ****************
//======================================================================
assign  vga_sync  = 1'b0;
assign  vga_blank = vga_hs & vga_vs;
assign  vga_hs    = hsync;
assign  vga_vs    = vsync;
assign  vga_clk   = ~clk;

always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        h_cnt <= 0;
    end
    else if(add_h_cnt)begin
        if(end_h_cnt)
            h_cnt <= 0;
        else
            h_cnt <= h_cnt + 1'b1;
    end
end

assign add_h_cnt= 1'b1;
assign end_h_cnt= add_h_cnt && h_cnt== LinePeriod-1;

always_ff @(posedge clk or negedge rst_n)begin 
    if(!rst_n)begin
        v_cnt <= 0;
    end
    else if(add_v_cnt)begin
        if(end_v_cnt)
            v_cnt <= 0;
        else
            v_cnt <= v_cnt + 1'b1;
    end
end

assign add_v_cnt = end_h_cnt;
assign end_v_cnt = add_v_cnt && v_cnt== FramePeriod-1;

//hsync
always_ff  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        hsync   <=      1'b0;
    end
    else if(add_h_cnt && h_cnt == H_SyncPulse-1)begin
        hsync   <=      1'b1;
    end
    else if(end_h_cnt)begin
        hsync   <=      1'b0;
    end
end

//vsync
always_ff  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        vsync <= 1'b0;
    end
    else if(add_v_cnt && v_cnt == V_SyncPulse-1)begin
        vsync <= 1'b1;
    end
    else if(end_v_cnt)begin
        vsync <= 1'b0;
    end
end



wire [4:0] block0_x1, block0_y1, block1_x1, block1_y1, block2_x1, block2_y1, block3_x1, block3_y1;
wire [4:0] block0_x2, block0_y2, block1_x2, block1_y2, block2_x2, block2_y2, block3_x2, block3_y2;
wire [4:0] gray0_x1,  gray0_y1,  gray1_x1,  gray1_y1,  gray2_x1,  gray2_y1,  gray3_x1,  gray3_y1;
wire [4:0] gray0_x2,  gray0_y2,  gray1_x2,  gray1_y2,  gray2_x2,  gray2_y2,  gray3_x2,  gray3_y2;
wire [3:0] next1 [0:5];
wire [3:0] next2 [0:5];
assign {next1[5], next1[4], next1[3], next1[2], next1[1]} = nexts1;
assign {next2[5], next2[4], next2[3], next2[2], next2[1]} = nexts2;
assign {gray0_x1, gray0_y1, gray1_x1, gray1_y1, gray2_x1, gray2_y1, gray3_x1, gray3_y1} = grays1;
assign {gray0_x2, gray0_y2, gray1_x2, gray1_y2, gray2_x2, gray2_y2, gray3_x2, gray3_y2} = grays2;
assign {block0_x1, block0_y1, block1_x1, block1_y1, block2_x1, block2_y1, block3_x1, block3_y1} = blocks1;
assign {block0_x2, block0_y2, block1_x2, block1_y2, block2_x2, block2_y2, block3_x2, block3_y2} = blocks2;
//wire [3:0] x_number; // 2 ~ 11
//wire [4:0] y_number; // 0 ~ 19
//wire valid_area, wall_area, buttom_area, dropping_area, placed_area, green_area, red_area;
//assign valid_area  = (h_cnt >= Hde_start - 1 && h_cnt < Hde_end - 1 && v_cnt >= Vde_start && v_cnt < Vde_end);//v_cnt是多周期的，所以不用提前
//assign wall_area   = (state_whole == `PLAY) && ((h_cnt >= Hde_start - 1 + 80 && h_cnt < Hde_start - 1 + 96) || (h_cnt >= Hde_start - 1 + 96 + 160 && h_cnt < Hde_start - 1 + 272)) && (v_cnt >= Vde_start + 80 && v_cnt < Vde_start + 80 + 320);
//assign buttom_area = (state_whole == `PLAY) && (h_cnt >= Hde_start - 1 + 80 && h_cnt < Hde_start - 1 + 96 + 176 && v_cnt >= Vde_start + 400 && v_cnt < Vde_start + 400 + 16);
//assign placed_area = (state_whole == `PLAY) && (h_cnt >= Hde_start - 1 + 96) && (h_cnt < Hde_start - 1 + 96 + 160) && (v_cnt >= Vde_start + 80) && (v_cnt < Vde_start + 80 + 320);
//assign dropping_area = (state_whole == `PLAY) && ((x_number == block0_x && y_number == block0_y) || (x_number == block1_x && y_number == block1_y) ||(x_number == block2_x && y_number == block2_y) ||(x_number == block3_x && y_number == block3_y));
parameter a = 4'd8;
parameter b = 16*3;
parameter c = 16*10;
parameter d = 80;
parameter f = 16*20;
parameter g = 16*15;
parameter h = 16;
parameter i = 10;
parameter j = 11;
parameter k = 5;

reg green_area;
wire valid_area, wall_area, buttom_area, wall_area2, dropping_area2, placed_area1, placed_area2, red_area, dropping_area1, gray_area1, gray_area2, hold_area1;
wire hold_up, hold_left, hold_down, buttom_area2, next_up, next_down, next_right;
wire hold_S,  hold_J,  hold_O,  hold_Z,  hold_I,  hold_L,  hold_T;
wire hold_S2, hold_J2, hold_O2, hold_Z2, hold_I2, hold_L2, hold_T2;

wire next1_Z, next2_Z, next3_Z, next4_Z, next5_Z;
wire next1_Z2, next2_Z2, next3_Z2, next4_Z2, next5_Z2;

wire next1_L, next2_L, next3_L, next4_L, next5_L;
wire next1_L2, next2_L2, next3_L2, next4_L2, next5_L2;

wire next1_O, next2_O, next3_O, next4_O, next5_O;
wire next1_O2, next2_O2, next3_O2, next4_O2, next5_O2;

wire next1_S, next2_S, next3_S, next4_S, next5_S;
wire next1_S2, next2_S2, next3_S2, next4_S2, next5_S2;

wire next1_I, next2_I, next3_I, next4_I, next5_I;
wire next1_I2, next2_I2, next3_I2, next4_I2, next5_I2;

wire next1_J, next2_J, next3_J, next4_J, next5_J;
wire next1_J2, next2_J2, next3_J2, next4_J2, next5_J2;

wire next1_T, next2_T, next3_T, next4_T, next5_T;
wire next1_T2, next2_T2, next3_T2, next4_T2, next5_T2;

wire LOSE_L, LOSE_O, LOSE_S, LOSE_E, LOSE_p;  // LOSE_p is "!"
wire LOSE_L2, LOSE_O2, LOSE_S2, LOSE_E2, LOSE_p2; 


assign x_img = (h_cnt - Hde_start) >> 2;
assign y_img = (v_cnt - Vde_start) >> 2;

assign valid_area  = (h_cnt >= Hde_start - 1 && h_cnt < Hde_end - 1 && v_cnt >= Vde_start && v_cnt < Vde_end);//v_cnt是多周期的，所以不用提前

assign wall_area      = (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + (h+a+b) && h_cnt < Hde_start - 1 + (h+a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a))) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f); // left & right wall
assign wall_area2     = (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c+a))) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f); // left & right wall
assign buttom_area    = (state_whole == `PLAY || state_whole == `ENDS) && (h_cnt >= Hde_start - 1 + (h+a+b) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a) && v_cnt >= Vde_start + (d+f) && v_cnt < Vde_start + (d+f) + a);  // bottom wall
assign buttom_area2   = (state_whole == `PLAY || state_whole == `ENDS) && (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c+a) && v_cnt >= Vde_start + (d+f) && v_cnt < Vde_start + (d+f) + a);  // bottom wall

assign placed_area1   = (state_whole == `PLAY || state_whole == `ENDS) && (h_cnt >= Hde_start - 1 + (h+a+b+a)) && (h_cnt < Hde_start - 1 + (h+a+b+a+c)) && (v_cnt >= Vde_start + (d)) && (v_cnt < Vde_start + (d+f));
assign placed_area2   = (state_whole == `PLAY || state_whole == `ENDS) && (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a)) && (h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a+c)) && (v_cnt >= Vde_start + (d)) && (v_cnt < Vde_start + (d+f));
assign dropping_area1 = (state_whole == `PLAY || state_whole == `ENDS) && ((x_number1 == block0_x1 && y_number1 == block0_y1) || (x_number1 == block1_x1 && y_number1 == block1_y1) ||(x_number1 == block2_x1 && y_number1 == block2_y1) ||(x_number1 == block3_x1 && y_number1 == block3_y1));
assign dropping_area2 = (state_whole == `PLAY || state_whole == `ENDS) && ((x_number2 == block0_x2 && y_number2 == block0_y2) || (x_number2 == block1_x2 && y_number2 == block1_y2) ||(x_number2 == block2_x2 && y_number2 == block2_y2) ||(x_number2 == block3_x2 && y_number2 == block3_y2));
assign gray_area1     = (state_whole == `PLAY || state_whole == `ENDS) && ((x_number1 == gray0_x1  && y_number1 == gray0_y1)  || (x_number1 == gray1_x1 && y_number1 == gray1_y1) ||(x_number1 == gray2_x1 && y_number1 == gray2_y1) ||(x_number1 == gray3_x1 && y_number1 == gray3_y1));
assign gray_area2     = (state_whole == `PLAY || state_whole == `ENDS) && ((x_number2 == gray0_x2  && y_number2 == gray0_y2)  || (x_number2 == gray1_x2 && y_number2 == gray1_y2) ||(x_number2 == gray2_x2 && y_number2 == gray2_y2) ||(x_number2 == gray3_x2 && y_number2 == gray3_y2));
//assign hold_area1     = (state_whole == `PLAY) && ((h_cnt >= Hde_start - 1 + (h+a+(b>>2))) && (h_cnt < Hde_start - 1 + (h+a+(b>>2)*3)) && (v_cnt >= Vde_start+(d+a+(b>>2)) && (v_cnt < Vde_start + (d+a+(b>>2)*3))));


assign hold_up    =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + h && h_cnt < Hde_start - 1 + h + (a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a))&&(h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a))) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + a);
assign hold_down  =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + h && h_cnt < Hde_start - 1 + h + (a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a))&&(h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a))) && (v_cnt >= Vde_start + d + (a+b) && v_cnt < Vde_start + d + (a+b+a));
assign hold_left  =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + h && h_cnt < Hde_start - 1 + h + a) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + a)) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + (a+b+a));

assign next_up    =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + (h+a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c+a+b+a))) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + a);
assign next_down  =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + (h+a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c+a+b+a))) && (v_cnt >= Vde_start + d + (a+g) && v_cnt < Vde_start + d + (a+g+a));
assign next_right =  (state_whole == `PLAY || state_whole == `ENDS) && ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a)) || (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a) +(a+b+a+c+a+b)) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a) + (a+b+a+c+a+b+a)) && (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + (a+g+a));

//assign x_number1 = (h_cnt >= Hde_start - 1 + (h+a+b+a) && h_cnt < Hde_start - 1 + (h+a+b+a+c)) ? ((h_cnt - Hde_start - (h+a+b+a)) >> 4) + 2 : 4'd15;
assign x_number1 = (h_cnt >= Hde_start + (h+a+b+a) && h_cnt < Hde_start - 1 + (h+a+b+a+c)) ? ((h_cnt - Hde_start - (h+a+b+a)) >> 4) + 2 : 4'd15;

assign y_number1 = (v_cnt >= Vde_start + (d) && v_cnt < Vde_start + (d+f)) ? (v_cnt - Vde_start - (d)) >> 4 : 5'd25;

//assign x_number2 = (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a+c)) ? ((h_cnt - Hde_start - (h+a+b+a+c+a+b+a+a+b+a)) >> 4) + 2 : 4'd15;
assign x_number2 = (h_cnt >= Hde_start + (h+a+b+a+c+a+b+a+a+b+a) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a+c)) ? ((h_cnt - Hde_start - (h+a+b+a+c+a+b+a+a+b+a)) >> 4) + 2 : 4'd15;

assign y_number2 = (v_cnt >= Vde_start + (d) && v_cnt < Vde_start + (d+f)) ? (v_cnt - Vde_start - (d)) >> 4 : 5'd25;

assign hold_S = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 +h+a+24+4) && (v_cnt >= Vde_start + d + a + 24 && v_cnt < Vde_start + d + a  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-4 && h_cnt < Hde_start - 1 +h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24 ))); 

assign hold_J = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 + h+a+24-4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 + h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_O = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24-8 && h_cnt < Hde_start - 1 + h+a+24+8) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-8 && h_cnt < Hde_start - 1 + h+a+24+8) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_Z = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 + h+a+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-4 && h_cnt < Hde_start - 1 + h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_I = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + h+a+24-16 && h_cnt < Hde_start - 1 + h+a+24+16) && (v_cnt >= Vde_start + d + a  + 24 - 4 && v_cnt < Vde_start + d + a  + 24 + 4));
assign hold_L = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24+4 && h_cnt < Hde_start - 1 + h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 + h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_T = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold1 == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + h+a+24-4 && h_cnt < Hde_start - 1 + h+a+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + h+a+24-12 && h_cnt < Hde_start - 1 + h+a+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 

assign hold_S2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24+4) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + 312+24-4 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24 ))); 

assign hold_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24-4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24-8 && h_cnt < Hde_start - 1 +312+24+8) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + 312+24-8 && h_cnt < Hde_start - 1 +312+24+8) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + 312+24-4 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + 312+24-16 && h_cnt < Hde_start - 1 +312+24+16) && (v_cnt >= Vde_start + d + a  + 24 - 4 && v_cnt < Vde_start + d + a  + 24 + 4));
assign hold_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24+4 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign hold_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (tetris_hold2 == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + 312+24-4 && h_cnt < Hde_start - 1 +312+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + 312+24-12 && h_cnt < Hde_start - 1 +312+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 

assign next1_Z = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_Z = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 - a && v_cnt < Vde_start + (d+a+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a))); 
assign next3_Z = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a))); 
assign next4_Z = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a))); 
assign next5_Z = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a))); 

assign next1_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 - a && v_cnt < Vde_start + (d+a+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a))); 
assign next3_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a))); 
assign next4_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a))); 
assign next5_Z2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `Z_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a)));



assign next1_L = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_L = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a))); 
assign next3_L = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a))); 
assign next4_L = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a))); 
assign next5_L = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a))); 

assign next1_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a))); 
assign next3_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a))); 
assign next4_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a))); 
assign next5_L2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `L_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24+4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a))); 




assign next1_O = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_O = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a))); 
assign next3_O = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a))); 
assign next4_O = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a))); 
assign next5_O = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a))); 

assign next1_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a))); 
assign next3_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a))); 
assign next4_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a))); 
assign next5_O2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `O_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-8 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+8) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a))); 


assign next1_S = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 +(h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a + 24 && v_cnt < Vde_start + d + a  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 +(h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24 )));
assign next2_S =(state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 +(h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24 )));
assign next3_S =(state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1+ (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24 )));
assign next4_S =(state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1+(h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24 )));
assign next5_S =(state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 +(h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 )));

assign next1_S2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a + 24 && v_cnt < Vde_start + d + a  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24 )));
assign next2_S2 =(state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 +(312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24 )));
assign next3_S2 =(state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b)  + 24 )));
assign next4_S2 =(state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 +(312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 +(312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b)  + 24 )));
assign next5_S2 =(state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `S_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 + a)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1+ (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b)  + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b)  + 24 )));



assign next1_I = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+16) && (v_cnt >= Vde_start + d + a  + 24 - 4 && v_cnt < Vde_start + d + a  + 24 + 4));
assign next2_I = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b)  + 24 - 4 && v_cnt < Vde_start + (d+a+b)  + 24 + 4));
assign next3_I = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - 4 && v_cnt < Vde_start + (d+a+b+b)  + 24 + 4));
assign next4_I = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - 4 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + 4));
assign next5_I = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - 4 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + 4));

assign next1_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+16) && (v_cnt >= Vde_start + d + a  + 24 - 4 && v_cnt < Vde_start + d + a  + 24 + 4));
assign next2_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b)  + 24 - 4 && v_cnt < Vde_start + (d+a+b)  + 24 + 4));
assign next3_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b)  + 24 - 4 && v_cnt < Vde_start + (d+a+b+b)  + 24 + 4));
assign next4_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - 4 && v_cnt < Vde_start + (d+a+b+b+b)  + 24 + 4));
assign next5_I2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `I_BLOCK) &&
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-16 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+16) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - 4 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + 4));



assign next1_J = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24-4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_J = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a)));
assign next3_J = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a)));
assign next4_J = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a)));
assign next5_J = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a)));

assign next1_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24-4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a))); 
assign next2_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b)  + 24 - a && v_cnt < Vde_start + (d+a+b)  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b)  + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a)));
assign next3_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a)));
assign next4_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a)));
assign next5_J2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `J_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24-4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a)));



assign next1_T = (state_whole == `PLAY || state_whole == `ENDS) && (next1[1] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a)));
assign next2_T = (state_whole == `PLAY || state_whole == `ENDS) && (next1[2] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 - a && v_cnt < Vde_start + (d+a+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a)));
assign next3_T = (state_whole == `PLAY || state_whole == `ENDS) && (next1[3] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a)));
assign next4_T = (state_whole == `PLAY || state_whole == `ENDS) && (next1[4] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a)));
assign next5_T = (state_whole == `PLAY || state_whole == `ENDS) && (next1[5] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a)));

assign next1_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[1] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + d + a  + 24 - a && v_cnt < Vde_start + d + a  + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + d + a  + 24 && v_cnt < Vde_start + d + a  + 24 + a)));
assign next2_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[2] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b) + 24 - a && v_cnt < Vde_start + (d+a+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b) + 24 && v_cnt < Vde_start + (d+a+b) + 24 + a)));
assign next3_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[3] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b) + 24 + a)));
assign next4_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[4] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b) + 24 + a)));
assign next5_T2 = (state_whole == `PLAY || state_whole == `ENDS) && (next2[5] == `T_BLOCK) &&
					(((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-4 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+4) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 - a && v_cnt < Vde_start + (d+a+b+b+b+b) + 24)) ||
					((h_cnt >= Hde_start - 1 + (312+b+a+c+a)+24-12 && h_cnt < Hde_start - 1 + (312+b+a+c+a)+24+12) && (v_cnt >= Vde_start + (d+a+b+b+b+b) + 24 && v_cnt < Vde_start + (d+a+b+b+b+b) + 24 + a)));

assign LOSE_L = (state_whole == `ENDS) && (lose1) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i+i+k+k) - (i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i+i+k+k)  && (v_cnt >= Vde_start + (d+f+a) + j +(i+i+i+i) && v_cnt < Vde_start + (d+f+a) + j +(i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i+i+k+k) - (i+i+i+i)&& h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i+i+k+k) - (i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + j +(i+i+i+i+i) ))));
assign LOSE_O = (state_whole == `ENDS) && (lose1) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - (k+i)) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start +  (d+f+a) + j + i)) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - (k+i)) && (v_cnt >= Vde_start + (d+f+a) + j +(i+i+i+i)&& v_cnt < Vde_start +  (d+f+a) + j +(i+i+i+i) + i)) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - (k+i+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i) +(i+i+i) )) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 - k) && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i) +(i+i+i) )));
assign LOSE_S = (state_whole == `ENDS) && (lose1) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + j + i)) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + k && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i)  && (v_cnt >= Vde_start + (d+f+a) + j + i && v_cnt < Vde_start + (d+f+a) + j + (i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i) && v_cnt < Vde_start +  (d+f+a) + j + (i+i+i))) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i+i) && v_cnt < Vde_start + (d+f+a) + j + (i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + k && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i+i+i) && v_cnt < Vde_start + (d+f+a) + j + (i+i+i+i+i) )) ));
assign LOSE_E = (state_whole == `ENDS) && (lose1) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + i && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ) )
           );
assign LOSE_p = (state_whole == `ENDS) && (lose1) &&
            ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i+k+k) + i) && ((v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i)) || (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i))));


assign LOSE_L2 = (state_whole == `ENDS) && (lose2) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i+i+k+k)  - (i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i+i+k+k) && (v_cnt >= Vde_start + (d+f+a) + j +(i+i+i+i) && v_cnt < Vde_start + (d+f+a) + j +(i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i+i+k+k) - (i+i+i+i)&& h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i+i+k+k) - (i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + j +(i+i+i+i+i) ))));
assign LOSE_O2 = (state_whole == `ENDS) && (lose2) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i)) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start +  (d+f+a) + j + i)) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i)) && (v_cnt >= Vde_start + (d+f+a) + j +(i+i+i+i)&& v_cnt < Vde_start + (d+f+a) + j +(i+i+i+i) + i)) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i) +(i+i+i) )) || 
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - k) && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i) +(i+i+i) )));
assign LOSE_S2 = (state_whole == `ENDS) && (lose2) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + j + i)) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + k && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i)  && (v_cnt >= Vde_start + (d+f+a) + j + i && v_cnt < Vde_start + (d+f+a) + j + (i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i) && v_cnt < Vde_start +  (d+f+a) + j + (i+i+i))) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i+i) && v_cnt < Vde_start + (d+f+a) + j + (i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + k && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j + (i+i+i+i) && v_cnt < Vde_start + (d+f+a) + j + (i+i+i+i+i) )) ));
assign LOSE_E2 = (state_whole == `ENDS) && (lose2) &&
          ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           (h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + i && (v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ) )
           );
assign LOSE_p2 = (state_whole == `ENDS) && (lose2) &&
            ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + (k+i+i+i+i+k+k) + (i+i+i+i+k+k) + i) && ((v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i)) || (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i))));

assign WIN_W = (state_whole == `ENDS) && (lose2) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 -5 - (i+k+k) )&& (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i) ) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i) )&& (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start +  (d+f+a) + (j+i+i+i))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i+i) )&& (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 -5 -(i+k+k+i+i+i+i) ) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) 
           );

assign WIN_I = (state_whole == `ENDS) && (lose2) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - 5 - i && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + 5 + i) && ((v_cnt >= Vde_start + (d+f+a) +j  && v_cnt < Vde_start + (d+f+a) + (j+i))||(v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 - 5 && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + 5 ) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ))
           );

assign WIN_N = (state_whole == `ENDS) && (lose2) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 +5 +(i+k+k+i)) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 +5 +(i+k+k+i+i))  && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 +5 +(i+k+k+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start +  (d+f+a) + (j+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 +5 +(i+k+k+i+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a) + 80 +5 +(i+k+k+i+i+i+i+i))  && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) 
           );

assign WIN_p = (state_whole == `ENDS) && (lose2) &&
            ((h_cnt >= Hde_start - 1 + (h+a+b+a) + 80 + 5 +(i+k+k+i+i+i+i+i+k)&& h_cnt < Hde_start - 1 + (h+a+b+a) + 80 + + 5 +(i+k+k+i+i+i+i+i+k+i)) && ((v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i)) || (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i))));


assign WIN_W2 = (state_whole == `ENDS) && (lose1) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 - (i+k+k) )&& (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i) ) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i) )&& (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start +  (d+f+a) + (j+i+i+i))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i+i) )&& (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 -5 -(i+k+k+i+i+i+i) ) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) 
           );

assign WIN_I2 = (state_whole == `ENDS) && (lose1) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - 5 - i && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 + i) && ((v_cnt >= Vde_start + (d+f+a) +j  && v_cnt < Vde_start + (d+f+a) + (j+i))||(v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ))) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 - 5 && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 ) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) ))
           );

assign WIN_N2 = (state_whole == `ENDS) && (lose1) &&
          (((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 +5 +(i+k+k+i)) && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 +5 +(i+k+k+i+i))  && (v_cnt >= Vde_start + (d+f+a) + (j+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 +5 +(i+k+k+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i) && v_cnt < Vde_start +  (d+f+a) + (j+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 +5 +(i+k+k+i+i+i+i)) && (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i) )) ||
           ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i+i+i+i) && h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 +5 +(i+k+k+i+i+i+i+i))  && (v_cnt >= Vde_start + (d+f+a) + j  && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i) )) 
           );

assign WIN_p2 = (state_whole == `ENDS) && (lose1) &&
            ((h_cnt >= Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i+i+i+i+i+k)&& h_cnt < Hde_start - 1 + (h+a+b+a+c+a+b+a+a+b+a) + 80 + 5 +(i+k+k+i+i+i+i+i+k+i)) && ((v_cnt >= Vde_start + (d+f+a) + j && v_cnt < Vde_start + (d+f+a) + (j+i+i+i)) || (v_cnt >= Vde_start + (d+f+a) + (j+i+i+i+i) && v_cnt < Vde_start + (d+f+a) + (j+i+i+i+i+i))));


wire start_s, start_t1, start_a, start_r, start_t2, start_p;

assign start_s = (state_whole == `IDLE) &&
                (((h_cnt >= Hde_start - 1 + 160 && h_cnt < Hde_start -1 + 190) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210))||
                 ((h_cnt >= Hde_start - 1 + 150 && h_cnt < Hde_start -1 + 160) && (v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 230))||
                 ((h_cnt >= Hde_start - 1 + 160 && h_cnt < Hde_start -1 + 180) && (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 250))||
                 ((h_cnt >= Hde_start - 1 + 180 && h_cnt < Hde_start -1 + 190) && (v_cnt >= Vde_start + 250 && v_cnt < Vde_start + 270))||
                 ((h_cnt >= Hde_start - 1 + 150 && h_cnt < Hde_start -1 + 180) && (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290))
                );

assign start_t1 = (state_whole == `IDLE) &&
                (((h_cnt >= Hde_start - 1 + 210 && h_cnt <= Hde_start - 1 + 250) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210)) || 
                 ((h_cnt >= Hde_start - 1 + 225 && h_cnt <= Hde_start - 1 + 235) && v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 290)
                );

assign start_a = (state_whole == `IDLE) &&
                (((h_cnt >= Hde_start - 1 + 270 && h_cnt < Hde_start -1 + 280) || (h_cnt >= Hde_start - 1 + 300 && h_cnt < Hde_start -1 + 310)) && (v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 290) ||
                 (h_cnt >= Hde_start - 1 + 280 && h_cnt < Hde_start -1 + 300) && ((v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210) || (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 250))
                );
                
assign start_r = (state_whole == `IDLE) &&
                (((h_cnt >= Hde_start - 1 + 330 && h_cnt < Hde_start -1 + 360) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210))||
                 (((h_cnt >= Hde_start - 1 + 330 && h_cnt < Hde_start -1 + 340)||(h_cnt >= Hde_start - 1 + 360 && h_cnt < Hde_start -1 + 370)) && (v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 230))||
                 ((h_cnt >= Hde_start - 1 + 330 && h_cnt < Hde_start -1 + 360) && (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 250))||
                 (((h_cnt >= Hde_start - 1 + 330 && h_cnt < Hde_start -1 + 340)||(h_cnt >= Hde_start - 1 + 350 && h_cnt < Hde_start -1 + 360)) && (v_cnt >= Vde_start + 250 && v_cnt < Vde_start + 270))||
                 (((h_cnt >= Hde_start - 1 + 330 && h_cnt < Hde_start -1 + 340)||(h_cnt >= Hde_start - 1 + 360 && h_cnt < Hde_start -1 + 370)) && (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290))
                );
                
assign start_t2 = (state_whole == `IDLE) &&
                (((h_cnt >= Hde_start - 1 + 390 && h_cnt <= Hde_start - 1 + 430) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210)) || 
                 ((h_cnt >= Hde_start - 1 + 405 && h_cnt <= Hde_start - 1 + 415) && (v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 290))
                );

assign start_p = (state_whole == `IDLE) &&
                ((h_cnt >= Hde_start - 1 + 465 && h_cnt <= Hde_start - 1 + 475) && ((v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 250) || (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290))
                );
wire line1_1, line_1_2, line1_3, line1_4, line1_5, line1_6, line1_7, line1_8, line1_9;
wire line2_1, line_2_2, line2_3, line2_4, line2_5, line2_6, line2_7, line2_8, line2_9;

assign line1_1 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 16)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_2 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 32)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_3 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 48)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_4 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 64)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_5 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 80)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_6 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 96)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_7 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 112)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_8 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 128)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line1_9 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (h+a+b+a) + 144)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));

assign line2_1 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 16)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_2 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 32)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_3 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 48)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_4 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 64)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_5 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 80)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_6 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 96)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_7 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 112)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_8 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 128)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
assign line2_9 = (state_whole == `PLAY || state_whole == `ENDS)&&
					((h_cnt == Hde_start - 1 + (312+b+a) + 144)&& (v_cnt >= Vde_start + d && v_cnt < Vde_start + d + f));
always @(*) begin
    if(cnt > 28'd100_000_000) begin
        green_area = (state_whole == `CTWN) && 
                    ((h_cnt >= Hde_start - 1 + 310 && h_cnt < Hde_start - 1 + 330) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 290) || 
                     (h_cnt >= Hde_start - 1 + 290 && h_cnt < Hde_start - 1 + 330) && (v_cnt >= Vde_start + 210 && v_cnt < Vde_start + 230) || 
                     (h_cnt >= Hde_start - 1 + 290 && h_cnt < Hde_start - 1 + 350) && (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290)
                    );
    end
    else if(cnt > 28'd50_000_000) begin
        green_area = (state_whole == `CTWN) && 
                    ((h_cnt >= Hde_start - 1 + 280 && h_cnt < Hde_start - 1 + 360) && ((v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210) || (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 250) || (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290)) || 
                     (h_cnt >= Hde_start - 1 + 340 && h_cnt < Hde_start - 1 + 360) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 250) || 
                     (h_cnt >= Hde_start - 1 + 280 && h_cnt < Hde_start - 1 + 300) && (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 290)
                    );
    end
    else if (cnt > 28'd0) begin
        green_area = (state_whole == `CTWN) && 
                    ((h_cnt >= Hde_start - 1 + 280 && h_cnt < Hde_start - 1 + 360) && ((v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 210) || (v_cnt >= Vde_start + 230 && v_cnt < Vde_start + 250) || (v_cnt >= Vde_start + 270 && v_cnt < Vde_start + 290)) || 
                     (h_cnt >= Hde_start - 1 + 340 && h_cnt < Hde_start - 1 + 360) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 290)
                    );
    end 
    else green_area = 0;
end

//assign red_area = (state_whole == `IDLE) && (h_cnt >= Hde_start - 1 && h_cnt < Hde_end - 1) && (v_cnt >= Vde_start && v_cnt < Vde_end);
//assign  red_area    =   (state_whole == `IDLE) && ((h_cnt >= Hde_start -1 && h_cnt < Hde_start - 1 + Red_Wide) || (h_cnt >= Hde_end - 1 - 20 && h_cnt < Hde_end - 1) || (v_cnt >= Vde_start && v_cnt < Vde_start + Red_Wide) || (v_cnt >= Vde_end - 20 && v_cnt < Vde_end));
//assign  green_area  =   (state_whole == `CTWN) && (h_cnt >= Hde_start - 1 + 270 && h_cnt < Hde_start - 1 + 370) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 290);

//assign x_number = (h_cnt >= Hde_start - 1 + 96 && h_cnt < Hde_start - 1 + 96 + 160) ? ((h_cnt - Hde_start - 96) >> 4) + 2 : 4'd15;
//assign y_number = (v_cnt >= Vde_start + 80 && v_cnt < Vde_start + 80 + 320) ? (v_cnt - Vde_start - 80) >> 4 : 5'd25;
//
//assign  red_area    =   (state_whole == `IDLE) && ((h_cnt >= Hde_start -1 && h_cnt < Hde_start - 1 + Red_Wide) || (h_cnt >= Hde_end - 1 - 20 && h_cnt < Hde_end - 1) || (v_cnt >= Vde_start && v_cnt < Vde_start + Red_Wide) || (v_cnt >= Vde_end - 20 && v_cnt < Vde_end));
//assign  green_area  =   (state_whole == `CTWN) && (h_cnt >= Hde_start - 1 + 270 && h_cnt < Hde_start -1 + 370) && (v_cnt >= Vde_start + 190 && v_cnt < Vde_start + 290);

always_ff  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        vga_r <= 8'h0;
        vga_g <= 8'h0;
        vga_b <= 8'h0;
    end
    else if(valid_area)
         /*if(red_area)begin
            {vga_r, vga_g, vga_b} <= pixel;
        end*/
        if(green_area)begin
            vga_r <= 8'h0;
            vga_g <= 8'hff;
            vga_b <= 8'h0;
        end
        else if (wall_area || buttom_area || wall_area2 || buttom_area2 || hold_up || hold_down || hold_left || next_up || next_down || next_right) begin
            vga_r <= 8'hff;
            vga_g <= 8'hff;
            vga_b <= 8'hff;
        end
        else if (dropping_area1) begin
            case (tetris_type1)
                `NON:     {vga_r, vga_g, vga_b} <= 24'h000000;
                `Z_BLOCK: {vga_r, vga_g, vga_b} <= `RED;
                `L_BLOCK: {vga_r, vga_g, vga_b} <= `ORANGE;
                `O_BLOCK: {vga_r, vga_g, vga_b} <= `YELLOW;
                `S_BLOCK: {vga_r, vga_g, vga_b} <= `LIME;
                `I_BLOCK: {vga_r, vga_g, vga_b} <= `CYAN;
                `J_BLOCK: {vga_r, vga_g, vga_b} <= `BLUE;
                `T_BLOCK: {vga_r, vga_g, vga_b} <= `PURPLE;
                `GRAY:    {vga_r, vga_g, vga_b} <= `GREY;
                default:  {vga_r, vga_g, vga_b} <= 24'b0;
            endcase
        end 
        else if (dropping_area2) begin
            case (tetris_type2)
                `NON:     {vga_r, vga_g, vga_b} <= 24'h000000;
                `Z_BLOCK: {vga_r, vga_g, vga_b} <= `RED;
                `L_BLOCK: {vga_r, vga_g, vga_b} <= `ORANGE;
                `O_BLOCK: {vga_r, vga_g, vga_b} <= `YELLOW;
                `S_BLOCK: {vga_r, vga_g, vga_b} <= `LIME;
                `I_BLOCK: {vga_r, vga_g, vga_b} <= `CYAN;
                `J_BLOCK: {vga_r, vga_g, vga_b} <= `BLUE;
                `T_BLOCK: {vga_r, vga_g, vga_b} <= `PURPLE;
                `GRAY:    {vga_r, vga_g, vga_b} <= `GREY;
                default:  {vga_r, vga_g, vga_b} <= 24'b0;
            endcase
        end
        else if (gray_area1 || gray_area2) begin
            {vga_r, vga_g, vga_b} <= `GREY;
        end

        else if (start_s) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (start_t1) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (start_a) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (start_r) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (start_t2) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (start_p) {vga_r, vga_g, vga_b} <= `WHITE;
        else if (hold_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (hold_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (hold_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (hold_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (hold_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (hold_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (hold_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (hold_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (hold_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (hold_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (hold_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (hold_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (hold_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (hold_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next1_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (next2_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (next3_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (next4_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (next5_Z) {vga_r, vga_g, vga_b} <= `RED;
        else if (next1_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next2_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next3_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next4_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next5_L) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next1_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next2_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next3_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next4_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next5_O) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next1_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next2_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next3_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next4_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next5_S) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next1_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next2_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next3_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next4_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next5_I) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next1_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next2_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next3_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next4_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next5_J) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next1_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next2_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next3_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next4_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next5_T) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next1_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (next2_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (next3_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (next4_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (next5_Z2) {vga_r, vga_g, vga_b} <= `RED;
        else if (next1_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next2_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next3_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next4_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next5_L2) {vga_r, vga_g, vga_b} <= `ORANGE;
        else if (next1_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next2_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next3_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next4_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next5_O2) {vga_r, vga_g, vga_b} <= `YELLOW;
        else if (next1_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next2_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next3_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next4_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next5_S2) {vga_r, vga_g, vga_b} <= `LIME;
        else if (next1_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next2_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next3_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next4_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next5_I2) {vga_r, vga_g, vga_b} <= `CYAN;
        else if (next1_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next2_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next3_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next4_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next5_J2) {vga_r, vga_g, vga_b} <= `BLUE;
        else if (next1_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next2_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next3_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next4_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (next5_T2) {vga_r, vga_g, vga_b} <= `PURPLE;
        else if (LOSE_L)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_O)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_S)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_E)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_p)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_L2)  {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_O2)  {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_S2)  {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_E2)  {vga_r, vga_g, vga_b} <= `WHITE;
        else if (LOSE_p2)  {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_W)    {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_I)    {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_N)    {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_p)    {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_W2)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_I2)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_N2)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (WIN_p2)   {vga_r, vga_g, vga_b} <= `WHITE;
        else if (line1_1)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_2)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_3)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_4)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_5)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_6)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_7)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_8)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line1_9)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_1)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_2)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_3)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_4)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_5)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_6)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_7)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_8)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (line2_9)  {vga_r, vga_g, vga_b} <= 8'hA9A9A9;
        else if (placed_area1) begin
            {vga_r, vga_g, vga_b} <= player1_vga;
        end
        else if (placed_area2) begin
            {vga_r, vga_g, vga_b} <= player2_vga;
        end
        else begin
            vga_r <= 8'h00;
            vga_g <= 8'h00;
            vga_b <= 8'h00;
        end
    else begin
            vga_r <= 8'h00;
            vga_g <= 8'h00;
            vga_b <= 8'h00;
    end
end

endmodule