`timescale 1ns / 1ps

module lab3_practice ( 
    input wire clk,
    input wire rst,
    input wire speed,
    output reg [15:0] led
); 
    /* Note that output ports can be either reg or wire. 
    * It depends on how you design your module. */
    // add your design here

    // clock divider instance example
    wire clk_div27, clk_div28;
    reg n_clk;
    clock_divider #(.n(27)) m27(.clk(clk), .clk_div(clk_div27));
    clock_divider #(.n(28)) m28(.clk(clk), .clk_div(clk_div28));

    // FSM example
    reg [1:0] state, next_state;
    reg [15:0] next_slow, next_fast;
    parameter INITIAL = 0, SLOW = 1, FAST = 2;

    // set next clk frequency
    always @(*) begin
        if(speed == 1) begin
            n_clk = clk_div27;
        end else begin
            n_clk = clk_div28;
        end
    end

    // F/F transition
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= INITIAL;
        end
        else begin
            state <= next_state;
        end
    end

    // set led light by state
    always @(posedge n_clk, posedge rst) begin
        if(rst) begin
            led <= 16'b1111111111111111;
            next_slow <= 1 << 15;
            next_fast <= 1 << 15;
        end else begin
            case(state)
                INITIAL: begin
                    led <= 16'b1111111111111111;
                    next_slow <= 1 << 15;
                    next_fast <= 1 << 15;
                end
                SLOW: begin
                    led <= next_slow;
                    next_slow <= {next_slow[0], next_slow[15:1]};
                    next_fast <= 1 << 15;
                end
                FAST: begin
                    led <= next_fast;
                    next_fast = {next_fast[0], next_fast[15:1]};
                    next_slow <= 1 << 15;
                end
            endcase
        end
    end

    // FSM
    always @(*) begin
        case(state)
            INITIAL: begin
                next_state = SLOW;
            end
            SLOW: begin
                if(speed == 1) begin
                    next_state = FAST;
                end else begin
                    next_state = SLOW;
                end
            end
            FAST: begin
                if(speed == 1) begin
                    next_state = FAST;
                end else begin
                    next_state = SLOW;
                end
            end
            default: begin
                next_state = state;
            end
        endcase
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