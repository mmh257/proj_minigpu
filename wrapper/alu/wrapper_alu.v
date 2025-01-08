// ===========================================
// Wrapper module for the ALU to enable waveforms
// ===========================================
// `timescale 1ns/1ps
`include "../../src/alu/alu.v"

module wrapper_alu (
  input clk, 
  input reset, 

  // Functionality inputs
  input alu_en, 
  input [3:0] alu_func, 
  input [15:0] a, 
  input [15:0] b, 

  // Functionality Outputs
  output [15:0] out, 

  // Comparison Flag Outputs
  output cmp_lt, 
  output cmp_eq
); 

alu inst_alu(
  .clk(clk),
  .reset(reset),
  .alu_en(alu_en),
  .alu_func(alu_func),
  .a(a),
  .b(b),
  .out(out),
  .cmp_lt(cmp_lt),
  .cmp_eq(cmp_eq)
);

// Dump waves
initial begin 
  $dumpfile("minigpu_alu.vcd");
  $dumpvars(1, wrapper_alu);
end

endmodule
