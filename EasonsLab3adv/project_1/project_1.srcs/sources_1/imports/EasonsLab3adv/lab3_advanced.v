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

    wire clk26, clk27;
    clock_divider #(.n(27)) m27(.clk(clk), .clk_div(clk27));
    clock_divider #(.n(26)) m26(.clk(clk), .clk_div(clk26));

    debounce d1(clk, right, de_right);
    debounce d2(clk, left, de_left);
    debounce d3(clk, up, de_up);
    debounce d4(clk, down, de_down);

    one_pulse p1(clk, de_right, pulse_right);
    one_pulse p2(clk, de_left, pulse_left);
    one_pulse p3(clk, de_up, pulse_up);
    one_pulse p4(clk, de_down, pulse_down);
    
    
    parameter INITIAL = 0, MOVING = 1, FILLING = 2;
    parameter UP = 4'b1000, RIGHT = 4'b0100, DOWN = 4'b0010, LEFT = 4'b0001;
    reg [3:0] buttons;
    always @(*) begin //one hot encode buttons
        buttons = {pulse_up, pulse_right, pulse_down, pulse_left};
    end
    //fsm

    wire tomoving, tofilling;
    reg toinitial;

    //3 seconds counter
    parameter n = 3;
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    always@(posedge clk27) begin
        num <= next_num;
    end
    assign next_num = toinitial == 0 || rst == 0 ? num + 1 : 0;
    assign tomoving = num[n-1];
    assign tofilling = pulse_down;
    //fsm
    reg [1:0] state, next_state;
    wire activate;
    n_sec_timer #(.n(1)) timer(.onesec_clk(clk27), .activate(activate), .timesup(toinitial));
    always@* begin
        case(state)
            INITIAL: begin
                if(tomoving) next_state = MOVING;
                else next_state = INITIAL;
            end    
            MOVING: begin
                if(tofilling) next_state = FILLING;
                else next_state = MOVING;
            end
            FILLING: begin
                if(toinitial) next_state = INITIAL;
                else next_state = FILLING;
            end
        endcase
    end

    //state transition
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= INITIAL;
        end
        else begin
            state <= next_state;
        end
    end
    //assign to display
    reg [6:0] segment, next_segment; //GFEDCBA
    reg [3:0] dir, next_dir;
    parameter A = 7'b1111110, B = 7'b1111101, C = 7'b1111011, D = 7'b1110111, E = 7'b1101111, F = 7'b1011111, G = 7'b0111111;
    parameter DIRUP = 4'b1000, DIRRIGHT = 4'b0100, DIRDOWN = 4'b0010, DIRLEFT = 4'b0001;
    always@(*) begin
        // Default: keep current state and direction
        next_segment <= segment;
        next_dir <= dir;
        case(state)
            INITIAL: begin
                next_segment <= G;
                next_dir <= DIRLEFT;
            end
            MOVING, FILLING: begin
                case (segment)
                    G: 
                        if(dir == DIRLEFT && buttons == RIGHT) begin
                            next_segment <= F;
                            next_dir <= DIRUP;
                        end else if(dir == DIRLEFT && buttons == LEFT) begin
                            next_segment <= E;
                            next_dir <= DIRDOWN;
                        end else if(dir == DIRRIGHT && buttons == RIGHT) begin
                            next_segment <= C;
                            next_dir <= DIRDOWN;
                        end else if(dir == DIRRIGHT && buttons == LEFT) begin
                            next_segment <= B;
                            next_dir <= DIRUP;
                        end
                    F:
                        if(dir == DIRUP && buttons == RIGHT) begin
                            next_segment <= A;
                            next_dir <= DIRRIGHT;
                        end else if(dir == DIRDOWN && buttons == LEFT) begin
                            next_segment <= G;
                            next_dir <= DIRRIGHT;
                        end else if(dir == DIRDOWN && buttons == UP) begin
                            next_segment <= E;
                            next_dir <= DIRDOWN;
                        end else begin
                            next_segment <= F;
                        end
                    E:
                        if(dir == DIRDOWN && buttons == LEFT) begin
                            next_segment <= D;
                            next_dir <= DIRRIGHT;
                        end else if(dir == UP && buttons == RIGHT) begin
                            next_segment <= G;
                            next_dir <= DIRRIGHT;
                        end else if(dir == UP && buttons == UP) begin
                            next_segment <= F;
                            next_dir <= UP;
                        end else begin
                            next_segment <= E;
                        end
                    D:
                        if(dir == DIRRIGHT && buttons == LEFT) begin
                            next_segment <= C;
                            next_dir <= DIRUP;
                        end else if(dir == DIRLEFT && buttons == RIGHT) begin
                            next_segment <= E;
                            next_dir <= DIRUP;
                        end else begin
                            next_segment <= D;
                        end
                    C:
                        if(dir == UP && buttons == UP) begin
                            next_segment <= B;
                            next_dir <= DIRUP;
                        end else if(dir == UP && buttons == LEFT) begin
                            next_segment <= G;
                            next_dir <= DIRLEFT;
                        end else if(dir == DIRDOWN && buttons == RIGHT) begin
                            next_segment <= D;
                            next_dir <= DIRLEFT;
                        end else begin
                            next_segment <= C;
                        end
                    B:
                        if(dir == DIRUP && buttons == LEFT) begin
                            next_segment <= A;
                            next_dir <= DIRLEFT;
                        end else if(dir == DOWN && buttons == UP) begin
                            next_segment <= C;
                            next_dir <= DIRDOWN;
                        end else if(dir == DOWN && buttons == RIGHT) begin
                            next_segment <= G;
                            next_dir <= DIRLEFT;
                        end else begin
                            next_segment <= B;
                        end
                    A: 
                        if(dir == DIRLEFT && buttons == LEFT) begin
                            next_segment <= F;
                            next_dir <= DIRDOWN;
                        end else if(dir == DIRRIGHT && buttons == RIGHT) begin
                            next_segment <= B;
                            next_dir <= DIRDOWN;
                        end else begin
                            next_segment <= A;
                        end
                    default:
                        next_segment <= 7'b0000000;
                endcase         
            end
            default: begin
                next_segment <= 7'b0111111;
            end
        endcase
    end


    //one second counter
    reg [6:0] visited, filled, head;
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            segment <= G;
            dir <= DIRLEFT;
            visited <= 7'b0000000;
            filled <= 7'b1111111;
            toinitial <= 0;
        end
        else begin
            segment <= next_segment;
            dir <= next_dir;
            case(state)
                INITIAL: begin
                    visited <= 7'b0000000;
                    filled <= 7'b1111111;
                    head <= G;
                    toinitial <= 0;
                end
                MOVING: begin
                    head <= segment;
                end
                FILLING: begin
                    visited <= visited | ~segment;
                    filled <= ~visited;
                    head <= segment;
                    if(visited == 7'b1111111) begin
                        segment <= G;
                        dir <= DIRLEFT;
                        visited <= 7'b0000000;
                        filled <= 7'b1111111;
                        toinitial <= 1;
                    end
                end
            endcase
        end
    end
    SevenSegment ss(.clk(clk), .clk27(clk27), .rst(rst), .filled(filled), .state(state), .head(head), .digit(DIGIT), .display(DISPLAY));

endmodule

module n_sec_timer #(
    parameter n = 1
)(
    input wire onesec_clk,
    input wire activate,
    output wire timesup
);
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    always@(posedge onesec_clk) begin
        if(activate)
            num <= next_num;
        else num <= 0;
    end
    assign next_num = num + 1;
    assign timesup = num[n-1];
endmodule

module SevenSegment(
    input wire clk,
    input wire clk27,
    input wire rst,
    input wire [2:0] state,
    input wire [6:0] head,
    input wire [6:0] filled,
    output wire [3:0] digit,
    output reg [6:0] display  
);

    assign digit = 4'b1110;
    parameter INITIAL = 0, MOVING = 1, FILLING = 2;
    //reg [6:0] on = segment , off = 7'b1111111;
    reg [6:0] temp, temp2 = 7'b1111111;
    always@(posedge clk) begin
        /*if(clk27) begin
            display = 7'b1111111;
        end else begin
            display = segments;
        end*/
        if(state == INITIAL) begin
            display = head;
        end else if(state == MOVING) begin
            if(clk27) begin
                display = 7'b1111111;
            end else begin
                display = head;
            end 
        end else begin //filling case
            // filled 0->bright, head 1->bright
            if(clk27) begin
                // head should be dark
                //display = filled | head;
                display = filled;
            end else begin
                display = filled;
            end
        end
        
    end


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