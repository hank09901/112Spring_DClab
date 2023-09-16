module DE2_115 (
	// clock
	input CLOCK_50,

	// VGA
	output [7:0] VGA_R,	
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output VGA_HS,
	output VGA_VS,
	output VGA_BLANK_N,
	output VGA_CLK,
	output VGA_SYNC_N,

	// four bottom
	input [3:0] KEY,

	// PS2
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,

	// audio
	/*
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
*/


	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	//output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,

	//input [17:0] SW
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7

	// LCD
	/*output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW*/
	/*
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO*/
);


// KEY[0]: reset; KEY[1]: start; KEY[2]: left




wire keystart;
wire clk_25m, clk_65m, rst_vga_n;
wire lose1, lose2;
wire [2:0] lines1, lines2;
wire [23:0] pixel;
wire [ 1:0] state_whole;
wire [ 9:0] x_img, y_img;
wire [19:0] nexts1, nexts2;
wire [ 7:0] key_data, key_data2;
wire [ 4:0] ctr_elim1, ctr_elim2;
wire [ 3:0] x_number1, x_number2;
wire [ 4:0] y_number1, y_number2;
wire [ 2:0] state_Game1, state_Game2;
wire [23:0] player1_vga, player2_vga;
wire [39:0] blocks1, blocks2, grays1, grays2;
wire [3:0] tetris_type1, tetris_type2, tetris_hold1, tetris_hold2;
wire gamestart;
wire [27:0] cnt;
reg [4:0] attack1, attack2, attack1_next, attack2_next; // attack1: attack arise by player1
wire [2:0] move_speed1, move_speed2;

/************************ keyboard****************************/
keyboard ps2_keyboard1 ( .clk(CLOCK_50), .rst(KEY[0]), .ps2_data (PS2_DAT),  .ps2_clk (PS2_CLK),   .led_g(key_data), .speed(keyplayer1), .move_speed(move_speed1));
keyboard ps2_keyboard2 ( .clk(CLOCK_50), .rst(KEY[0]), .ps2_data (PS2_DAT2), .ps2_clk (PS2_CLK2),  .led_g(key_data2), .speed(keyplayer2), .move_speed(move_speed2));
AttackDisplay decoder1 (.value(attack1), .tens(HEX1), .digits(HEX0));
AttackDisplay decoder2 (.value(attack2), .tens(HEX5), .digits(HEX4));
SpeedDisplay  decoder3 (.value(move_speed1), .digits(HEX7));
SpeedDisplay  decoder4 (.value(move_speed2), .digits(HEX3));

// bottom debouncer
Debounce deb0 (.i_in(KEY[1]), .i_rst_n(KEY[0]), .i_clk(CLOCK_50), .o_neg(keystart));
Debounce deb1 (.i_in(KEY[2]), .i_rst_n(KEY[0]), .i_clk(CLOCK_50), .o_neg(keyplayer1));
Debounce deb2 (.i_in(KEY[3]), .i_rst_n(KEY[0]), .i_clk(CLOCK_50), .o_neg(keyplayer2));


/********************************************
*  *       *     ***       *                *
*   *     *     *   *     * *               *
*    *   *     *         *   *              *
*	  * *       *  **   *******             *
*	   *         ***   *       *            * 
*********************************************/


pll_vga pll_vga_inst(.inclk0(CLOCK_50), .c0(clk_25m), .c1(clk_65m), .locked(rst_vga_n));
vga vga0(.clk(clk_25m), .rst_n(rst_vga_n),.vga_r(VGA_R),.vga_g(VGA_G),.vga_b(VGA_B),.vga_hs(VGA_HS),.vga_vs(VGA_VS),.vga_blank(VGA_BLANK_N),.vga_sync(VGA_SYNC_N),.vga_clk(VGA_CLK), 
		 .state_whole(state_whole),
		 .grays1(grays1), .grays2(grays2),
		 .nexts1(nexts1), .nexts2(nexts2),
		 .blocks1(blocks1), .blocks2(blocks2),
		 .player1_vga(player1_vga), .player2_vga(player2_vga),
		 .tetris_type1(tetris_type1), .tetris_type2(tetris_type2),
		 .tetris_hold1(tetris_hold1), .tetris_hold2(tetris_hold2),
		 .x_number1(x_number1), .y_number1(y_number1), .x_number2(x_number2), .y_number2(y_number2),
		 .x_img(x_img), .y_img(y_img), .pixel(pixel),
		 .lose1(lose1), .lose2(lose2), .cnt(cnt)
		 );
