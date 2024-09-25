`timescale 1ns/100ps
module practice_1 (
    input wire a,
    input wire b,
    input wire c,
    output wire out
);

    // Write your code here

    wire temp;
    xor_gate xor1(a, b, temp);
    xor_gate xor2(temp, c, out);

endmodule

module xor_gate (
    input wire a,
    input wire b,
    output wire y
);

    // Write your code here(i)

    wire na, nb, t1, t2;
    not(na, a);
    not(nb, b);
    and(t1, na, b);
    and(t2, a, nb);
    or(y, t1, t2);

endmodule