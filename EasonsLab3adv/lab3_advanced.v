module lab3_advanced (
    input wire clk,
    input wire rst,
    input wire right,
    input wire left,
    input wire up,
    input wire down,
    output [3:0] DIGIT,
    output [6:0] DISPLAY
);
    
    clock_divider #(.n(27)) m27(.clk(clk), .clk_div(d27_clk));
    clock_divider #(.n(26)) m26(.clk(clk), .clk_div(d26_clk));

    assign main_clk = d26_clk;

    debounce d1(clk, right, de_right);
    debounce d2(clk, left, de_left);
    debounce d3(clk, up, de_up);
    debounce d4(clk, down, de_down);

    one_pulse p1(clk, de_right, pulse_right);
    one_pulse p2(clk, de_left, pulse_left);
    one_pulse p3(clk, de_up, pulse_up);
    one_pulse p4(clk, de_down, pulse_down);

    wire allfilled;
    reg [1:0] fsmstate;
    reg [6:0] segments;
    reg [3:0] buttons;
    parameter UP = 4'b1000, RIGHT = 4'b0100, DOWN = 4'b0010, LEFT = 4'b0001;
    always @(*) begin //one hot encode buttons
        case({up, right, down, left})
            4'b1000: buttons = UP;
            4'b0100: buttons = RIGHT;
            4'b0010: buttons = DOWN;
            4'b0001: buttons = LEFT;
            default: buttons = 4'b0000;
        endcase
    end
    FSM fsm(.clk27(clk27), .rst(rst), .down_bnt(pulse_down), .allfilled(allfilled), .curstate(fsmstate));

    Snake snake(.clk(clk), .rst(rst), .buttons(buttons), .fsmstate(fsmstate), .segments(segments), .allfilled(allfilled));

    SevenSegment sv(.clk(clk26), .clk26(clk26), .rst(rst), .segments(segments), .digit(DIGIT), .display(DISPLAY));
endmodule


module Snake  (
    input wire clk,
    input wire rst,
    input wire [3:0] buttons, //up(1000), right(0100), down(0010), left(0001)
    input wire [1:0] fsmstate,
    output reg allfilled,
    output reg [6:0] segments
);
    parameter INITIAL = 0, MOVING = 1, FILLING = 2;
    parameter UP = 4'b1000, RIGHT = 4'b0100, DOWN = 4'b0010, LEFT = 4'b0001;
    always@(posedge clk, posedge rst) begin
        case(fsmstate)
            INITIAL: begin
                segments <= 7'b1111110;
            end
            MOVING: begin
                segments <= 7'b0000001;
            end

            FILLING: begin 
                segments <= 7'b0000001;
            end
            default:
                segments <= 7'b0000000;
        endcase  
    end

endmodule

module SevenSegment(
    input wire clk,
    input wire clk26,
    input wire rst,
    input wire [6:0] segments,
    output wire [3:0] digit,
    output reg [6:0] display
);
    assign digit = 4'b1110;

    reg [6:0] next_segments = 7'b1111110, temp = 7'b1111111;

    always@(clk) begin
        display <= next_segments;
    end

    always@(clk26) begin
        next_segments <= temp;
        temp <= next_segments;
    end
endmodule

module FSM(
    input wire clk27,
    input wire rst,
    input wire down_bnt,
    input wire allfilled,
    output wire [1:0] curstate
    );
    parameter INITIAL = 0, MOVING = 1, FILLING = 2;
    reg [1:0] state, next_state;
    wire tomoving, tofilling, toinitial;

    assign tofilling = down_bnt;
    assign toinitial = allfilled;

    always@* begin
        case(state)
            INITIAL: begin
                if(tomoving) next_state <= MOVING;
                else next_state <= INITIAL;
            end
            MOVING: begin
                if(tofilling) next_state <= FILLING;
                else next_state <= MOVING;
            end
            FILLING: begin
                if(toinitial) next_state <= INITIAL;
                else next_state <= FILLING;
            end
        endcase
    end

    always@(posedge clk27, posedge rst) begin
        if(rst) state <= INITIAL;
        else state <= next_state;
    end
    assign curstate = state;

    parameter n = 3; //for 3 seconds
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    always@(posedge clk27) begin
        num <= next_num;
    end
    assign next_num = num + 1;
    assign tomoving = num[n-1];

endmodule


// Clock Divider Module
module clock_divider(clk, clk_div);
    input clk;
    output clk_div;
    parameter n = 25;
    reg[n-1:0] num;
    wire[n-1:0] next_num;
    always @(posedge clk) begin
        num <= next_num;
    end
    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

// Debounce Module
module debounce (
    input wire clk,
    input wire pb,
    output wire pb_debounced
);
    reg [3:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
    assign pb_debounced = (shift_reg == 4'b1111) ? 1'b1 : 1'b0;
endmodule

// One Pulse Module
module one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
);
    reg pb_in_delay;
    always @(posedge clk) begin
        if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
            pb_out <= 1'b1;
        end else begin
            pb_out <= 1'b0;
        end
    end
    always @(posedge clk) begin
        pb_in_delay <= pb_in;
    end
endmodule
// In this lab, you only need to control the rightmost seven-segment display, passing the 7-bit nums directly to control it.
module EXSevenSegment(
 output reg [6:0] display,
 output reg [3:0] digit, 
 input wire [6:0] nums,
 input wire rst,
 input wire clk  // Input 100Mhz clock
);
    
    reg [15:0] clk_divider;
    reg [6:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
     if (rst) begin
      clk_divider <= 15'b0;
     end else begin
      clk_divider <= clk_divider + 15'b1;
     end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
     if (rst) begin
      display_num <= 7'b1111111;
      digit <= 4'b1111;
     end else begin
      case (digit)
       4'b1110 : begin
         display_num <= 7'b1111111;
         digit <= 4'b1101;
        end
       4'b1101 : begin
      display_num <= 7'b1111111;
      digit <= 4'b1011;
     end
       4'b1011 : begin
      display_num <= 7'b1111111;
      digit <= 4'b0111;
     end
       4'b0111 : begin
      display_num <= nums;
      digit <= 4'b1110;
     end
       default : begin
      display_num <= 7'b1111111;
      digit <= 4'b1110;
     end    
      endcase
     end
    end
    
    always @ (*) begin
        display = display_num;
    end
endmodule