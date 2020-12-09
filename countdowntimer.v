module countdowntimer (
	input wire CLOCK_50,
	input wire [3:0] KEY,
	//input wire [16:14] SW,
	output wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
	output wire [17:0] LEDR
);

reg [31:0] counter;
reg [31:0] timer = 86400;
reg [2:0] updating;
reg [1:0] state;
reg pulse;
reg [17:0] active;
reg [3:0] oldkey;

wire [31:0] increment;
wire [3:0] s1, s2, m1, m2, h1, h2;

assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign LEDR = active;

updatingtoincrement uti (updating, increment);

bintoval #(10, 1) btv1 (timer, s2);
bintoval #(6, 10) btv2 (timer, s1);
bintoval #(10, 60) btv3 (timer, m2);
bintoval #(6, 600) btv4 (timer, m1);
bintoval #(10, 3600) btv5 (timer, h2);
bintoval #(3, 36000) btv6 (timer, h1);

numtosegment #(0) nts1 (s2, updating, pulse, HEX2);
numtosegment #(1) nts2 (s1, updating, pulse, HEX3);
numtosegment #(2) nts3 (m2, updating, pulse, HEX4);
numtosegment #(3) nts4 (m1, updating, pulse, HEX5);
numtosegment #(4) nts5 (h2, updating, pulse, HEX6);
numtosegment #(5) nts6 (h1, updating, pulse, HEX7);

always @ (posedge CLOCK_50) begin
	
	counter = counter + 1;
	
	case (state) 
		2'b00: 
			begin
				pulse = counter > 25000000;
				active = 0;
				if (counter > 50000000) begin
					counter = 0;
				end
				if (KEY[0] && ~oldkey[0])
					timer = (timer + increment) % 86400;
				else if (KEY[1] && ~oldkey[1])
					timer = (timer - increment) % 86400;
				else if (KEY[2] && ~oldkey[2])
					updating = (updating + 1) % 6;
				else if (KEY[3] && ~oldkey[3]) begin
					counter = 0;
					state = 2'b01;
				end
			end
		2'b01:
			begin
				pulse = 1'b0;
				if (timer == 0)
					state = 2'b10;		
				else if (counter > 50000000) begin
					timer = timer - 1;
					counter = 0;
				end
				
				if (KEY[3] && ~oldkey[3])
					state = 2'b00;
			end
		2'b10:
			begin
				active = 18'b111111111111111111;
				if (KEY[3] && ~oldkey[3])
					state = 2'b00;
			end
		endcase
	oldkey = KEY;
end

endmodule

module bintoval (
	input [31:0] timer,
	output reg [3:0] val
);
	parameter mod, div;

always @*
	val = (timer / div) % mod;

endmodule

module updatingtoincrement (
	input [2:0] updating,
	output reg [31:0] increment
	);

	always @* begin
		case (updating)
		3'b000: increment = 1;
		3'b001: increment = 10;
		3'b010: increment = 60;
		3'b011: increment = 600;
		3'b100: increment = 3600;
		3'b101: increment = 36000;
		endcase
	end
		
endmodule

module numtosegment(
    input  [3:0] num,
	 input [2:0] updating,
	 input pulse,
    output reg [6:0] segment
    );
	 parameter update = 0;
	 
	always @* begin
		case (num)
		4'b0000 :
			segment = 7'b1000000;
		4'b0001 :
			segment = 7'b1111001;
		4'b0010 :
			segment = 7'b0100100; 
		4'b0011 :
			segment = 7'b0110000;
		4'b0100 :
			segment = 7'b0011001;
		4'b0101 :
			segment = 7'b0010010;
		4'b0110 :
			segment = 7'b0000010;
		4'b0111 :
			segment = 7'b1111000;
		4'b1000 :
			segment = 7'b0000000;
		4'b1001 :
			segment = 7'b0010000;
		endcase

		if (update == updating && pulse) segment = 7'b1111111;
		
	end 
endmodule
