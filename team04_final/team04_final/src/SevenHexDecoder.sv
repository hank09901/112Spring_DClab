/*module HexToSevenSegment(
	hex_value,
	converted_value
);

	input [3:0] hex_value;
	output [6:0] converted_value;
	
	always_comb begin
		case(hex_value)
			4'h1: converted_value = 7'b1111001;
			4'h2: converted_value = 7'b0100100;
			4'h3: converted_value = 7'b0110000;
			4'h4: converted_value = 7'b0011001;
			4'h5: converted_value = 7'b0010010;
			4'h6: converted_value = 7'b0000010;
			4'h7: converted_value = 7'b1111000;
			4'h8: converted_value = 7'b0000000;
			4'h9: converted_value = 7'b0011000;
			4'ha: converted_value = 7'b0001000;
			4'hb: converted_value = 7'b0000011;
			4'hc: converted_value = 7'b1000110;
			4'hd: converted_value = 7'b0100001;
			4'he: converted_value = 7'b0000110; 
			4'hf: converted_value = 7'b0001110;
			default: converted_value = 7'b1000000;
		endcase
	end
endmodule*/

`define NUMBER0 7'b1000000
`define NUMBER1 7'b1111001
`define NUMBER2 7'b0100100
`define NUMBER3 7'b0110000
`define NUMBER4 7'b0011001
`define NUMBER5 7'b0010010
`define NUMBER6 7'b0000010
`define NUMBER7 7'b1111000
`define NUMBER8 7'b0000000
`define NUMBER9 7'b0011000

module AttackDisplay (
	input [4:0] value,
	output [6:0] tens, digits
);

wire [3:0] digit_number, ten_number;

assign digit_number = value % 4'd10;
assign ten_number   = value / 4'd10;

always_comb begin
	case (digit_number)
		4'd0: digits = `NUMBER0;
		4'd1: digits = `NUMBER1;
		4'd2: digits = `NUMBER2;
		4'd3: digits = `NUMBER3;
		4'd4: digits = `NUMBER4;
		4'd5: digits = `NUMBER5;
		4'd6: digits = `NUMBER6;
		4'd7: digits = `NUMBER7;
		4'd8: digits = `NUMBER8;
		4'd9: digits = `NUMBER9;
		default: digits = 7'b0000000;
	endcase

end

always_comb begin
	case (ten_number)
		4'd0: tens = `NUMBER0;
		4'd1: tens = `NUMBER1;
		4'd2: tens = `NUMBER2;
		4'd3: tens = `NUMBER3;
		default: tens = 7'b0000000;
	endcase	
end
endmodule

module SpeedDisplay (
	input [2:0] value,
	output [6:0] digits
);
always_comb begin
	case (value)
		3'd0: digits = `NUMBER0;
		3'd1: digits = `NUMBER1;
		3'd2: digits = `NUMBER2;
		3'd3: digits = `NUMBER3;
		3'd4: digits = `NUMBER4;
		3'd5: digits = `NUMBER5;
		3'd6: digits = `NUMBER6;
		3'd7: digits = `NUMBER7;
		default: digits = 7'b0000000;
	endcase
end
endmodule