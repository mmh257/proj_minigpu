// ===========================================
// Scalar ALU Design for a Compute Unit
// - Support 8 bit arithmetic & logical ops
// - Will also contain comparison flags
// - Supports the following instructions: 
//   Arith: ADD, SUB, MUL, DIV 
//   Logic: AND, OR, XOR
//   Shift: SRL, SLL, SRA
//   Comp : CMP 
// - WILL NOT SUPPORT CARRY 
// ===========================================

module alu (
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

// Establishing localparams for alu functions
localparam  alu_add  = 4'd0, 
            alu_sub  = 4'd1, 
            alu_mul  = 4'd2, 
            alu_div  = 4'd3,
            alu_and  = 4'd4, 
            alu_or   = 4'd5, 
            alu_srl  = 4'd6, 
            alu_sll  = 4'd15,
            alu_cmp  = 4'd8;

// Internal Register to work with all of our functionality
reg [15:0] alu_reg_out;
reg cmp_reg_eq;
reg cmp_reg_lt; 
reg cmp_reg_lte;
assign out = alu_reg_out; 
assign cmp_eq = cmp_reg_eq; 
assign cmp_lt = cmp_reg_lt; 
assign cmp_lte = cmp_reg_lte; 

// Case statements to process the different scenarios
always @(posedge clk) begin 
  // First check if we reset
  if (reset) begin 
    alu_reg_out <= 0; 
    cmp_reg_lt <= 0; 
    cmp_reg_lte <= 0; 
    cmp_reg_eq <= 0; 
  end
  else if (alu_en) begin 
    // Case statement here to perform the correct alu operation on our output
    // Data on inputs a and b are assumed to be signed inputs
    case (alu_func) 

      alu_add : alu_reg_out <= a + b; 
      alu_sub : alu_reg_out <= a - b; 
      alu_mul : alu_reg_out <= a * b; 
      alu_div : alu_reg_out <= a / b;
      alu_and : alu_reg_out <= a & b;
      alu_or  : alu_reg_out <= a | b;
      alu_srl : alu_reg_out <= a & b;
      alu_sll : alu_reg_out <= $signed(a) << $unsigned(b[3:0]);
      alu_srl : alu_reg_out <= $signed(a) >> $unsigned(b[3:0]);
      alu_cmp : begin 
        alu_reg_out <= 0;
        cmp_reg_lt <= $signed(a) < $signed(b);
        cmp_reg_eq <= $signed(a) == $signed(b);
      end

      default : alu_reg_out <= 0; 
    endcase
  end

end



endmodule