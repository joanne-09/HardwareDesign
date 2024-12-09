// 112062309 陳芷妍
module exam2_B(
    input clk, 
    input rst, 
    input en, 
	input [1:0] sw,
    inout PS2_DATA, 
	inout PS2_CLK, 
    output [3:0] DIGIT, 
    output [6:0] DISPLAY,
    output reg [15:0] led
);
    parameter [8:0] KEY_CODES [0:1] = {
        9'b0_0001_0100, //left Ctrl
        9'b1_0001_0100 // right Ctrl
    };

    // add your design here
	parameter IDLE = 0, COUNTDOWN = 1, BATTLE = 2;
	reg [1:0] state, next_state;
	reg [1:0] cnt, curkey;
	reg [1:0] p1, p2;
	reg [15:0] p1_led, p2_led;
	reg [15:0] nums;
	reg [1:0] prev_sw;

	clock_divider #(.n(27)) cd(.clk(clk), .clk_div(clk27));
	clock_divider #(.n(24)) cd2(.clk(clk), .clk_div(clk24));

	always @(posedge clk27) begin
		if(rst) cnt <= 0;
		else begin
			if(state == COUNTDOWN) begin
				cnt <= cnt + 1;
			end else begin
				cnt <= 0;
			end
		end
	end

	debounce db(.pb(en), .clk(clk), .pb_debounced(en_db));
	one_pulse op(.pb_debounced(en_db), .clk(clk), .pb_one_pulse(en_op));

	KeyboardDecoder kd(
		.clk(clk), .rst(rst), .PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK),
		.last_change(last_change), .key_down(key_down), .key_valid(key_valid)
	);
	AvailKey ak(.clk(clk), .rst(rst), .key_down(key_down), .key_valid(key_valid), .last_change(last_change), .available(available), .last_key(last_key));
	SevenSegment ss(.clk(clk), .rst(rst), .nums(nums), .display(DISPLAY), .digit(DIGIT));

	always @(posedge clk) begin
		if(rst) state <= IDLE;
		else state <= next_state;
	end

	always @(*) begin
		case(state)
			IDLE: begin
				if(en_op) next_state = COUNTDOWN;
				else next_state = IDLE;
			end
			COUNTDOWN: begin
				if(cnt == 3) next_state = BATTLE;
				else next_state = COUNTDOWN;
			end
			BATTLE: begin
				if(p1 == 0 || p2 == 0) next_state = IDLE;
				else next_state = BATTLE;
			end
		endcase
	end

	// led
	always @(*) begin
		case(state)
			IDLE: led = 16'hffff;
			COUNTDOWN: begin
				if(clk27 == 0) led = 16'h0000;
				else led = 16'hffff;
			end
			BATTLE: led = p1_led | p2_led;
		endcase
	end

	// TODO: this part is a kind of messy and should change to keyboard control
	reg used;
	always @(posedge clk) begin
		if(rst) begin
			p1_led <= 16'h0000;
			p2_led <= 16'h0000;
			used <= 0;
		end else begin
			if(clk24 && !used) begin
				used <= 1;
				if(sw[0] != prev_sw[0]) p1_led <= {1'b1, p1_led[15:1]};
				else if(sw[1] != prev_sw[1]) p2_led <= {p2_led[14:0], 1'b1};
				else begin
					p1_led <= p1_led >> 1;
					p2_led <= p2_led << 1;
				end
			end else if(!clk24) used <= 0;
			else begin
				if(sw[0] != prev_sw[0]) p1_led[15] <= 1;
				else if(sw[1] != prev_sw[1]) p2_led[0] <= 1;
				else begin
					p1_led <= p1_led;
					p2_led <= p2_led;
				end
			end
		end
	end

	always @(posedge clk24) begin
		if(rst) begin
			p1 <= 2'b10;
			p2 <= 2'b10;
		end else begin
			if(p1_led[0] == 1) p2 <= p2 - 1;
			else if(p2_led[15] == 1) p1 <= p1 - 1;
			else begin
				p1 <= p1;
				p2 <= p2;
			end
		end
	end

	// seven segment
	always @(*) begin
		case(state)
			IDLE: nums = 16'h0000;
			COUNTDOWN: nums = {12'h000, 3-cnt};
			BATTLE: nums = {6'h0, p1, 6'h0, p2};
		endcase
	end

	// key
	// always @(*) begin
	// 	case(last_key)
	// 		KEY_CODES[0]: curkey = 2'b01;
	// 		KEY_CODES[1]: curkey = 2'b10;
	// 		default: curkey = 0;
	// 	endcase
	// end

	always @(posedge clk) begin
		prev_sw <= sw;
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

// provided modules
module clock_divider #(parameter n=25) (clk, clk_div);
    input clk;
    output clk_div;

    reg [n-1:0] num = 0;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule


module debounce (pb, clk, pb_debounced);
    input pb;
    input clk;
    output pb_debounced;

    reg [3:0] shift_reg;

    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end

    assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule


module one_pulse (pb_debounced, clk, pb_one_pulse);
    input pb_debounced;
    input clk;
    output pb_one_pulse;
    
    reg pb_one_pulse;
    reg pb_debounced_delay;

    always @(posedge clk) begin
        if(pb_debounced == 1'b1 && pb_debounced_delay == 1'b0) begin
            pb_one_pulse <= 1'b1;
        end else begin
            pb_one_pulse <= 1'b0;
        end            
        pb_debounced_delay <= pb_debounced;
    end
endmodule


module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit, 
	input wire [15:0] nums, // four 4-bits BCD number
	input wire rst,
	input wire clk  // Input 100Mhz clock
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
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule


module KeyboardDecoder(
    input wire rst,
    input wire clk,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [511:0] key_down,
    output wire [8:0] last_change,
    output reg key_valid
);
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
    parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	one_pulse op (
		.pb_one_pulse(pulse_been_ready),
		.pb_debounced(been_ready),
		.clk(clk)
	);

    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule