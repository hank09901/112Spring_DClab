`include "global.sv"

module FSM_Whole (
    input clk, rst,
    input start,
    input gameover,
    output reg [27:0] ctr,
    output countdownfinish,
    output [1:0] state
);

reg  [1:0] state_next;
reg  [27:0] ctr_next;
//wire countdownfinish;

always_comb begin
    if (state == `CTWN) ctr_next = ctr + 28'd1;
    else                ctr_next = 0;
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst) ctr <= 0;
    else      ctr <= ctr_next;
end

//assign countdownfinish = (ctr == 28'd150_000_000);
assign countdownfinish = (ctr == 28'd150_000_000);


always_comb begin
    case (state)
        `IDLE:
            if (start) state_next = `CTWN;
            else       state_next = `IDLE;
        `CTWN:
            if (countdownfinish) state_next = `PLAY;
            else                 state_next = `CTWN;
        `PLAY:
            if (gameover)        state_next = `ENDS;
            else                 state_next = `PLAY;
        `ENDS:
            if (start)           state_next = `IDLE;
            else                 state_next = `ENDS;
    endcase
end

always_ff@(posedge clk or negedge rst) begin
    if (!rst)   state <= 2'b00;
    else        state <= state_next;
end




endmodule