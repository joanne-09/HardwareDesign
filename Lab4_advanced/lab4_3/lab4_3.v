`define silence   32'd50000000
`define c4  32'd131   // C4
`define d4  32'd147   // D4
`define e4  32'd165   // E4
`define f4  32'd175   // F4
`define g4  32'd196   // G4
`define a4  32'd220   // A4
`define b4  32'd247   // B4

module lab4_3(
    input wire clk,
    input wire rst,        // BTNC: active high reset
    input wire volUP,     // BTNU: Vol up
    input wire volDOWN,   // BTND: Vol down
    input wire octaveUP,  // BTNR: Octave up
    input wire octaveDOWN,// BTNL: Octave down
    inout wire PS2_DATA,   // Keyboard I/O
    inout wire PS2_CLK,    // Keyboard I/O
    output reg [4:0] LED,       // LED: [4:0] volume
    output wire audio_mclk, // master clock
    output wire audio_lrck, // left-right clock
    output wire audio_sck,  // serial clock
    output wire audio_sdin, // serial audio data input
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT
    );      
    

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    reg [31:0] mainfreq;
    wire [31:0] freqL, freqR;           // Raw frequency
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    /*------------------ This part does not included in Lab4 ------------------*/
    // wire [11:0] ibeatNum;               // Beat counter

    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    // player_control #(.LEN(128)) playerCtrl_00 ( 
    //     .clk(clkDiv22),
    //     .reset(rst),
    //     ._play(1'b1), 
    //     ._mode(1'b0),
    //     .ibeat(ibeatNum)
    // );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    // music_example music_00 (
    //     .ibeatNum(ibeatNum),
    //     .en(1'b1),
    //     .toneL(freqL),
    //     .toneR(freqR)
    // );
    /*------------------------------------------------------------------------*/

    // clkDiv22
    wire clkDiv16;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for audio
    clock_divider #(.n(16)) clock_16(.clk(clk), .clk_div(clkDiv16));
    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;

    wire [511:0] key_down;
	wire [8:0] last_change, last_key;
	wire key_valid;
	wire available;
    reg [2:0] volume, octave;
    reg [15:0] nums;
    reg [3:0] key_num, note_num;

    parameter [8:0] KEY_CODES [0:6] = {
        9'b0_0001_1100,	// a => 1C
        9'b0_0001_1011,	// s => 1B
        9'b0_0010_0011,	// d => 23
        9'b0_0010_1011,	// f => 2B
        9'b0_0011_0100,	// g => 34
        9'b0_0011_0011,	// h => 33
        9'b0_0011_1011	// j => 3B
    };

    debounce dbVup(.clk(clkDiv16), .pb(volUP), .pb_debounced(db_volUP));
    debounce dbVdown(.clk(clkDiv16), .pb(volDOWN), .pb_debounced(db_volDOWN));
    debounce dbOup(.clk(clkDiv16), .pb(octaveUP), .pb_debounced(db_octaveUP));
    debounce dbOdown(.clk(clkDiv16), .pb(octaveDOWN), .pb_debounced(db_octaveDOWN));
    one_pulse opVup(.clk(clk), .pb_in(db_volUP), .pb_out(op_volUP));
    one_pulse opVdown(.clk(clk), .pb_in(db_volDOWN), .pb_out(op_volDOWN));
    one_pulse opOup(.clk(clk), .pb_in(db_octaveUP), .pb_out(op_octaveUP));
    one_pulse opOdown(.clk(clk), .pb_in(db_octaveDOWN), .pb_out(op_octaveDOWN));

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), .rst(rst), .volume(volume),
        .note_div_left(freq_outL), .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

    SevenSegment seven_seg (
		.display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst), .clk(clk)
	);

	KeyboardDecoder key_de (
		.key_down(key_down), .last_change(last_change), .key_valid(key_valid),
		.PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK), .rst(rst), .clk(clk)
	);

    // check if available the push changed key
    ChangeKey ck(
		.clk(clk), .rst(rst), .key_down(key_down), .last_change(last_change), 
        .key_valid(key_valid), .available(available), .last_key(last_key)
	);

    // control the volume
    always @(posedge clk, posedge rst) begin
        if(rst) volume <= 3'd3;
        else begin
            if(op_volUP && !db_volDOWN) begin
                if(volume < 3'd5) volume <= volume + 1;
            end else if(op_volDOWN && !db_volUP) begin
                if(volume > 3'd1) volume <= volume - 1;
            end
        end
    end

    // handle volume LED
    always @(*) begin
        case(volume)
            3'd1: LED = 5'b00001;
            3'd2: LED = 5'b00011;
            3'd3: LED = 5'b00111;
            3'd4: LED = 5'b01111;
            3'd5: LED = 5'b11111;
            default: LED = 5'b00000;
        endcase
    end

    // control the octave
    always @(posedge clk, posedge rst) begin
        if(rst) octave <= 3'd4;
        else begin
            if(op_octaveUP && !db_octaveDOWN) begin
                if(octave < 3'd5) octave <= octave + 1;
            end else if(op_octaveDOWN && !db_octaveUP) begin
                if(octave > 3'd3) octave <= octave - 1;
            end
        end
    end

    // handle note number
    always @(posedge clk, posedge rst) begin
        if(rst) note_num <= 4'hC;
        else begin
            if(available) note_num <= key_num;
        end
    end

    // set frequency for notes
    always @(*) begin
        if(last_key != 9'b0) begin
            case(note_num)
                4'hC: mainfreq = `c4;
                4'hD: mainfreq = `d4;
                4'hE: mainfreq = `e4;
                4'hF: mainfreq = `f4;
                4'h9: mainfreq = `g4;
                4'hA: mainfreq = `a4;
                4'hB: mainfreq = `b4;
                default: mainfreq = `silence;
            endcase
        end else mainfreq = `silence;
    end

    assign freqL = mainfreq << (octave - 3);
    assign freqR = mainfreq << (octave - 3);

    // set sum for seven segment
    always @(posedge clk, posedge rst) begin
        if(rst) nums <= 16'd0;
        else begin
            if(last_key != 9'b0) nums <= {8'h00, note_num, 1'b0, octave};
            else nums <= 16'b0;
        end
    end

    // control note and key input
    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'hC; // c
			KEY_CODES[01] : key_num = 4'hD; // d
			KEY_CODES[02] : key_num = 4'hE; // e
			KEY_CODES[03] : key_num = 4'hF; // f
			KEY_CODES[04] : key_num = 4'h9; // g
			KEY_CODES[05] : key_num = 4'hA; // a
			KEY_CODES[06] : key_num = 4'hB; // b
			default		  : key_num = 4'h0; // default
		endcase
	end

endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
);
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
        end else begin
    		case (digit)
    			4'b1110 : begin
                    display_num <= nums[7:4];
                    digit <= 4'b1101;
                end
    			4'b1101 : begin
                    display_num <= nums[11:8];
                    digit <= 4'b1011;
                end
    			4'b1011 : begin
                    display_num <= nums[15:12];
                    digit <= 4'b0111;
                end
    			4'b0111 : begin
                    display_num <= nums[3:0];
                    digit <= 4'b1110;
                end
    			default : begin
                    display_num <= nums[3:0];
                    digit <= 4'b1110;
                end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b0111111;	//only dash                                              
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101
            9 : display = 7'b0010000;   // G                                              
			10 : display = 7'b0001000;  // A
            11 : display = 7'b0000011;  // B
            12 : display = 7'b1000110;  // C
            13 : display = 7'b0100001;  // D
            14 : display = 7'b0000110;  // E
            15 : display = 7'b0001110;  // F
            default : display = 7'b1111111; // nothing
    	endcase
    end
endmodule

module ChangeKey(
	input wire clk,
	input wire rst,
	input wire [511:0] key_down,
	input wire [8:0] last_change,
	input wire key_valid,
	output reg available,
    output reg [8:0] last_key
);
    reg pressed;
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			available <= 1'b0;
			pressed <= 0;
			last_key <= 9'b0;
		end else begin
			pressed <= pressed;
			available <= 0;
			last_key <= last_key;
			if (!pressed && key_valid && key_down[last_change]) begin
				pressed <= 1;
				available <= 1'b1;
				last_key <= last_change;
			end else if(pressed && key_valid && key_down[last_key] == 1'b0) begin
				pressed <= 0;
				last_key <= 9'b0;
			end
		end
	end
endmodule