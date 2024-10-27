module lab4_2(
    input wire clk,
    input wire rst,
    input wire start,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [15:0] LED,
    output wire [3:0] digit,
    output wire [6:0] display
);

    parameter INITIAL = 0, SET = 1, GAME = 2, FINAL = 3;
    reg [1:0] state, next_state;
    reg [3:0] key_num;
    reg [15:0] nums; // represent of four number
    reg [8:0] LED_pattern, LED_changed;
    reg [7:0] time_last, target_score, score;

    parameter [8:0] SPACE = 9'b0_0010_1001;
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

    clock_divider #(.n(27)) cld_1s(.clk(clk), .clk_div(clk_1sec));
    clock_divider #(.n(16)) cld_1ms(.clk(clk), .clk_div(clk_16));

    // preprocess button input
    debounce db_start(.pb(start), .pb_debounced(start_db), .clk(clk_16));
    one_pulse op_start(.clk(clk), .pb_in(start_db), .pb_out(start_op));

    SevenSegment seven_seg (
		.display(display), .digit(digit), .nums(nums), .rst(rst), .clk(clk)
	);
	
    wire [511:0] key_down;
	wire [8:0] last_change, last_key;
	wire key_valid;
	wire available;
	KeyboardDecoder key_de (
		.key_down(key_down), .last_change(last_change), .key_valid(key_valid),
		.PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK), .rst(rst), .clk(clk)
	);

    // check if available the push changed key
    ChangeKey ck(
		.clk(clk), .rst(rst), .key_down(key_down), .last_change(last_change), 
        .key_valid(key_valid), .available(available), .last_key(last_key)
	);

    Counter cnt(.clk(clk_1sec), .rst(rst), .state(state), .available(toinitial));

    // change state
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= INITIAL;
        end else begin
            state <= next_state;
        end
    end

    // state FSM
    always @(*) begin
        case(state)
            INITIAL: begin
                if(start_op) next_state = SET;
                else next_state = INITIAL;
            end
            SET: begin
                if(start_op) next_state = GAME;
                else next_state = SET;
            end
            GAME: begin
                if(time_last == 8'b0 || score == target_score) next_state = FINAL;
                else next_state = GAME;
            end
            FINAL: begin
                if(toinitial) next_state = INITIAL;
                else next_state = FINAL;
            end
        endcase
    end

    // set nums
    reg gamecount, istime;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            time_last <= 8'h30;
            target_score <= 8'h10;
            gamecount <= 1'b0;
            istime <= 1'b1;
        end else begin
            time_last <= time_last;
            target_score <= target_score;
            gamecount <= gamecount;
            istime <= istime;
            if(state == INITIAL) begin
                time_last <= 8'h30;
                target_score <= 8'h10;
                gamecount <= 1'b0;
                istime <= 1'b1;
            end else if(state == SET) begin
                if(available) begin
                    if(last_key == SPACE) istime <= !istime;
                    else begin
                        if(istime) time_last <= {time_last[3:0], key_num};
                        else if(!istime) target_score <= {target_score[3:0], key_num};
                    end
                end
            end else if(state == GAME) begin
                if(clk_1sec && !gamecount) begin
                    gamecount <= 1'b1;
                    if(time_last[3:0] == 4'b0) time_last <= {time_last[7:4]-4'h1, 4'h9};
                    else time_last <= time_last - 8'h1;
                end else if(!clk_1sec && gamecount) gamecount <= 1'b0;
            end
        end
    end

    // set score
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            score <= 8'h0;
            LED_changed <= 9'b0;
        end else begin
            score <= score;
            LED_changed <= LED_changed;
            if(state == GAME) begin
                if(clk_1sec && !gamecount) LED_changed <= 9'b0;
                else if(available && LED[4'd15-key_num+4'b1] == 1'b1) begin
                    if(score[3:0] == 4'h9) score <= {score[7:4]+4'h1, 4'h0};
                    else score <= score + 8'h1;
                    LED_changed[4'd9-key_num] <= 1;
                end
            end
        end
    end

    // set LED pattern for GAME
    always @(posedge clk_1sec, posedge rst) begin
        if(rst) begin
            LED_pattern <= 9'b001011000;
        end else begin
            LED_pattern <= LED_pattern;
            if(state == GAME) begin
                LED_pattern <= {LED_pattern[0], LED_pattern[8], LED_pattern[7]^LED_pattern[0],
                                LED_pattern[6]^LED_pattern[0], LED_pattern[5],
                                LED_pattern[4]^LED_pattern[0], LED_pattern[3:1]};
            end
        end
    end

    // shift LED and seven segment
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            nums <= 16'hAAAA; // default four dash
            LED <= 16'b0;
        end else begin
            case(state)
                INITIAL: begin
                    nums <= 16'hAAAA;
                    LED <= 16'b0;
                end
                SET: begin
                    nums <= {time_last, target_score};
                    if(istime) LED <= {8'hFF, 8'h00};
                    else if(!istime) LED <= {8'h00, 8'hFF};
                end
                GAME: begin
                    nums <= {time_last, score};
                    LED <= {LED_pattern ^ LED_changed, 7'b0};
                end
                FINAL: begin
                    if(score == target_score) nums <= 16'hABCD; // win
                    else nums <= 16'hE05F; // lose
                    // flash LED
                    if(clk_1sec) LED <= 16'hFFFF;
                    else LED <= 16'h0000;
                end
            endcase
        end
    end

    always @ (*) begin
		case (last_key)
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
			10 : display = 7'b0111111; // only dash
            11 : display = 7'b1100010; // W
            12 : display = 7'b1001111; // I
            13 : display = 7'b1001000; // N
            14 : display = 7'b1000111; // L
            15 : display = 7'b0000110; // E
            default : display = 7'b1111111; // nothing
    	endcase
    end
endmodule

module ChangeKey(
	input wire clk,
	input wire rst,
	input wire [511:0] key_down,
	input wire [8:0] last_change,
	input wire key_valid,
	output reg available,
    output reg [8:0] last_key
);
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

module Counter #(parameter target = 3)(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    output wire available
);

    reg [1:0] cnt;
    always @(posedge clk, posedge rst) begin
        if(rst) cnt <= 2'b00;
        else begin
            if(state == target) cnt <= cnt + 2'b01;
            else cnt <= 2'b00;
        end
    end

    assign available = (cnt == 2'b11);
endmodule