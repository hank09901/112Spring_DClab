`include "global.sv"

module FSM_Game (
    input clk, rst, start, touch, space, lose, hold,
    output reg [2:0] state,
    output reg [4:0] ctr_elim,
    output reg [4:0] ctr_garb
);

reg [2:0]  state_next;
reg [29:0] ctr_lockdelay, ctr_lockdelay_next;
reg [ 4:0] ctr_elim_next;
reg time_out;
reg [4:0]  ctr_garb_next;

always_comb begin
    if (touch && ctr_lockdelay == `LKDYTIME) begin
        ctr_lockdelay_next = `LKDYTIME;
        time_out = 1'b1;
    end else if (touch) begin
        ctr_lockdelay_next = ctr_lockdelay + 1'd1;
        time_out = 1'b0;
    end else begin
        ctr_lockdelay_next = 30'd0;
        time_out = 1'b0;
    end
end


always_comb begin
    if (state == `PLAC)      ctr_elim_next = 5'd20;
    else if (state == `ELIM) ctr_elim_next = ctr_elim - 1'd1;
    else                     ctr_elim_next = 5'd21;
end

always_comb begin
    if (state == `ELIM)      ctr_garb_next = 5'd0;
    else if (state == `GARB) ctr_garb_next = ctr_garb + 1'b1;
    else                     ctr_garb_next = 5'd21;
end



always_comb begin
    case (state)
        `NOTH:
            if (start) state_next = `PREP;
            else       state_next = `NOTH;
        `PREP:
            state_next = `DROP;
        `DROP:
            if (touch)      state_next = `LKDY;
            else if (hold)  state_next = `PREP;
            else            state_next = `DROP;
        `LKDY:
            if (hold)          state_next = `PREP;
            else if (space)    state_next = `PLAC;
            else if (time_out) state_next = `PLAC;
            else if (!touch)   state_next = `DROP;
            else               state_next = `LKDY;
        `PLAC:
            state_next = `ELIM;
        `ELIM:
            if (ctr_elim == 0) state_next = `GARB;
            else               state_next = `ELIM;
        `GARB:
            if (ctr_garb == 5'd19) state_next = `LOSE;
            else                   state_next = `GARB;
        `LOSE:
            if (lose) state_next = `NOTH;
            else      state_next = `PREP;
        default:
            state_next = `NOTH;
    endcase
end

always_ff @(posedge clk or negedge rst)
    if (!rst) begin
        state         <= 3'b0;
        ctr_elim      <= 5'd0;
        ctr_garb      <= 5'd0;
        ctr_lockdelay <= 0;
    end else begin
        state         <= state_next;
        ctr_elim      <= ctr_elim_next;
        ctr_garb      <= ctr_garb_next;
        ctr_lockdelay <= ctr_lockdelay_next;
    end
endmodule