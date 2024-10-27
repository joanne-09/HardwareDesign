module lab4_1(
	output wire [6:0] display,
	output wire [3:0] digit,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
	);
	
	parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
	parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
	parameter [8:0] KEY_CODES [0:19] = {
		9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
		9'b0_0111_0000, // right_0 => 70
		9'b0_0110_1001, // right_1 => 69
		9'b0_0111_0010, // right_2 => 72
		9'b0_0111_1010, // right_3 => 7A
		9'b0_0110_1011, // right_4 => 6B
		9'b0_0111_0011, // right_5 => 73
		9'b0_0111_0100, // right_6 => 74
		9'b0_0110_1100, // right_7 => 6C
		9'b0_0111_0101, // right_8 => 75
		9'b0_0111_1101  // right_9 => 7D
	};
	
	reg [15:0] nums; // represent of four number
	reg [3:0] key_num;

	wire [511:0] key_down;
	wire [8:0] last_change;
	wire key_valid;
	wire available;
		
	// display: 7-segment display value
	// digit: decide which segment to display
	SevenSegment seven_seg (
		.display(display), .digit(digit), .nums(nums), .rst(rst), .clk(clk)
	);
	
	// key_down: if pressed, this digit will be 1
	// last_change: pressed key value
	// been_ready: if key is down
	KeyboardDecoder key_de (
		.key_down(key_down), .last_change(last_change), .key_valid(key_valid),
		.PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK), .rst(rst), .clk(clk)
	);

	ChangeKey ck(
		.clk(clk), .rst(rst), .key_down(key_down),
		.last_change(last_change), .key_valid(key_valid), .available(available)
	);

	always @ (posedge clk, posedge rst) begin
		if (rst) begin
			nums <= 16'hAAAA; // default four dash
		end else begin
			nums <= nums;
			if(available) nums <= {key_num, nums[15:4]};
		end
	end
	
	// updated number
	always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000; // 0
			KEY_CODES[01] : key_num = 4'b0001; // 1
			KEY_CODES[02] : key_num = 4'b0010; // 2
			KEY_CODES[03] : key_num = 4'b0011; // 3
			KEY_CODES[04] : key_num = 4'b0100; // 4
			KEY_CODES[05] : key_num = 4'b0101; // 5
			KEY_CODES[06] : key_num = 4'b0110; // 6
			KEY_CODES[07] : key_num = 4'b0111; // 7
			KEY_CODES[08] : key_num = 4'b1000; // 8
			KEY_CODES[09] : key_num = 4'b1001; // 9
			KEY_CODES[10] : key_num = 4'b0000; // 0
			KEY_CODES[11] : key_num = 4'b0001; // 1
			KEY_CODES[12] : key_num = 4'b0010; // 2
			KEY_CODES[13] : key_num = 4'b0011; // 3
			KEY_CODES[14] : key_num = 4'b0100; // 4
			KEY_CODES[15] : key_num = 4'b0101; // 5
			KEY_CODES[16] : key_num = 4'b0110; // 6
			KEY_CODES[17] : key_num = 4'b0111; // 7
			KEY_CODES[18] : key_num = 4'b1000; // 8
			KEY_CODES[19] : key_num = 4'b1001; // 9
			default		  : key_num = 4'b1111; // default
		endcase
	end
	
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
);
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			default : display = 7'b0111111; // only dash
    	endcase
    end
endmodule

module ChangeKey(
	input wire clk,
	input wire rst,
	input wire [511:0] key_down,
	input wire [8:0] last_change,
	input wire key_valid,
	output reg available
);
	reg [8:0] last_key;
	reg pressed;
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			available <= 1'b0;
			pressed <= 0;
			last_key <= 9'b0;
		end else begin
			pressed <= pressed;
			available <= 0;
			last_key <= last_key;
			if (!pressed && key_valid && key_down[last_change]) begin
				pressed <= 1;
				available <= 1'b1;
				last_key <= last_change;
			end else if(pressed && key_valid && key_down[last_key] == 1'b0) begin
				pressed <= 0;
				last_key <= 9'b0;
			end
		end
	end
endmodule