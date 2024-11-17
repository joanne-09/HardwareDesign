module lab5_2 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire hint,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output reg hysnc,
    output reg vsync,
    output reg pass
);
    // add your design here
    parameter INIT = 0, SHOW = 1, GAME = 2, FINISH = 3;

    reg [1:0] state, next_state;

    debounce db(.clk(clk), .pb_deobunde(db_start), .pb(start));
    one_pulse op(.clk(clk), .pb_in(db_start), .pb_out(op_start));

    always @(posedge clk) begin
        if (rst) state <= INIT;
        else state <= next_state;
    end

    always @(*) begin
        case(state)
            INIT: begin
                if(op_start) next_state = SHOW;
                else next_state = INIT;
            end
            SHOW: begin
                if(op_start) next_state = GAME;
                else next_state = SHOW;
            end
        endcase
    end

endmodule