/* basic time unit/time precision */
`timescale 1ns/100ps

/* declaration of a Verilog module */
module practice_1_t;

/* input signal of the design should be declared as reg in the testbench */
reg w, x, a, b, c;

/* output signal of the design should be declared as wire in the testbench */
wire y, out;

/* "#" is used to specify a delay */
/* invert the clk signal every 5 unit of time */
// wire clk = 1'b0;
// always#5 clk = ~clk;

/* instatiate the module */
xor_gate x1(
    /* "." is used to associate the input and output ports 
       of the instantiated module with the corresponding signals */
    .a(w),
    .b(x),
    .y(y)
);

//====================================
// TODO
// Connect your practice_1 module here with "a", "b", "c", "out"
// Please connect it by port name but not order

practice_1 p1(
    .a(a),
    .b(b),
    .c(c),
    .out(out)
);

//====================================

integer i, answer;
/* initial blocks are not synthesizable and can only be used in test benches */
initial begin
    /* display a message */
    $display("===== Simulation ======");

    for (i = 0; i < 4; i = i + 1) begin
        /* assign a value to the input signal */
        {w, x} = i;
        answer = w ^ x;
        /* wait for 10 unit of time */
        #10;
        if (y !== answer) begin
            $display("Error: a = %b, b = %b, y = %b", w, x, y);
            $display("Correct answer should be %b", answer);
        end else begin
            $display("Correct: a = %b, b = %b, y = %b", w, x, y);
        end
    end
#10
    for (i = 0; i < 8; i = i + 1) begin
        {a, b, c} = i;
        answer = a ^ b ^ c;
        #10;
        if (out !== answer) begin
            $display("Error: a = %b, b = %b, c = %b, out = %b", a, b, c, out);
            $display("Correct answer should be %b", answer);
        end else begin
            $display("Correct: a = %b, b = %b, c = %b, out = %b", a, b, c, out);
        end
    end

    $display("===== Simulation finished ======");

    /* done simulating */
    $finish;
end

endmodule