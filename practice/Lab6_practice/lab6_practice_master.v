module lab6_practice_master (
	input wire clk,
	input wire rst,
	input wire [7:0] sw, // switches
	output reg [3:0] data_out  // data (number) to slave 
);

// add your design here
wire is_ont_hot;
assign is_ont_hot = (sw != 0 && (sw & (sw - 1)) == 0);

always @(posedge clk) begin
	if(rst) data_out <= 4'b1000;
	else begin
		if(sw[0] && is_ont_hot) data_out <= 0;
		else if(sw[1] && is_ont_hot) data_out <= 1;
		else if(sw[2] && is_ont_hot) data_out <= 2;
		else if(sw[3] && is_ont_hot) data_out <= 3;
		else if(sw[4] && is_ont_hot) data_out <= 4;
		else if(sw[5] && is_ont_hot) data_out <= 5;
		else if(sw[6] && is_ont_hot) data_out <= 6;
		else if(sw[7] && is_ont_hot) data_out <= 7;
		else data_out <= 4'b1000;
	end
end
endmodule

