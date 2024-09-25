`timescale 1ns/100ps

module practice_2(
  input wire G,
  input wire D,
  output wire P,
  output wire Pn
);
  // Write your code here

  wire nD, t1, t2;
  not(nD, D);
  nand(t1, D, G);
  nand(t2, nD, G);
  nand(P, t1, Pn);
  nand(Pn, t2, P);
  
endmodule
