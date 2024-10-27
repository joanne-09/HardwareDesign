module lab3_advanced (
    input wire clk,
    input wire rst,
    input wire right,
    input wire left,
    input wire up,
    input wire down,
    output [3:0] DIGIT,
    output reg [6:0] DISPLAY
);

    wire clk_1sec, clk_fill;
    reg [1:0] cycle_cnt, cycle_fill;
    clock_divider #(.n(27)) m27(.clk(clk), .clk_div(clk_1sec));
    clock_divider #(.n(26)) m25(.clk(clk), .clk_div(clk_fill));

    // set up one pulse for each button
    // ont hot encoding for direction
    wire [3:0] dir_pulse;
    delay_one_pulse m_right(.clk(clk), .pb_in(right), .pb_out(dir_pulse[3]));
    delay_one_pulse m_left(.clk(clk), .pb_in(left), .pb_out(dir_pulse[2]));
    delay_one_pulse m_up(.clk(clk), .pb_in(up), .pb_out(dir_pulse[1]));
    delay_one_pulse m_down(.clk(clk), .pb_in(down), .pb_out(dir_pulse[0]));

    reg [1:0] state, next_state;
    parameter INITIAL = 0, MOVING = 1, FILLING = 2;
    parameter RIGHT = 8, LEFT = 4, UP = 2, DOWN = 1;
    reg [3:0] facing, next_facing;
    reg [2:0] state_display, next_state_display;
    reg [6:0] out;

    // FF for changing state
    always @(posedge clk, posedge rst) begin
        if(rst) state <= INITIAL;
        else state <= next_state;
    end

    // FF for changing display
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_display <= 6;
            facing <= LEFT;
            out <= 0;
        end else begin
            if(state == INITIAL) begin
                state_display <= 6;
                facing <= LEFT;
                out <= 0;
            end else if(state == FILLING) begin
                state_display <= next_state_display;
                facing <= next_facing;
                out[next_state_display] <= 1;
            end else begin
                state_display <= next_state_display;
                facing <= next_facing;
                out <= 0;
            end
        end
    end

    // set INITIAL state counter
    always @(posedge clk_1sec, posedge rst) begin
        if (rst) begin
            cycle_cnt <= 2'b00;
            cycle_fill <= 2'b00;
        end else begin
            if(state == INITIAL) begin 
                cycle_cnt <= cycle_cnt + 1;
                cycle_fill <= 2'b00;
            end else begin
                if(out == 7'b1111111) begin
                    cycle_cnt <= 2'b00;
                    cycle_fill <= cycle_fill + 1;
                end else begin
                    cycle_cnt <= 2'b00;
                    cycle_fill <= 2'b00;
                end
            end
        end
    end

    // only using right most 7-segment display
    assign DIGIT = 4'b1110;

    // FSM
    always @(*) begin
        case(state)
            INITIAL: begin
                if (cycle_cnt == 3) next_state = MOVING;
                else next_state = INITIAL;
            end
            MOVING: begin
                if(dir_pulse == DOWN) next_state = FILLING;
                else next_state = MOVING;
            end
            FILLING: begin
                if(cycle_fill == 2'b10) next_state = INITIAL;
                else next_state = FILLING;
            end
        endcase
    end
    
    // handle 7-segment display switching
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            DISPLAY <= 7'b1111111;
        end else begin
            case(state)
                INITIAL: begin
                    DISPLAY <= ~(1 << state_display);
                end
                MOVING: begin
                    if(clk_1sec) DISPLAY <= ~(1 << state_display);
                    else DISPLAY <= 7'b1111111;
                end
                FILLING: begin
                    if(clk_1sec) DISPLAY <= ~(out | (1 << state_display));
                    else DISPLAY <= ~(out & ~(1 << state_display));
                end
            endcase
        end
    end

    // switch state and facing direction
    always @(*) begin
        case(state_display)
            6: begin
                if(facing == LEFT)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 5;
                        next_facing = UP;
                    end else if(dir_pulse == LEFT) begin 
                        next_state_display = 4;
                        next_facing = DOWN;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == RIGHT)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 2;
                        next_facing = DOWN;
                    end else if(dir_pulse == LEFT) begin 
                        next_state_display = 1;
                        next_facing = UP;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            5: begin
                if(facing == UP)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 0;
                        next_facing = RIGHT;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == DOWN)
                    if(dir_pulse == LEFT) begin 
                        next_state_display = 6;
                        next_facing = RIGHT;
                    end else if(dir_pulse == UP) begin 
                        next_state_display = 3;
                        next_facing = DOWN;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            4: begin
                if(facing == DOWN)
                    if(dir_pulse == LEFT) begin
                        next_state_display = 3;
                        next_facing = RIGHT;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == UP)
                    if(dir_pulse == RIGHT) begin
                        next_state_display = 6;
                        next_facing = RIGHT;
                    end else if(dir_pulse == UP) begin
                        next_state_display = 5;
                        next_facing = UP;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            3: begin
                if(facing == LEFT)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 4;
                        next_facing = UP;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == RIGHT)
                    if(dir_pulse == LEFT) begin 
                        next_state_display = 2;
                        next_facing = UP;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            2: begin
                if(facing == DOWN)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 3;
                        next_facing = LEFT;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == UP)
                    if(dir_pulse == LEFT) begin 
                        next_state_display = 6;
                        next_facing = LEFT;
                    end else if(dir_pulse == UP) begin 
                        next_state_display = 1;
                        next_facing = UP;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            1: begin
                if(facing == UP)
                    if(dir_pulse == LEFT) begin 
                        next_state_display = 0;
                        next_facing = LEFT;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == DOWN)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 6;
                        next_facing = LEFT;
                    end else if(dir_pulse == UP) begin 
                        next_state_display = 2;
                        next_facing = DOWN;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            0: begin
                if(facing == LEFT)
                    if(dir_pulse == LEFT) begin 
                        next_state_display = 5;
                        next_facing = DOWN;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else if(facing == RIGHT)
                    if(dir_pulse == RIGHT) begin 
                        next_state_display = 1;
                        next_facing = DOWN;
                    end else begin
                        next_state_display = state_display;
                        next_facing = facing;
                    end
                else begin
                    next_state_display = state_display;
                    next_facing = facing;
                end
            end
            default: begin
                next_state_display = state_display;
                next_facing = facing;
            end
        endcase
    end
endmodule

module delay_one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
);
    wire pb_debounced;
    debounce m_debounce(.clk(clk), .pb(pb_in), .pb_debounced(pb_debounced));
    one_pulse m_one_pulse(.clk(clk), .pb_in(pb_debounced), .pb_out(pb_out_tmp));

    always @(posedge clk) begin
        pb_out <= pb_out_tmp;
    end
endmodule

// Clock Divider Module
module clock_divider (clk, clk_div);
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