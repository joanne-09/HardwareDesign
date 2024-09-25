`define WIDTH 8

module lab2_1(
    input wire clk,
    input wire rst,
    input wire signed [`WIDTH-1:0] A,
    input wire signed [`WIDTH-1:0] B,
    input wire ctrl,
    output reg signed [`WIDTH*2-1:0] out // You can modify "reg" to "wire" if needed
);
    //Your design here
    always @(posedge clk) begin
        if(rst) begin
            out <= 0;
        end
        else begin
            if(ctrl == 0) begin
                out <= A * B;
            end
            else if(A < B) begin
                out <= 1;
            end
            else begin
                out <= -1;
            end
        end
    end

endmodule

// You can add any module you need.
// Make sure you include all modules you used in this problem.