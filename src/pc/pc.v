// ===========================================
// PC Counter Module
// Will perform PC + 2 since each instruction 
// is 2 bytes wide. (16 bits)
// Input Overview:
// 1. curr_pc: the current pc we are at
// 2. alu_out: output from the alu (if we need to do some complex op)
// 3. br_imm: The address destination of where we are branching to
// 4. br_type: the type of branch condition we are checking: NE, EQ, GT, LT
// 5. br_valid: A valid signal for us to make sure that we are actually branching
// 6. cmp_vals: These are the comparison values from the ALU !!! May need to add an ALU valid output flag
// 7. alu_func: This flag is to help us check if we are actually branching
// ===========================================

module pc #(
  parameter PC_ADDR_WIDTH = 8,
            DATA_WIDTH=16
) (
  input clk,
  input reset, 
  input pc_en, 
  input [3:0] cu_state, 

  // Functional Inputs
  input [PC_ADDR_WIDTH-1:0] curr_pc,
  input [15:0] alu_out, 
  input [DATA_WIDTH-1:0] br_imm, 
  input [3:0] opcode, 
  input cmp_lt,
  input cmp_eq,
  input [3:0] alu_func,

  // Functional Outputs
  output [PC_ADDR_WIDTH-1:0] next_pc
);

// // Defining localparam for branch types
// localparam  br_eq  = 4'd0, 
//             br_neq = 4'd1, 
//             br_lt  = 4'd2, 
//             br_gt  = 4'd3;

localparam  BNE = 4'd4, 
            BEQ = 4'd5,
            BLT = 4'd6, 
            BGT = 4'd7;
// Local params for states to check 
localparam EXECUTE = 4'd5;
localparam CMP = 4'd8;

// Defining internal module registers
reg [PC_ADDR_WIDTH-1:0] next_pc_reg;
assign next_pc = next_pc_reg;

always @(posedge clk) begin 
  if (reset) begin 
    next_pc_reg <= 0; 
  end else begin 
    if (pc_en) begin 
      // First check that we are in the execute state
      // Then check to see if we are branching, set to the branch immediate
      // If no branch or if the branch condition is not satisfied, we simply increment by 2
      if (cu_state == EXECUTE) begin 
        if (alu_func == CMP) begin 
          case (opcode)

            BEQ : next_pc_reg <= (cmp_eq) ? br_imm : curr_pc + 2; 
            BNE : next_pc_reg <= (~cmp_eq) ? br_imm : curr_pc + 2; 
            BLT : next_pc_reg <= (cmp_lt && ~cmp_eq) ? br_imm : curr_pc + 2; 
            BGT : next_pc_reg <= (~cmp_lt && ~cmp_eq) ? br_imm : curr_pc + 2;

            default: next_pc_reg <= curr_pc + 2;
          endcase
        end else begin 
          // Case for we're executing and not branching
          next_pc_reg <= curr_pc + 2; 
        end
      end
      
    end else begin 
      next_pc_reg <= 0; // To make sure we have no open ends, no "X"
    end
  end
end

endmodule