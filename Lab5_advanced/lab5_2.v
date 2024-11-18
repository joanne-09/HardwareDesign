module lab5_2 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire hint,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire hsync,
    output wire vsync,
    output wire pass
);
    parameter INIT = 0, SHOW = 1, GAME = 2, FINISH = 3;
    // grid answer
    parameter [2:0] answer [0:15] = {
        0, 1, 2, 3, 3, 4, 5, 6, 7, 6, 7, 1, 4, 0, 2, 5
    };
    // key codes to check which key is pressed
	parameter [8:0] KEY_CODES [0:17] = {
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
        9'b0_0001_0101, // Q => 15
        9'b0_0001_1101, // W => 1D
        9'b0_0010_0100, // E => 24
        9'b0_0010_1101, // R => 2D
        9'b0_0001_1100, // A => 1C
        9'b0_0001_1011, // S => 1B
        9'b0_0010_0011, // D => 23
        9'b0_0010_1011, // F => 2B
        9'b0_0001_1010, // Z => 1A
        9'b0_0010_0010, // X => 22
        9'b0_0010_0001, // C => 21
        9'b0_0010_1010, // V => 2A
        9'b0_0001_0010, // Left Shift => 12
        9'b0_0101_1010 // Enter => 5A
	};

    // parameter for vga display
    wire [11:0] data;
    wire clk_25MHz, clk22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid, show;
    wire [9:0] h_cnt, v_cnt;  // 640 480

    // parameter for keyboard
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;

    reg [1:0] state, next_state;
    reg [15:0] flipped, mirrored, reveal;
    reg [15:0] nxt_flipped, nxt_mirrored, nxt_reveal;
    wire hintstate;
    reg [4:0] key1, key2, curkey;
    wire op_start;

    debounce db(.clk(clk), .pb_debounced(db_start), .pb(start));
    one_pulse op(.clk(clk), .pb_in(db_start), .pb_out(op_start));

    assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1 && show==1'b1) ? pixel : 12'h0;

    clock_divider #(.n(22)) n22 (.clk(clk), .clk_div(clk22));
    clock_divider #(.n(2)) n2 (.clk(clk), .clk_div(clk_25MHz));

    mem_addr_gen mem_addr_gen_inst(
        .clk(clk22), .rst(rst), .h_cnt(h_cnt), .v_cnt(v_cnt), .flipped(flipped), 
        .mirrored(mirrored), .reveal(reveal), .hintstate(hintstate), .pixel_addr(pixel_addr), .show(show)
    );
    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_25MHz), .wea(0), .addra(pixel_addr), .dina(data[11:0]), .douta(pixel)
    );
    vga_controller   vga_inst(
        .pclk(clk_25MHz), .reset(rst), .hsync(hsync),
        .vsync(vsync), .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt)
    );
    KeyboardDecoder key_de (
		.key_down(key_down), .last_change(last_change), .key_valid(key_valid),
		.PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK), .rst(rst), .clk(clk)
	);

    // state FSM
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
            GAME: begin
                if(flipped == 16'hFFFF) next_state = FINISH;
                else next_state = GAME;
            end
            FINISH: begin
                if(op_start) next_state = INIT;
                else next_state = FINISH;
            end
        endcase
    end

    // handle flipped, mirrored, reveal
    always @(posedge clk) begin
        case(state)
            INIT: begin
                flipped <= 16'h0000;
                mirrored <= 16'h8208;
                reveal <= 16'h0000;
            end
            SHOW: begin
                flipped <= 16'h0000;
                mirrored <= 16'h8208;
                reveal <= 16'hFFFF;
            end
            GAME: begin
                flipped <= nxt_flipped;
                mirrored <= nxt_mirrored;
                reveal <= nxt_reveal;
            end
            FINISH: begin
                flipped <= 16'hFFFF;
                mirrored <= 16'h0000;
                reveal <= 16'h0000;
            end
        endcase
    end

    // assign hint state
    assign hintstate = (state == GAME && hint);

    // handle pass LED
    assign pass = (state == FINISH);

    // handle pressed key
    always @(*) begin
        if(state == INIT || state == SHOW || state == FINISH) begin
            key1 = 18;
            key2 = 18;
            nxt_reveal = 16'h0000;
            nxt_flipped = 16'h0000;
            nxt_mirrored = 16'h8208;
        end else begin
            if(key_valid && key_down[last_change] && curkey != 18 && !hint) begin
                if(curkey == 17) begin
                    // check if correct, either turn to black or flip it
                    if(key1 < 16 && key2 < 16) begin
                        if(answer[key1] == answer[key2] && !mirrored[15-key1] && !mirrored[15-key2]) begin
                            nxt_flipped[15-key1] = 1;
                            nxt_flipped[15-key2] = 1;
                        end
                    end
                    key1 = 18;
                    key2 = 18;
                    nxt_reveal = 16'h0000;
                end else begin
                    // select a grid, and should simutaneously press two keys
                    if(key1 == 18) begin
                        // first key is pressed
                        if(curkey < 16 && !flipped[15-curkey]) key1 = curkey;
                        else if(curkey < 16 && flipped[15-curkey]) key1 = 18;
                        else key1 = curkey;
                    end else if(key2 == 18 && key_down[KEY_CODES[key1]] && curkey != key1) begin
                        // second key and first key is pressed
                        key2 = curkey;
                        if(key2 < 16 && flipped[15-key2]) key2 = 18;
                        else if(key1 == 16 && key2 < 16) begin
                            // first press shift and mirror key2
                            nxt_mirrored[15-key2] = !mirrored[15-key2];
                            nxt_reveal[15-key2] = 1;
                        end else if(key1 < 16 && key2 == 16) begin
                            // second press shift and mirror key1
                            nxt_mirrored[15-key1] = !mirrored[15-key1];
                            nxt_reveal[15-key1] = 1;
                        end else if(key1 < 16 && key2 < 16)begin
                            nxt_reveal[15-key2] = 1;
                            nxt_reveal[15-key1] = 1;
                        end
                    end else if(key2 == 18 && !key_down[KEY_CODES[key1]] && curkey != key1) begin
                        // second key and first key is not pressed
                        if(curkey < 16 && !flipped[15-curkey]) key1 = curkey;
                        else if(curkey < 16 && flipped[15-curkey]) key1 = 18;
                        else key1 = curkey;
                    end
                end
            end
        end
    end

    // current pressed key
    always @(*) begin
        case(last_change)
            KEY_CODES[0] : curkey = 0;
            KEY_CODES[1] : curkey = 1;
            KEY_CODES[2] : curkey = 2;
            KEY_CODES[3] : curkey = 3;
            KEY_CODES[4] : curkey = 4;
            KEY_CODES[5] : curkey = 5;
            KEY_CODES[6] : curkey = 6;
            KEY_CODES[7] : curkey = 7;
            KEY_CODES[8] : curkey = 8;
            KEY_CODES[9] : curkey = 9;
            KEY_CODES[10]: curkey = 10;
            KEY_CODES[11]: curkey = 11;
            KEY_CODES[12]: curkey = 12;
            KEY_CODES[13]: curkey = 13;
            KEY_CODES[14]: curkey = 14;
            KEY_CODES[15]: curkey = 15;
            KEY_CODES[16]: curkey = 16; // shift
            KEY_CODES[17]: curkey = 17; // enter
            default: curkey = 18;
        endcase
    end

endmodule

module mem_addr_gen(
    input wire clk,
    input wire rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [15:0] flipped,
    input [15:0] mirrored,
    input [15:0] reveal,
    input hintstate,
    output [16:0] pixel_addr,
    output show
);
    
    reg [1:0] x_offset, y_offset;
    reg [8:0] out_x, out_y;
    assign pixel_addr = (out_x + 320 * out_y) % 76800;  //640*480 --> 320*240
    assign show = (flipped[(3 - x_offset) + (3 - y_offset) * 4] || reveal[(3 - x_offset) + (3 - y_offset) * 4] || hintstate);

    always @(*) begin
        if((h_cnt >> 1) < 80) x_offset = 0;
        else if((h_cnt >> 1) < 160 && (h_cnt >> 1) >= 80) x_offset = 1;
        else if((h_cnt >> 1) < 240 && (h_cnt >> 1) >= 160) x_offset = 2;
        else x_offset = 3;
    end

    always @(*) begin
        if((v_cnt >> 1) < 60) y_offset = 0;
        else if((v_cnt >> 1) < 120 && (v_cnt >> 1) >= 60) y_offset = 1;
        else if((v_cnt >> 1) < 180 && (v_cnt >> 1) >= 120) y_offset = 2;
        else y_offset = 3;
    end

    // check if the pixel is mirrored area
    always @(*) begin
        out_x = (h_cnt >> 1);
    end

    always @(*) begin
        if(mirrored[(3 - x_offset) + (3 - y_offset) * 4] && !hintstate) 
            out_y = 60 * y_offset + 59 - ((v_cnt >> 1) - 60 * y_offset);
        else out_y = (v_cnt >> 1);
    end
    
endmodule