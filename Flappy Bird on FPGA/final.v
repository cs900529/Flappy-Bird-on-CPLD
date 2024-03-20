module final (clkF, clkS, reset, fly, segout, scanout, segout7, scanout7);

input clkF, clkS, reset, fly;
output reg[7:0] segout;
output reg[2:0] scanout;

output reg[7:0] segout7;
output reg[1:0] scanout7;

reg clk1, clk2, clk7;
reg [22:0] cnt_scan;
reg [15:0] cnt_clk2;
reg [24:0] cnt_scan7;

reg [3:0] i, j, y = 2, x = 1;
reg [3:0] wallX = 8;
reg [7:0] wallY;

reg [2:0] carry = 0;
reg [1:0] dark = 0, dead = 0;

reg [63:0] q;

reg [3:0] sel;
reg [3:0] q0 = 4'h0;
reg [3:0] q1 = 4'h0;
reg [3:0] q2 = 4'h0;
reg [3:0] q3 = 4'h0;
reg [3:0] d0 = 4'h0;
reg [3:0] d1 = 4'h0;
reg [3:0] d2 = 4'h0;
reg [3:0] d3 = 4'h0;

//------------------ clock running -----------------------
always@(posedge clkF or negedge reset)
begin
	if(!reset) begin
		cnt_scan <= 0;
		cnt_scan7 <= 0;
	end
	else begin
		cnt_scan <= cnt_scan + 1;
		cnt_scan7 <= cnt_scan7 + 1;
		case(q1)
		4'h0:
			if (cnt_scan == 8000000) begin
				cnt_scan <= 0;
				clk1 = ~clk1;
			end
		default:
			if (cnt_scan == 5000000) begin
				cnt_scan <= 0;
				clk1 = ~clk1;
			end
		endcase
		
		if (cnt_scan7 == 25000000) begin
			cnt_scan7 <= 0;
			clk7 = ~clk7;
		end
	end
end

always@(posedge clkS)
begin
	cnt_clk2 <= cnt_clk2 + 1;
end

//---------modify display digit ----------
always @(posedge clk1 , negedge reset)
begin
	if (reset == 0) begin
		for(i = 0;i < 8; i = i + 1) begin
			wallY[i] = 0;
		end
		wallX = 8;
		x = 1;
		y = 2;
		dead = 0;
		q = 64'b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111;
		q[x + 8 * y] = 1'b0;
	end

	else if(dead != 1)begin
//-----------bird fall--------------------------
		if(fly == 0 && wallX != 1) begin
			q = q | 64'b00000010_00000010_00000010_00000010_00000010_00000010_00000010_00000010;
			if(y == 0) y = 0;
			else y = y - 1;
			q[x + 8 * y] = 1'b0;
		end
		else if(y < 8 && wallX != 1) begin
			q = q | 64'b00000010_00000010_00000010_00000010_00000010_00000010_00000010_00000010;
			y = y + 1;
			if(y < 8) q[x + 8 * y] = 1'b0;
		end
		else if(y >= 8) begin
			q = 64'b11011011_11001011_11010011_10011000_01011110_01011000_01011110_10011000; //END
			dead = 1;
		end
		
//-----------wall move--------------------------

		if(wallX == 8)begin
			for(i = 0;i < 8; i = i + 1) wallY[i] = 0;
			case(cnt_clk2[11:10] + cnt_clk2[6:5])
			2'b00:
				for(i = 1;i < 4; i = i + 1)
					wallY[i] = 1;
			2'b01:
				for(i = 2;i < 5; i = i + 1)
					wallY[i] = 1;
			2'b10:
				for(i = 3;i < 6; i = i + 1)
					wallY[i] = 1;
			2'b11:
				for(i = 4;i < 7; i = i + 1)
					wallY[i] = 1;
			default:
				for(i = 0;i < 8; i = i + 1) begin
					wallY[i] = 0;
				end
			endcase
			//wallX = 7;
		end
		if(dead != 1) q = q | 64'b11111101_11111101_11111101_11111101_11111101_11111101_11111101_11111101;
		if(wallX < 8 && dead != 1)begin
		
			if(wallX == 1)begin
				q = q | 64'b00000110_00000110_00000110_00000110_00000110_00000110_00000110_00000110;
				q[x + 8 * y] = 1'b0;
			end
			
			
			for(i = 0;i < 8; i = i + 1)begin:one
				if(wallY[i] == 0)begin
					if((x + 8 * y) == (wallX + 8 * i))begin
						dead = 1;
						q = 64'b11011011_11001011_11010011_10011000_01011110_01011000_01011110_10011000;
						disable one;
					end
					if(dead != 1) q[wallX + 8 * i] = 1'b0;
				end
			end
		end
		if(wallX > 0) wallX = wallX - 1;
		else if(wallX == 0) wallX = 8;
	end
