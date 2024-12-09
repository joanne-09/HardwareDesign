module exam2(
    input clk,
    input rst,
    input en,
    inout PS2_DATA,
    inout PS2_CLK,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output reg [15:0] LED
);

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
    9'b0_0111_1101 // right_9 => 7D
};

parameter INIT = 0, SET = 1, GUESS = 2, CHECK = 3;
reg flash; reg [2:0] cnt;
reg [1:0] state, next_state;
reg [3:0] curkey;
reg [15:0] nums, password, guessed;
wire correct;

clk_divider cd(.clk(clk), .clk_div(clk24));
KeyboardDecoder kd(
    .PS2_CLK(PS2_CLK), .PS2_DATA(PS2_DATA), .clk(clk), .rst(rst), 
    .key_down(key_down), .last_change(last_change), .key_valid(key_valid)
);
AvailKey ak(.clk(clk), .rst(rst), .key_down(key_down), .key_valid(key_valid), .last_change(last_change), .available(available), .last_key(last_key));

SevenSegment ss(.display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst), .clk(clk), .flash(flash));

always @(posedge clk24) begin
    if(rst) begin
        flash <= 1;
        cnt <= 0;
    end else begin
        if(state == CHECK) begin
            cnt <= cnt + 1;
            flash <= ~flash;
        end else begin
            cnt <= 0;
            flash <= 1;
        end
    end
end

always @(posedge clk, posedge rst) begin
    if(rst) state <= INIT;
    else state <= next_state;
end

always @(*) begin
    case(state)
        INIT: begin
            if(en) next_state = SET;
            else next_state = INIT;
        end
        SET: begin
            if(en) next_state = GUESS;
            else next_state = SET;
        end
        GUESS: begin
            if(en) next_state = CHECK;
            else next_state = GUESS;
        end
        CHECK: begin
            if(correct && cnt == 5) next_state = INIT;
            else if(cnt == 5) next_state = GUESS;
            else next_state = CHECK;
        end
    endcase
end

assign correct = (password == guessed);

// led
always @(*) begin
    case(state)
        INIT: LED = 16'hF000;
        SET: LED = 16'h0F00;
        GUESS: LED = 16'h00F0;
        CHECK: LED = 16'h000F;
    endcase
end

// seven segment
always @(*) begin
    case(state)
        INIT: nums = 16'hAAAA;
        SET: nums = password;
        GUESS: nums = guessed;
        CHECK: begin
            if(correct) nums = 16'h1111;
            else nums = 16'h0000;
        end
    endcase
end

always @(posedge clk, posedge rst) begin
    if(rst) password <= 0;
    else begin
        password <= password;
        if(state == INIT) password <= 0;
        else if(state == SET && curkey != 15)
            password <= {password[11:0], curkey};
    end
end

always @(posedge clk, posedge rst) begin
    if(rst) guessed <= 0;
    else begin
        guessed <= guessed;
        if(state == INIT || state == SET) guessed <= 0;
        else if(state == GUESS && curkey != 15)
            guessed <= {guessed[11:0], curkey};
    end
end

always @(*) begin
    case(last_key)
        KEY_CODES[0]: curkey = 0;
        KEY_CODES[1]: curkey = 1;
        KEY_CODES[2]: curkey = 2;
        KEY_CODES[3]: curkey = 3;
        KEY_CODES[4]: curkey = 4;
        KEY_CODES[5]: curkey = 5;
        KEY_CODES[6]: curkey = 6;
        KEY_CODES[7]: curkey = 7;
        KEY_CODES[8]: curkey = 8;
        KEY_CODES[9]: curkey = 9;
        KEY_CODES[10]: curkey = 0;
        KEY_CODES[11]: curkey = 1;
        KEY_CODES[12]: curkey = 2;
        KEY_CODES[13]: curkey = 3;
        KEY_CODES[14]: curkey = 4;
        KEY_CODES[15]: curkey = 5;
        KEY_CODES[16]: curkey = 6;
        KEY_CODES[17]: curkey = 7;
        KEY_CODES[18]: curkey = 8;
        KEY_CODES[19]: curkey = 9;
        default: curkey = 15;
    endcase
end

endmodule

module clk_divider #(parameter n = 24)(
    input clk,
    output wire clk_div
);

reg [n-1:0] clk_divider;
always @(posedge clk) begin
    clk_divider <= clk_divider + 1;
end
assign clk_div = clk_divider[n-1];
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk,
    input wire flash
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
            if(flash) begin
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
            end else begin
                display_num <= 4'b0000;
                digit <= 4'b1111;
            end
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
			10 : display = 7'b0111111; // only dash
            default : display = 7'b1111111; // nothing
    	endcase
    end
endmodule

module AvailKey(
    input clk,
    input rst,
    input [511:0] key_down,
    input key_valid,
    input [8:0] last_change,
    output reg available,
    output reg [8:0] last_key
);

    reg pressed;
    always @(posedge clk) begin
        if(rst) begin
            pressed <= 0;
            available <= 0;
            last_key <= 0;
        end else begin
            pressed <= pressed;
            available <= 0;
            last_key <= last_key;
            if(!pressed && key_valid && key_down[last_change]) begin
                pressed <= 1;
                available <= 1;
                last_key <= last_change;
            end else if(pressed && key_valid && !key_down[last_key]) begin
                pressed <= 0;
                last_key <= 0;
            end
        end
    end

endmodule