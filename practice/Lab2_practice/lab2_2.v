module lab2_2(
    input wire clk,
    input wire rst,
    output reg [15:0] out// You can modify "reg" to "wire" if needed
);
    //Your design here
    reg [15:0] idx;
    
    always @(posedge clk) begin
        if(rst) begin
            out <= 1;
            idx <= 1'b1;
        end
        else begin
            if(out[0] == 1) begin
                out <= (out * 2);
            end
            else begin
                out <= (out + idx);
            end

            idx <= idx + 1;
        end
    end

endmodule

// You can add any module you need.
// Make sure you include all modules you used in this problem.