end

//---------modify display digit ----------
always @(posedge clk7 , negedge reset)
begin
	if (reset == 0) begin
		q0 <= 4'h0;
		q1 <= 4'h0;
		q2 <= 4'h0;
		q3 <= 4'h0;
	end
	
	else if (dead != 1) begin
		if (q0 != 4'h9)
			q0 = q0 + 1;
		else begin
			q0 = 4'h0;
			carry[0] = 1;
		end
		
		if(carry[0] == 1)begin
			if (q1 != 4'h9) begin
				q1 = q1 + 1;
			end
			else begin
				q1 = 4'h0;
				carry[1] = 1;
			end
			carry[0] = 0;
		end
		
		if(carry[1] == 1)begin
			if (q2 != 4'h9) begin
				q2 = q2 + 1;
			end
			else begin
				q2 = 4'h0;
				carry[2] = 1;
			end
			carry[1] = 0;
		end
		
		if(carry[2] == 1)begin
			if (q3 != 4'h9) begin
				q3 = q3 + 1;
			end
			else begin
				q3 = 4'h0;
			end
			carry[2] = 0;
		end
		d0 = q0;
		d1 = q1;
		d2 = q2;
		d3 = q3;
	end
	
	else begin
		if(dark == 0) begin
			q0 = 4'hF;
			q1 = 4'hF;
			q2 = 4'hF;
			q3 = 4'hF;
			dark = 1;
		end
		else if(dark == 1) begin
			q0 = d0;
			q1 = d1;
			q2 = d2;
			q3 = d3;
			dark = 0;
		end
	end
end

//-----------scan and display 7-SEG-------------
always@(cnt_scan[15:13])
begin
	scanout <= cnt_scan[15:13];
end

always@(scanout) 
begin
	case(scanout)
	7:
		segout=q[63:56];
	6:
		segout=q[55:48];
	5:
		segout=q[47:40];
	4:
		segout=q[39:32];
	3:
		segout=q[31:24];
	2:
		segout=q[23:16];
	1:
		segout=q[15:8];
	0:
		segout=q[7:0];
	default:
		segout=8'b11111111;
	endcase
end

//-----------scan and display 7-SEG-------------
always@(cnt_scan7[14:13])
begin
	scanout7 <= cnt_scan7[14:13];
	case(cnt_scan7[14:13])
	2'b00 :
		sel=q0;
	2'b01 :
		sel=q1;
	2'b10 :
		sel=q2;
	2'b11 :
		sel=q3;
	default :
		sel=4'hD;
	endcase
end

always@(sel)
begin
	case(sel)
	4'h0 :
		segout7<= 8'd192; // seg_out <= B"11000000";
	4'h1 :
		segout7<= 8'b11111001;
	4'h2 :
		segout7<= 8'b10100100;
	4'h3 :
		segout7<= 8'b10110000;
	4'h4 :
		segout7<= 8'b10011001;
	4'h5 :
		segout7<= 8'b10010010;
	4'h6 :
		segout7<= 8'b10000010;
	4'h7 :
		segout7<= 8'b11111000;
	4'h8 :
		segout7<= 8'b10000000;
	4'h9 :
		segout7<= 8'b10011000;
	default :
		segout7<= 8'b11111111;
	endcase
end

endmodule