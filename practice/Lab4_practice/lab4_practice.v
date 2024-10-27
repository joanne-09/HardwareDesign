module lab3_practice(
    input wire clk,
    input wire rst,
    input wire btnL,
    input wire btnR,
    output reg [15:0] LED
);
    used_pulse uprst(.clk(clk), .pb_in(rst), .pb_out(rst_pulse));
    used_pulse upbtnL(.clk(clk), .pb_in(btnL), .pb_out(btnL_pulse));
    used_pulse upbtnR(.clk(clk), .pb_in(btnR), .pb_out(btnR_pulse));

    reg leftDark, rightLight;

    always @(posedge clk) begin
        if(rst_pulse) begin
            LED <= 16'h0000;
            leftDark <= 15;
            rightLight <= 0;
        end else if(btnL_pulse && ~btnR_pulse) begin
            LED[leftDark] <= 1;
            leftDark <= leftDark - 1;
            rightLight <= leftDark;
        end else if(btnR_pulse && ~btnL_pulse) begin
            LED[rightLight] <= 0;
            leftDark <= rightLight;
            rightLight <= rightLight + 1;
        end else begin
            LED <= LED;
            leftDark <= leftDark;
            rightLight <= rightLight;
        end
    end
endmodule

module used_pulse(
    input clk,
    input pb_in,
    output reg pb_out
);
    debounce db(.clk(clk), .pb(pb_in), .pb_debounced(pb_debounced));
    one_pulse op(.clk(clk), .pb_in(pb_debounced), .pb_out(pb_out_tmp));

    always @(posedge clk) begin
        pb_out <= pb_out_tmp;
    end
endmodule