`timescale 10ps/1ps

`define PATTERN_NUM 24
`define CYCLE 10
module lab2_2_tb;

    reg clk, rst;
    wire [15:0] out;

    reg [15:0] mem[0:`PATTERN_NUM-1];
    reg pass, feed_finish;
    
    lab2_2 counter(
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end

    integer i;
    integer scores;

    initial begin
        // input feeding init
        $readmemh("pattern_B.dat", mem);
        if(mem[1] !== 16'h2) begin
            $display(">>>>>>>>>>> [ERROR] Can not find patter_B.dat, make sure you have added it to simulation source!");
            $finish;
        end

        pass = 1'b1;
        feed_finish = 1'b0;

        #(`CYCLE);
        rst = 1'b1;
        #(`CYCLE);
        rst = 1'b0;

        for(i = 0; i < `PATTERN_NUM; i = i+1) begin
            @(negedge clk);
            if(out !== mem[i]) begin
                pass = 1'b0;
                $display("[COUNT ERROR] i:%d, out:%d, mem:%d", i+1, out, mem[i]);
            end
        end
        // #(`CYCLE);
        feed_finish = 1'b1;
        
        #(`CYCLE*10);
        rst = 1'b1;

        // Check
        if(pass) begin
            $display("====================PASS!====================");
        end
        else begin
            $display("====================FAIL!====================");
        end

        $finish;
    end

endmodule