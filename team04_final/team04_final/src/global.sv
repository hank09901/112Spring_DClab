`define NON     4'b0000
`define Z_BLOCK 4'b0001
`define L_BLOCK 4'b0010
`define O_BLOCK 4'b0011
`define S_BLOCK 4'b0100
`define I_BLOCK 4'b0101
`define J_BLOCK 4'b0110
`define T_BLOCK 4'b0111
`define GRAY    4'b1000
//`define WHITE   4'b1001
`define TRASH   4'b1010

`define KEY_LEFT    8'h6b
`define KEY_RIGHT   8'h74
`define KEY_ROT     8'h75
`define KEY_ANTIROT 8'h1A
`define KEY_DOWN    8'h72
`define KEY_ENTER   8'h5A
`define KEY_SPACE   8'h29
`define KEY_LSHIFT  8'h12
`define KEY_RSHIFT  8'h59

`define LEFT  2'b01
`define RIGHT 2'b10
`define DOWN  2'b11

`define RED     24'hEE0000
`define ORANGE  24'hFF8800
`define YELLOW  24'hFFFF33
`define LIME    24'h00FF00
`define CYAN    24'h00FFFF
`define BLUE    24'h0000FF
`define PURPLE  24'h7733BB
`define GREY    24'hC0C0C0
`define WHITE  24'hFFFFFF
`define TRASHH  24'h808080

`define IDLE 2'b00  // idle
`define CTWN 2'b01  // count down
`define PLAY 2'b10  // play
`define ENDS 2'b11  // end games

`define NOTH 3'b000 // idle state
`define PREP 3'b001 // prepare for next tetris
`define DROP 3'b010 // tetris dropping
`define LKDY 3'b011 // lock delay
`define PLAC 3'b100 // place tetris
`define ELIM 3'b101 // elimination lines
`define GARB 3'b110 // add garbage lines
`define LOSE 3'b111 // anyone lose or not

`define LKDYTIME 30'd100_000_000