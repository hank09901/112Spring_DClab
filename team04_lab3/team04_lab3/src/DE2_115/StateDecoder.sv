module StateDecoder (
	input        [2:0] i_hex,
	output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = 7'b1000000;  // 0
parameter D1 = 7'b1111001;  // 1
parameter D2 = 7'b0100100;  // 2
parameter D3 = 7'b0110000;  // 3
parameter D4 = 7'b0011001;  // 4
parameter D5 = 7'b0010010;  // 5
parameter D6 = 7'b0000010;  // 6
parameter D7 = 7'b1011000;  // 7
parameter D8 = 7'b0000000;  // 8
parameter D9 = 7'b0010000;  // 9
always_comb begin
	case(i_hex)
		3'd0: begin o_seven_ten = D0; o_seven_one = D0; end
		3'd1: begin o_seven_ten = D0; o_seven_one = D1; end
		3'd2: begin o_seven_ten = D0; o_seven_one = D2; end
		3'd3: begin o_seven_ten = D0; o_seven_one = D3; end
		3'd4: begin o_seven_ten = D0; o_seven_one = D4; end
		3'd5: begin o_seven_ten = D0; o_seven_one = D5; end
		default: begin o_seven_ten = D0; o_seven_one = D6; end
	endcase
end

endmodule
