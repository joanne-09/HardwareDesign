`timescale 1ns / 1ps

module lab3_basic ( 
    input wire clk,
    input wire rst,
    input wire restart,
    input wire [9:0] SW,
    output reg [9:0] led
); 
    /* Note that output ports can be either reg or wire. 
    * It depends on how you design your module. */
    // add your design here

    // clock divider instance example
    wire fsm_clk, finish_clk;
    clock_divider #(.n(10)) m10(.clk(clk), .clk_div(fsm_clk));
    clock_divider #(.n(27)) m27(.clk(clk), .clk_div(finish_clk));

    // FSM example
    reg n_clk;
    reg [1:0] state, next_state;
    reg [9:0] prev_SW, next_led, changed_led;
    parameter INITIAL = 0;
    parameter PLAYING = 1;
    parameter FINISH = 2;

    always @* begin
        if(state == FINISH) n_clk = finish_clk;
        else n_clk = clk;
    end

    always @(posedge fsm_clk, posedge rst) begin
        if(rst) begin
            state <= INITIAL;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case(state)
            INITIAL: begin
                if(restart) next_state = INITIAL;
                else next_state = PLAYING;
            end
            PLAYING: begin
                if(led == 0) next_state = FINISH;
                else next_state = PLAYING;
            end
            FINISH: begin
                if(restart) next_state = INITIAL;
                else next_state = FINISH;
            end
            default: begin
                next_state = state;
            end
        endcase
    end

    always @* begin
        if(SW[9] != prev_SW[9]) changed_led = 10'b1100000000;
        else if(SW[8] != prev_SW[8]) changed_led = 10'b1110000000;
        else if(SW[7] != prev_SW[7]) changed_led = 10'b0111000000;
        else if(SW[6] != prev_SW[6]) changed_led = 10'b0011100000;
        else if(SW[5] != prev_SW[5]) changed_led = 10'b0001110000;
        else if(SW[4] != prev_SW[4]) changed_led = 10'b0000111000;
        else if(SW[3] != prev_SW[3]) changed_led = 10'b0000011100;
        else if(SW[2] != prev_SW[2]) changed_led = 10'b0000001110;
        else if(SW[1] != prev_SW[1]) changed_led = 10'b0000000111;
        else if(SW[0] != prev_SW[0]) changed_led = 10'b0000000011;
        else changed_led = 10'b0000000000;
    end

    always @(posedge n_clk, posedge rst) begin
        if(rst) begin
            led <= 10'b0010010000;
            next_led <= 10'b0010010000;
            prev_SW <= SW;
        end else begin
            case(state)
                INITIAL: begin
                    led <= 10'b0010010000;
                    next_led <= 10'b0010010000;
                    prev_SW <= SW;
                end
                PLAYING: begin
                    led <= next_led;
                    next_led <= next_led ^ changed_led;
                    prev_SW <= SW;
                end
                FINISH: begin
                    led <= next_led;
                    next_led <= next_led ^ 10'b1111111111;
                    prev_SW <= SW;
                end
            endcase
        end
    end

endmodule

module clock_divider #(
    parameter n = 10
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule