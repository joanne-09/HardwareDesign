module lab2_adv_2(
    input clk,
    input rst,
    input [4:0] raw_data,
    input [9:0] error_bit_input,
    output wire [9:0] received_data,
    output reg [3:0] error_index,
    output reg multiple_error
);

// Output signals can be reg or wire
// add your design here
reg [3:0] H, temp_error_idx;
reg Hn, temp_errors;
reg [9:0] hamming_code, t_ham, temp_data;

// handling error bit
always @* begin
    hamming_code = t_ham ^ error_bit_input;
end

// encode hamming code
always @* begin
    t_ham[7] = raw_data[4];
    t_ham[5] = raw_data[3];
    t_ham[4] = raw_data[2];
    t_ham[3] = raw_data[1];
    t_ham[1] = raw_data[0];

    t_ham[9] = raw_data[4] ^ raw_data[3] ^ raw_data[1] ^ raw_data[0];
    t_ham[8] = raw_data[4] ^ raw_data[2] ^ raw_data[1];
    t_ham[6] = raw_data[3] ^ raw_data[2] ^ raw_data[1];
    t_ham[2] = raw_data[0];

    t_ham[0] = raw_data[0] ^ raw_data[2] ^ raw_data[3] ^ raw_data[4];
end

always @* begin
    H[0] = hamming_code[9] ^ hamming_code[7] ^ hamming_code[5] ^ hamming_code[3] ^ hamming_code[1];
    H[1] = hamming_code[8] ^ hamming_code[7] ^ hamming_code[4] ^ hamming_code[3];
    H[2] = hamming_code[6] ^ hamming_code[5] ^ hamming_code[4] ^ hamming_code[3];
    H[3] = hamming_code[2] ^ hamming_code[1];
    Hn = hamming_code[0] ^ hamming_code[1] ^ hamming_code[2] ^ hamming_code[3] ^ hamming_code[4] ^ hamming_code[5] ^ hamming_code[6] ^ hamming_code[7] ^ hamming_code[8] ^ hamming_code[9];

    if(H == 0) begin
        if(Hn == 0) begin
            // no error
            temp_error_idx = 0;
            temp_errors = 0;
        end else begin
            // error at pn
            temp_error_idx = 10;
            temp_errors = 0;
        end
    end else if(H > 10) begin
        temp_error_idx = 0;
        temp_errors = 1;
    end else begin
        if(Hn == 0) begin
            // double bits error
            temp_error_idx = 0;
            temp_errors = 1;
        end else begin
            // error at H
            temp_error_idx = H;
            temp_errors = 0;
        end
    end
end

always @(posedge rst, posedge clk) begin
    if (rst) begin
        temp_data <= 10'b0;
        error_index <= 4'b0;
        multiple_error <= 1'b0;
    end else begin
        temp_data <= hamming_code;
        error_index <= temp_error_idx;
        multiple_error <= temp_errors;
    end
end

assign received_data = temp_data;
endmodule