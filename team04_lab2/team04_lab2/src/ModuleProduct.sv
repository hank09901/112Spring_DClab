// calculate (y * 2^256) mod(N)
module ModuleProduct (
    input clk,
    input rst,
    input [255:0] N,
    input [255:0] y,
    input [  1:0] state,
    input [  1:0] state_next,
    output reg [255:0] m,
    output finished
);

    parameter IDLE = 2'b00;
    parameter PREP = 2'b01;
    parameter MONT = 2'b10;
    parameter CALC = 2'b11;

    reg  [257:0] t, t_next;
    reg  [8:0]   counter, counter_next;
    reg  [255:0] m_next;
    logic finished_w, finished_r;
    wire [257:0] twot;

    assign twot = t + t;

    assign num_256 = 8'b1000_0000;
    assign finished = (finished_r) ? 1 : 0; 

    always_comb begin 
        if(counter == 9'b100000000) finished_w = 1;
        else if (state == IDLE)     finished_w = 0;
        else                        finished_w = finished_r;
    end
    always_comb begin
        if (state_next == PREP && state == IDLE) t_next = y;
        else if (twot > N && state == PREP)     t_next = t + t - N;
        else if (twot <= N && state == PREP)    t_next = t + t;
        else                                     t_next = 256'b0;
    end
    
    always_comb begin
        if (state == PREP) counter_next = counter + 1'b1;
        else               counter_next = 9'b0;
    end

    always_comb begin
        if (state == PREP && counter == 9'd256 && ((m + t) >= N))    m_next = m + t -N;
        else if (state == PREP && counter == 9'd256)                 m_next = m + t;
        else if (state == PREP)                                     m_next = m;
        else                                                        m_next = 256'd0;
    end

    always_ff@(posedge clk or posedge rst) begin
        if (rst) t <= 256'b0;
        else     t <= t_next;
    end

    always_ff@(posedge clk or posedge rst) begin
        if (rst) counter <= 8'b0;
        else     counter <= counter_next;
    end

    always_ff@(posedge clk or posedge rst) begin
        if (rst) m <= 256'b0;
        else     m <= m_next;
    end

    always_ff@(posedge clk or posedge rst) begin
        if (rst) finished_r <= 8'b0;
        else     finished_r <= finished_w;
    end



endmodule