// ===========================================
// Decoder module for the Compute Unit
// 
// Conceptually, this module is essentially a "demuxer", breaking
// up an input signal into something "recognizable". This decoder
// will take in a 16 bit custom instruction part of our ISA and 
// will output the proper 
// ===========================================
module decoder #(
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
  output [3:0] opcode,

  // Decoded Flags (Which instr to enable)
  output is_alu, // Includes both branches and alu ops
  output is_branch, // Separate branch flag here for the branching logic in PC
  output is_const, 
  output is_load, 
  output is_store,
  output is_nop,
  output is_jr // jump return flag to signal the end of an instruction. Process here

);

// Localparam encoding for our ISA
localparam  ADD = 4'd0, 
            SUB = 4'd1, 
            MUL = 4'd2, 
            DIV = 4'd3, 
            BNE = 4'd4, 
            BEQ = 4'd5,
            BLT = 4'd6, 
            BGT = 4'd7, 
            CONST = 4'd8,
            LW = 4'd9,
            SW = 4'd10,
            NOP = 4'd11,
            JR = 4'd12;

// ALU Local params
localparam  alu_add  = 4'd0, 
            alu_sub  = 4'd1, 
            alu_mul  = 4'd2, 
            alu_div  = 4'd3,
            alu_and  = 4'd4, 
            alu_or   = 4'd5, 
            alu_srl  = 4'd6, 
            alu_sll  = 4'd15,
            alu_cmp  = 4'd8;

localparam DECODE = 4'd2;

// Registering outputs
reg [3:0] rd_reg; 
reg [3:0] rs1_reg; 
reg [3:0] rs2_reg; 
reg [3:0] rimm_reg; 
reg [7:0] imm_reg; 
reg [3:0] alu_func_reg; 
reg is_alu_reg; 
reg is_branch_reg;
reg is_const_reg; 
reg is_load_reg; 
reg is_store_reg; 
reg is_nop_reg;
reg is_jr_reg; 
assign rd = rd_reg;
assign rs1 = rs1_reg;
assign rs2 = rs2_reg; 
assign rimm = rimm_reg; 
assign imm = imm_reg; 
assign alu_func = alu_func_reg; 
assign is_alu = is_alu_reg;
assign is_branch = is_branch_reg;
assign is_const = is_const_reg; 
assign is_load = is_load_reg;
assign is_store = is_store_reg; 
assign is_nop = is_nop_reg;
assign is_jr = is_jr_reg; 

// Internal registers
// wire [3:0] opcode; 
assign opcode = instr[15:12];

// Case Statement Logic
always @(posedge clk) begin 
  if (reset) begin 
    // Set all output signals to 0 
    rd_reg <= 0; 
    rs1_reg <= 0; 
    rs2_reg <= 0; 
    rimm_reg <= 0; 
    imm_reg <= 0; 
    alu_func_reg <= 0; 
    is_alu_reg <= 0; 
    is_branch_reg <= 0;
    is_const_reg <= 0; 
    is_load_reg <= 0; 
    is_store_reg <= 0; 
    is_jr_reg <= 0; 
  end else begin 
    if (cu_state == DECODE) begin 
      // Assigning initial values 
      rd_reg <= instr[11:8];
      rs1_reg <= instr[7:4]; 
      rs2_reg <= instr[3:0];
      rimm_reg <= instr[11:8];
      imm_reg <= instr[7:0];
      // Resetting Flags
      alu_func_reg <= 0; 
      is_alu_reg <= 0; 
      is_branch_reg <= 0;
      is_const_reg <= 0; 
      is_load_reg <= 0; 
      is_store_reg <= 0; 
      is_jr_reg <= 0; 
      case (opcode)
        ADD: begin 
          alu_func_reg <= alu_add; 
          is_alu_reg <= 1; 
        end
        SUB: begin 
          alu_func_reg <= alu_sub;
          is_alu_reg <= 1; 
        end
        MUL: begin 
          alu_func_reg <= alu_mul;
          is_alu_reg <= 1; 
        end
        DIV: begin 
          alu_func_reg <= alu_div;
          is_alu_reg <= 1; 
        end
        BNE: begin 
          alu_func_reg <= alu_cmp;
          is_alu_reg <= 1; 
          is_branch_reg <= 1;
        end
        BEQ: begin 
          alu_func_reg <= alu_cmp;
          is_alu_reg <= 1; 
          is_branch_reg <= 1;
        end
        BLT: begin 
          alu_func_reg <= alu_cmp;
          is_alu_reg <= 1; 
          is_branch_reg <= 1;
        end
        BGT: begin 
          alu_func_reg <= alu_cmp;
          is_alu_reg <= 1; 
          is_branch_reg <= 1;
        end
        CONST: begin 
          is_const_reg <= 1;
        end
        LW: begin 
          is_load_reg <= 1;
        end
        SW: begin 
          is_store_reg <= 1;
        end
        NOP: begin 
          is_nop_reg <= 1;
        end
        JR: begin 
          is_jr_reg <= 1;
        end
      endcase
    end
  end
end

endmodule