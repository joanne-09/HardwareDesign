`timescale 10ps/1ps
`define CYCLE 10

module lab5_t;
    reg clk, rst;
    reg [2:0] addr;
    reg re, we, start;
    reg [7:0] din;
    wire [7:0] dout, ans;
    wire done;

    lab5_practice l5(.clk(clk), .rst(rst), .addr(addr), .re(re), .we(we), .start(start), .din(din), .dout(dout), .done(done), .ans(ans));

    // set clock cycle
    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end

    // set reset value
    initial begin
        we = 0; re = 0; start = 0;
        addr = 3'b0; din = 8'b0;
        #(`CYCLE);
        rst = 1'b1;
        #(`CYCLE);
        rst = 1'b0;
    end

    initial begin
        @(negedge rst);
        #(`CYCLE*3);
        we = 1;
        #(`CYCLE);
        we = 0;
        #(`CYCLE);
        we = 1;
        #(`CYCLE*2);
        we = 0;
        #(`CYCLE*4);
        re = 1;
        #(`CYCLE);
        re = 0;
        #(`CYCLE*5);
        start = 1;
        #(`CYCLE);
        start = 0;
        #(`CYCLE*10);
        $finish;
    end

    initial begin
        @(negedge rst);
        #(`CYCLE*3);
        addr = 3'd5;
        din = 8'd4;
        #(`CYCLE*2);
        addr = 3'd1;
        din = 8'd8;
        #(`CYCLE);
        addr = 3'd3;
        din = 8'd2;
        #(`CYCLE*5);
        addr = 3'd1;
    end
endmodule