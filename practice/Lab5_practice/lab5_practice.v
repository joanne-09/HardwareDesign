module lab5_practice (
    input wire clk,
    input wire rst,
    input wire [2:0] addr,
    input wire we, 
    input wire [7:0] din,
    input wire re,
    input wire start,
    output reg [7:0] dout,
    output reg done,
    output reg [7:0] ans
);
    // add your design here
    // note that you are free to adjust the IO's data type
    reg start_accu, delay_re;
    reg [2:0] accu_addr;
    reg [7:0] memory [0:5];
    reg [7:0] read_data, sum;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            dout <= 8'b0;
            done <= 1'b0;
            ans <= 8'b0;
            sum <= 8'b0;
            accu_addr <= 3'b0;
        end else begin
            dout <= 8'b0;
            done <= 1'b0;
            ans <= 8'b0;
            sum <= sum;
            accu_addr <= accu_addr;
            if(we) begin
                memory[addr-1] <= din;
            end else if(delay_re) begin
                dout <= memory[addr-1];
            end else if(start_accu && accu_addr != 5) begin
                accu_addr <= accu_addr + 1;
                if(memory[accu_addr] != 8'bX)
                    sum <= sum + memory[accu_addr];
            end else if(accu_addr == 5) begin
                done <= 1;
                accu_addr <= 3'b0;
                ans <= sum;
                sum <= 8'b0;
            end
        end
    end
    // delayed read
    always @(posedge clk, posedge rst) begin
        if(rst) delay_re <= 0;
        else delay_re <= re;
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            start_accu <= 1'b0;
        end else begin
            if(start) begin
                start_accu <= 1'b1;
            end else if(done) begin
                start_accu <= 1'b0;
            end
        end
    end
    
endmodule