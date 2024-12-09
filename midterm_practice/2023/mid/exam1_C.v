module exam1_C(
    input wire clk, // 100Mhz clock
    input wire rst,
    input wire en,
    input wire set,
    input wire up,
    input wire down,
    input wire [15:0] sw,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output reg [15:0] led
);
	parameter RESET=0, START=1, FINISH=2;
	reg [1:0] state, next_state;
	reg dir111, dir1; // 1: move right, 0: move left
	reg [15:0] s111, s1; // indicate two snake position
	reg [1:0] mode111; // 0: 24, 1: 25, 2: 26
	reg signed [3:0] score;
	reg snack111_clk;

	debounce endb(.clk(clk), .pb(en), .pb_debounced(en_db));
	debounce setdb(.clk(clk), .pb(set), .pb_debounced(set_db));
	debounce updb(.clk(clk), .pb(up), .pb_debounced(up_db));
	debounce downdb(.clk(clk), .pb(down), .pb_debounced(down_db));
	onepulse enop(.pb_debounced(en_db), .clk(clk), .pb_1pulse(en_op));
	onepulse setop(.pb_debounced(set_db), .clk(clk), .pb_1pulse(set_op));
	onepulse upop(.pb_debounced(up_db), .clk(clk), .pb_1pulse(up_op));
	onepulse downop(.pb_debounced(down_db), .clk(clk), .pb_1pulse(down_op));
	clock_divider #(.n(24)) n24 (.clk(clk), .clk_div(clk24));
	clock_divider #(.n(25)) n25(.clk(clk), .clk_div(clk25));
	clock_divider #(.n(26)) n26(.clk(clk), .clk_div(clk26));
	Counter cnter(.clk(clk26), .ori_clk(clk), .rst(rst), .state(state), .available(tofinish));

	// state FSM
	always @(posedge clk) begin
		if(rst) state <= RESET;
		else state <= next_state;
	end

	always @(*) begin
		case(state)
			RESET: begin
				if(en_op) next_state = START;
				else next_state = RESET;
			end
			START: begin
				if(tofinish) next_state = FINISH;
				else next_state = START;
			end
			FINISH: begin
				if(en_op) next_state = RESET;
				else next_state = FINISH;
			end
		endcase
	end

	// set snake111 mode
	always @(posedge clk) begin
		case(state)
			RESET : mode111 <= 1;
			START : begin
				mode111 <= mode111;
				if(up_op && mode111 < 2) mode111 <= mode111 + 1;
				else if(down_op && mode111 > 0) mode111 <= mode111 - 1;
			end
			default: mode111 <= mode111;
		endcase
	end

	// set snack111 clock
	always @(*) begin
		case(mode111)
			0: snack111_clk = clk24;
			1: snack111_clk = clk25;
			2: snack111_clk = clk26;
			default: snack111_clk = clk26;
		endcase
	end

	// led control
	always @(*) begin
		case(state)
			RESET: led = 16'hE001;
			START: led = s111 | s1;
		endcase
	end

	// control snack111 movement
	always @(posedge snack111_clk) begin
		if(rst) begin
			s111 <= 16'hE000;
			dir111 <= 1;
		end else begin
			s111 <= s111;
			dir111 <= dir111;
			if(state == START) begin
				if(s111 == 16'hE000 && dir111 == 0) dir111 <= 1;
				else if(s111 == 16'h0007 && dir111 == 1) dir111 <= 0;
				else begin
					if(dir111 == 1) begin
						if((s111 >> 1) & s1 != 0) dir111 <= 0;
						else s111 <= s111 >> 1;
					end else begin
						if((s111 << 1) & s1 != 0) dir111 <= 1;
						else s111 <= s111 << 1;
					end
				end
			end
		end
	end

	// control snack1 movement
	always @(posedge clk25) begin
		if(rst) begin
			s1 <= 16'h0001;
			dir1 <= 0;
		end else begin
			s1 <= s1;
			dir1 <= dir1;
			if(state == START) begin
				if(s1 == 16'h8000 && dir1 == 0) dir1 <= 1;
				else if(s1 == 16'h0001 && dir1 == 1) dir1 <= 0;
				else begin
					if(dir1 == 1) begin
						if((s1 >> 1) & s111 != 0) dir1 <= 0;
						else s1 <= s1 >> 1;
					end else begin
						if((s1 << 1) & s111 != 0) dir1 <= 1;
						else s1 <= s1 << 1;
					end
				end
			end
		end
	end

endmodule

module Counter (
	input wire clk,
	input wire ori_clk,
	input wire rst,
	input wire [1:0] state,
	output wire available
);
	parameter cnt = 10;
	reg [4:0] count;

	always @(posedge clk) begin
		if(rst) count <= 0;
		else begin
			if(state == 1) count <= count + 1;
			else count <= 0;
		end
	end

	assign available = (count == cnt) ? 1 : 0;
endmodule

// You can modify below modules I/O or content if needed.
// Also you can add any module you need.
// Make sure you include all modules you used in this file.

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
			10: display = 7'b1111111;	//blank
			11: display = 7'b0111111;   //dash
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module clock_divider(clk, clk_div);   
    parameter n = 26;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num <= next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule

module debounce (pb_debounced, pb, clk); 
	output pb_debounced;
	input pb;
	input clk; 
	reg [3:0] DFF;
	always @(posedge clk) begin 
		DFF[3:1] <= DFF[2:0]; 
		DFF[0] <= pb; 
	end
	assign pb_debounced = ((DFF == 4'b1111) ? 1'b1 : 1'b0);

endmodule

module onepulse(pb_debounced, clk, pb_1pulse);	
	input pb_debounced;	
	input clk;	
	output pb_1pulse;	

	reg pb_1pulse;	
	reg pb_debounced_delay;	

	always@(posedge clk) begin
		pb_1pulse <= pb_debounced & (! pb_debounced_delay);
		pb_debounced_delay <= pb_debounced;
	end	
endmodule