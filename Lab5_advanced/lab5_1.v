module lab5_1 (
    input wire clk,
    input wire rst,
    input wire en,
    input wire dir,
    input wire vmir,
    input wire hmir,
    input wire enlarge,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire hsync,
    output wire vsync
);
    // add your design here
    wire [11:0] data;
    wire clk_25MHz;
    wire clk22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;

    clock_divider #(.n(22)) n22 (
        .clk(clk), .clk_div(clk22)
    );
    clock_divider #(.n(2)) n2 (
        .clk(clk), .clk_div(clk_25MHz)
    );

    mem_addr_gen mem_addr_gen_inst(
        .clk(clk22), .rst(rst), .en(en), .dir(dir),
        .vmir(vmir), .hmir(hmir), .enlarge(enlarge),
        .h_cnt(h_cnt), .v_cnt(v_cnt), .pixel_addr(pixel_addr)
    );

    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_25MHz), .wea(0), .addra(pixel_addr),
        .dina(data[11:0]), .douta(pixel)
    );

    vga_controller   vga_inst(
        .pclk(clk_25MHz), .reset(rst), .hsync(hsync),
        .vsync(vsync), .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt)
    );

endmodule

module mem_addr_gen(
    input wire clk,
    input wire rst,
    input wire en,
    input wire dir,
    input wire vmir,
    input wire hmir,
    input wire enlarge,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [16:0] pixel_addr
);
    
    reg [7:0] position_x, position_y; // handle picture movement
    reg [7:0] next_x, next_y, out_x, out_y;

    assign pixel_addr = ((h_cnt >> 1) + 320 * (v_cnt >> 1) + 
                            position_y * 320 + (position_x  - ((h_cnt >> 1) % 320) * hmir)) % 76800;  //640*480 --> 320*240 

    always @ (posedge clk or posedge rst) begin
        if(rst) position_y <= 0;
        else position_y <= next_y;
    end

    always @(posedge clk, posedge rst) begin
        if(rst) position_x <= 0;
        else position_x <= next_x;
    end

    // handle next x
    // always @(*) begin
    //     if(!en) next_x = position_x;
    //     else begin
    //         if(!hmir) begin
    //             if(position_x < 319 && dir)
    //                 next_x = position_x + 1;
    //             else if(position_x == 320 && dir)
    //                 next_x = 0;
    //             else if(position_x > 0 && !dir)
    //                 next_x = position_x - 1;
    //             else
    //                 next_x = 320;
    //         end else begin
    //             if(position_x < 319 && !dir)
    //                 next_x = position_x + 1;
    //             else if(position_x == 320 && !dir)
    //                 next_x = 0;
    //             else if(position_x > 0 && dir)
    //                 next_x = position_x - 1;
    //             else
    //                 next_x = 320;
    //         end
    //     end
    // end

    always @(*) begin
        if(!hmir) next_x = 0;
        else next_x = 319;
    end

    // handle next y
    always @(*) begin
        if(!en) next_y = position_y;
        else begin
            if(position_y < 239 && !dir)
                next_y = position_y + 1;
            else if(position_y == 239 && !dir)
                next_y = 0;
            else if(position_y > 0 && dir)
                next_y = position_y - 1;
            else
                next_y = 239;
        end
    end
    
endmodule
