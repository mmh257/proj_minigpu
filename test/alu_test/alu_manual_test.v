`timescale 1ns/1ps
`include "../../wrapper/alu/wrapper_alu.v"
module alu_manual_test;

// Internal Signals used for the wrapper_alu
reg clk = 0;
reg reset = 0; 
reg alu_en = 0;
reg [3:0] alu_func = 0; 
reg [15:0] a = 0; 
reg [15:0] b = 0; 
wire [15:0] out;

// Setting up clock
always #1 clk = !clk;

initial begin 
  // Setting up reset
  #2 reset <= 1; 
  #2 reset <= 0;

  // Now enabling the inputs
  #10
  alu_en <= 1;
  alu_func <= 0; 
  a <= 8'd10;
  b <= 8'd5;
  # 10
  
  // Finish
  #50 $finish;
end

// Hooking up module 
wrapper_alu inst_alu(
  .clk(clk),
  .reset(reset),
  .alu_en(alu_en),
  .alu_func(alu_func),
  .a(a),
  .b(b),
  .out(out)
);

// initial begin 
//   $dumpfile("minigpu_alu.vcd");
//   $dumpvars(1, inst_alu);
// end

endmodule