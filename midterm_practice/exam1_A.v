`define WIDTH 8

module exam1_A(
    input wire clk,
    input wire rst,
    input wire signed [`WIDTH-1:0] A,
    input wire signed [`WIDTH-1:0] B,
    input wire [1:0] ctrl,
    output reg signed [`WIDTH*2-1:0] out // You can modify "reg" to "wire" if needed
);

    always @(posedge clk) begin
        if(rst) begin
            out <= 0;
        end else begin
            case(ctrl)
                2'b00: out <= A*B + 3;
                2'b01: out <= {A & B, A ^ B};
                2'b11: out <= (A + B) << 2;
                default: begin
                    if(A>>>2 > B) out <= 1;
                    else out <= -1;
                end
            endcase
        end
    end
    
endmodule