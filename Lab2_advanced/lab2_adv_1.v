`timescale 1ns/1ps
module lab2_adv_1 (
    input clk,
    input rst_n, 
    input [11:0] code, 
    output reg [3:0] out,
    output reg [7:0] raw_data,
    output reg err,
    output reg cor
);

// Output signals can be reg or wire
// add your design here
reg [3:0] H;
reg [11:0] temp_code;
reg [3:0] next_out;
reg [7:0] next_raw_data;
reg [7:0] raw;
reg next_err, next_cor;

always @* begin
    raw[7] = temp_code[9];
    raw[6] = temp_code[7];
    raw[5] = temp_code[6];
    raw[4] = temp_code[5];
    raw[3] = temp_code[3];
    raw[2] = temp_code[2];
    raw[1] = temp_code[1];
    raw[0] = temp_code[0];
end

always @* begin
    H[0] = code[11] ^ code[9] ^ code[7] ^ code[5] ^ code[3] ^ code[1];
    H[1] = code[10] ^ code[9] ^ code[6] ^ code[5] ^ code[2] ^ code[1];
    H[2] = code[8] ^ code[7] ^ code[6] ^ code[5] ^ code[0];
    H[3] = code[4] ^ code[3] ^ code[2] ^ code[1] ^ code[0];
end

always @* begin
    if(H > 12) begin
        next_out = 4'b0;
        next_raw_data = 8'b0;
        next_err = 1'b1;
        next_cor = 1'b0;
    end
    else if(H != 0) begin
        temp_code = code ^ (1 << (12-H));
        next_out = H;
        next_raw_data = raw;
        next_err = 1'b0;
        next_cor = 1'b0;
    end
    else begin
        temp_code = code;
        next_out = 4'b0;
        next_raw_data = raw;
        next_err = 1'b0;
        next_cor = 1'b1;
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        out <= 4'b0;
        raw_data <= 8'b0;
        err <= 1'b0;
        cor <= 1'b0;
    end 
    else begin
        out <= next_out;
        raw_data <= next_raw_data;
        err <= next_err;
        cor <= next_cor;
    end
end
endmodule