wire [1:0] rotation1, rotation2;
//IMG IMG0 (.x(x_img), .y(y_img), .pixel(pixel));

assign pixel = 24'h000000;
//wire left, left_test;

//assign gameover = (lose1 || lose2);

FSM_Whole U0 (.clk(CLOCK_50), .rst(KEY[0]), .state(state_whole), .start(keystart), .gameover(lose1 | lose2), .countdownfinish(gamestart), .ctr(cnt));

Tetris player1 (.clk(CLOCK_50), .rst(KEY[0]), .start(keystart), .key_data(key_data), .blocks(blocks1), .grays(grays1), .state_Game(state_Game1), .attack_lines(lines1), .tetris_hold(tetris_hold1),
		   .vga(player1_vga), .x_number(x_number1), .y_number(y_number1), .tetris_type(tetris_type1), .gamestart(gamestart), .attacked(attack2), .nexts(nexts1), .lose(lose1), .ctr_elim(ctr_elim1), .state_whole(state_whole), .rotation(rotation1));

Tetris player2 (.clk(CLOCK_50), .rst(KEY[0]), .start(keystart), .key_data(key_data2), .blocks(blocks2), .grays(grays2), .state_Game(state_Game2), .attack_lines(lines2), .tetris_hold(tetris_hold2),
		   .vga(player2_vga), .x_number(x_number2), .y_number(y_number2), .tetris_type(tetris_type2), .gamestart(gamestart), .attacked(attack1), .nexts(nexts2), .lose(lose2), .ctr_elim(ctr_elim2), .state_whole(state_whole), .rotation(rotation2));

// attack1
always_comb begin
	if (state_Game1 == `ELIM && attack1 == 5'd31) attack1_next = attack1;
	else if (ctr_elim1 == 5'd20)			      attack1_next = attack1 + lines1;
	else if (state_Game2 == `LOSE)				  attack1_next = 0;
	else										  attack1_next = attack1;

	if (state_Game2 == `ELIM && attack2 == 5'd31) attack2_next = attack2;
	else if (ctr_elim2 == 5'd20)			      attack2_next = attack2 + lines2;
	else if (state_Game1 == `LOSE)				  attack2_next = 0;
	else										  attack2_next = attack2;
end


always_ff@(posedge CLOCK_50 or negedge KEY[0]) begin
	if (!KEY[0]) begin
		attack1 <= 5'b0;
		attack2 <= 5'b0;
	end else begin
		attack1 <= attack1_next;
		attack2 <= attack2_next;
	end
end

assign HEX2 = '1;
//assign HEX3 = '1;
assign HEX6 = '1;
//assign HEX7 = '1;
// assign LEDG[0] = tetris_hold1[0];
// assign LEDG[1] = tetris_hold1[1];
// assign LEDG[2] = tetris_hold1[2];
// assign LEDG[3] = tetris_hold2[3];
// assign LEDR[0] = state_whole[0];
// assign LEDR[1] = state_whole[1];
// assign LEDR[2] = lose1;
// assign LEDR[3] = lose2;
// 
// assign LEDR[4] = rotation1[0];
// assign LEDR[5] = rotation1[1];
// 
`ifdef DUT_LAB1
	initial begin
		$fsdbDumpfile("LAB1.fsdb");
		$fsdbDumpvars(0, DE2_115, "+mda");
	end
`endif

endmodule
