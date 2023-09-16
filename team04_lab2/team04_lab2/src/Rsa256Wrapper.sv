module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_QUERY_RX = 0;
localparam S_READ = 1;
localparam S_CALCULATE = 2;
localparam S_QUERY_TX = 3;
localparam S_WRITE = 4;

localparam S_READ_N = 0;
localparam S_READ_D = 1;
localparam S_READ_ENC = 2;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [2:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;  // Control to start computation of algorithm
logic rsa_finished;              // Tell when the computation is finished
logic [255:0] rsa_dec;
logic [2:0] substate_r, substate_w;
logic waiting;
logic readable;
logic status;
logic ready, not_ready;
logic ready2, not_ready2;
logic writable;

// assign wire ----------------------------------------------------------
assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];


// Instantiate RSA256Core module --------------------------------------------
Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),  // input cipher text y
    .i_d(d_r),    // input private key d
    .i_n(n_r),    
    .o_a_pow_d(rsa_dec),  // output plain text x
    .o_finished(rsa_finished)
);

// Define some task -----------------------------------------------------------
task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

// Combinational logic -----------------------------------------------------
always_comb begin
    // TODO
    substate_w = substate_r;
    state_w = state_r;
    avm_address_w = avm_address_r;
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    dec_w = dec_r;
    bytes_counter_w = bytes_counter_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    rsa_start_w = rsa_start_r;
    
	  waiting = avm_waitrequest;
    readable = avm_address_r == RX_BASE;
    status = avm_address_r == STATUS_BASE;
    ready = bytes_counter_r == 7'd31;
    not_ready = bytes_counter_r < 7'd31;
    ready2 = bytes_counter_r == 7'd30;
    not_ready2 = bytes_counter_r < 7'd30;
    writable = avm_address_r == TX_BASE;
    // FSM
	 case(state_r)
	 S_QUERY_RX:begin
        if (!waiting) begin
            if(status & avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                state_w = S_READ;
            end
            else begin
                StartRead(STATUS_BASE);
                state_w = S_QUERY_RX;
            end
        end
        else begin
            StartRead(STATUS_BASE);
            state_w = S_QUERY_RX;

        end
    end
	 S_READ: begin
	     case(substate_r)
       S_READ_N:begin
            if (!waiting) begin
                if(readable & not_ready)begin
                    n_w = n_r << 8;
                    n_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = bytes_counter_r +7'd1;
                    StartRead(STATUS_BASE);
                    state_w = S_QUERY_RX;
                    substate_w = S_READ_N;

                end
                else if(readable & ready) begin
                    n_w = n_r << 8;
                    n_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = 7'd0;
                    StartRead(STATUS_BASE);
                    state_w = S_QUERY_RX;
                    substate_w = S_READ_D;
                end
            end
        end
		  S_READ_D:begin
            if (!waiting) begin
                if(readable & not_ready) begin
                    d_w = d_r << 8;
                    d_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = bytes_counter_r +7'd1;
                    StartRead(STATUS_BASE);
                    state_w = S_QUERY_RX;
                    substate_w = S_READ_D;

                end
                else if(readable & ready) begin
                    d_w = d_r << 8;
                    d_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = 7'd0;
                    StartRead(STATUS_BASE);
                    state_w = S_QUERY_RX;
                    substate_w = S_READ_ENC;
                end
            end
        end
		  S_READ_ENC: begin
            if (!waiting) begin
                if(readable & not_ready) begin
                    enc_w = enc_r << 8;
                    enc_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = bytes_counter_r +7'd1;
                    StartRead(STATUS_BASE);
                    state_w = S_QUERY_RX;
                    substate_w = S_READ_ENC;
                end
                else if(readable & ready) begin
                    enc_w = enc_r << 8;
                    enc_w[7:0] = avm_readdata[7:0];
                    bytes_counter_w = 7'd0;
                    state_w = S_CALCULATE;
                    substate_w = S_READ_ENC;
                    StartRead(STATUS_BASE);
                end
            end
      end
		  endcase
	 end
	 S_CALCULATE:begin
        rsa_start_w = 1'd1;
        if(rsa_finished)begin
            rsa_start_w = 1'd0;
            state_w = S_QUERY_TX;
            dec_w = rsa_dec;
        end
    end
	 S_QUERY_TX:begin
        if (!waiting) begin
            if(status & avm_readdata[TX_OK_BIT] == 1'b1) begin
                StartWrite(TX_BASE);
                state_w = S_WRITE;
            end
            else begin
                StartRead(STATUS_BASE);
                state_w = S_QUERY_TX;
            end
        end
        else begin
            StartRead(STATUS_BASE);
            state_w = S_QUERY_TX;
        end
    end
	 S_WRITE:begin
        if (!waiting) begin
            if(writable & not_ready2) begin
                dec_w = dec_r << 8;
                bytes_counter_w = bytes_counter_r +7'd1;
                StartRead(STATUS_BASE);
                state_w = S_QUERY_TX;
            end
            else if (writable & ready2) begin
                dec_w = dec_r << 8;
                bytes_counter_w = 7'd0;
                StartRead(STATUS_BASE);
                state_w = S_QUERY_RX;
            end
        end
    end
	 endcase
end

// Sequential circuit ---------------------------------------------------------
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_QUERY_RX;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;
        substate_r <= S_READ_N;

    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
        substate_r <= substate_w;

    end
end

endmodule
