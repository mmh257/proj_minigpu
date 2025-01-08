`include "../../src/decoder/decoder.v"
module wrapper_decoder #(
  parameter PC_ADDR_WIDTH = 8, 
            INST_MSG_WIDTH = 16
) (
  input clk,
  input reset,
  input [3:0] cu_state, 

  // Functional Inputs
  input [INST_MSG_WIDTH-1:0] instr, 

  // Decoded Outputs
  output [3:0] rd, 
  output [3:0] rs1, 
  output [3:0] rs2, 
  output [3:0] rimm, 
  output [7:0] imm, 
  output [3:0] alu_func,

  // Decoded Flags (Which instr to enable)
  output is_alu, // Includes both branches and alu ops
  output is_branch, // Separate branch flag here for the branching logic in PC
  output is_const, 
  output is_load, 
  output is_store,
  output is_nop,
  output is_jr // jump return flag to signal the end of an instruction. Process here

);

decoder #(8, 16) inst_decoder(
  .clk(clk),
  .reset(reset),
  .cu_state(cu_state),
  .instr(instr),
  .rd(rd),
  .rs1(rs1),
  .rs2(rs2),
  .rimm(rimm),
  .imm(imm),
  .alu_func(alu_func),
  .is_alu(is_alu),
  .is_branch(is_branch),
  .is_const(is_const),
  .is_load(is_load),
  .is_store(is_store),
  .is_nop(is_nop),
  .is_jr(is_jr)
);

// Dumping vcd
initial begin 
  $dumpfile("decoder_dump.vcd");
  $dumpvars(1, wrapper_decoder);
end

endmodule