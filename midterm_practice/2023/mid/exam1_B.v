`define WIDTH 12

module exam1_B(
    input wire clk,
    input wire rst,
    input wire signed [`WIDTH-1:0] data,
    output reg [7:0] decoded,// You can modify "reg" to "wire" if needed
    output reg [2:0] out // You can modify "reg" to "wire" if needed
);
    reg [3:0] error_bit;
    reg [11:0] right_data;
    reg [7:0] out_data;
    always @(*) begin
        error_bit[3] = data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[11];
        error_bit[2] = data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[11];
        error_bit[1] = data[1] ^ data[2] ^ data[5] ^ data[6] ^ data[9] ^ data[10];
        error_bit[0] = data[0] ^ data[2] ^ data[4] ^ data[6] ^ data[8] ^ data[10];
    end

    always @(*) begin
        if(error_bit == 0) right_data = data;
        else right_data = data ^ (1 << (error_bit-1));
    end

    always @(posedge clk) begin
        if(rst) begin
            decoded <= 0;
            out <= 0;
        end else begin
            decoded <= {right_data[11:8], right_data[6:4], right_data[2]};
            case(right_data[11:10])
                2'b00: out <= {right_data[9:8], right_data[6]} & {right_data[5:4], right_data[2]};
                2'b01: out <= {right_data[9:8], right_data[6]} | {right_data[5:4], right_data[2]};
                2'b10: out <= {right_data[9:8], right_data[6]};
                default: out <= {right_data[5:4], right_data[2]};
            endcase
        end
    end
    
endmodule