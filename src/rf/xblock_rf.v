// ===========================================
// Register file for each individual X-Unit
// - Interfaces with the PC and LSU
// 
// 16 vector wide register file, 13 free registers
// and 3 read only registers (modified when initially scheduling 
// and operation for the compute unit
// 
// Breakdown of the register contents:
// x0 to x12: Free Registers 
// x13: CUIdx - The corresponding "compute unit" the thread belongs to 
// x14: CUWidth - How wide the compute unit will be. (Number of X-blocks active in a given CU)
// x15: ThreadIdx - The ID of the thread that this set of registers will be associated with 
// 
// Breakdown of inputs:
// 
// ===========================================
module xblock_rf #(
  parameter CU_IDX = 0,
            CU_WIDTH = 4, 
            THREAD_ID = 0,
            DATA_WIDTH = 16
) (
  input clk,
  input reset,
  input [3:0] cu_state, 
  input rf_enable,

  // Inputs From Scheduler
  input [DATA_WIDTH-1:0] cu_id, // For if we need to change the associated thread of a block

  // Inputs From the Decoder
  input [3:0] decoded_rd,
  input [3:0] decoded_rs1,
  input [3:0] decoded_rs2,
  input [3:0] decoded_rimm,
  input [7:0] decoded_imm, // !!! Need to sign extend this
  input is_alu, 
  input is_const,
  input is_read,

  // Inputs From the LSU
  input [DATA_WIDTH-1:0] lsu_load_data,

  // Inputs From the ALU
  input [DATA_WIDTH-1:0] alu_out_data,

  // Functional Inputs
  input rf_wen, // Writing RF during Writeback
  input rf_ren, // Reading RF during decode
  input [3:0] rf_addr,
  input [DATA_WIDTH-1:0] rf_data,

  // Functional Outputs
  output [DATA_WIDTH-1:0] rs1_data, // RS1 data after an RF Read
  output [DATA_WIDTH-1:0] rs2_data, // RS1 data after an RF Read
  output [DATA_WIDTH-1:0] rimm_data // RS1 data after an RF Read
);

// Declaring our internal register file 16 x 16bit register file 
reg [DATA_WIDTH-1:0] registers [15:0]; 

// Registering outputs
reg [DATA_WIDTH-1:0] rs1_data_reg;
reg [DATA_WIDTH-1:0] rs2_data_reg;
reg [DATA_WIDTH-1:0] rimm_data_reg;
assign rs1_data = rs1_data_reg;
assign rs2_data = rs2_data_reg;
assign rimm_data = rimm_data_reg;

// localparam for the compute unit state
localparam  IDLE = 4'd0, 
            FETCH = 4'd1, 
            DECODE = 4'd2,
            REQ = 4'd3, 
            WAIT = 4'd4,
            EXECUTE = 4'd5, 
            WRITEBACK = 4'd6,
            DONE = 4'd7;

integer i;
always @(posedge clk) begin 
  if (reset) begin 
    // Initialize Everything to 0
    // initial begin 
      // for (i=0; i<13; i=i+1) begin 
      //   registers[i] <= 16'b0;
      // end
    // end
    registers[0] <= 0;
    registers[1] <= 0;
    registers[2] <= 0;
    registers[3] <= 0;
    registers[4] <= 0;
    registers[5] <= 0;
    registers[6] <= 0;
    registers[7] <= 0;
    registers[8] <= 0;
    registers[9] <= 0;
    registers[10] <= 0;
    registers[11] <= 0;
    registers[12] <= 0;
    
    registers[13] <= CU_IDX;
    registers[14] <= CU_WIDTH;
    registers[15] <= THREAD_ID;
    rs1_data_reg <= 16'b0;
    rs2_data_reg <= 16'b0;
    rimm_data_reg <= 16'b0;
  end
  else begin 
    if (rf_enable) begin 
      // Temporary inclusion
      registers[13] <= cu_id;

      case (cu_state)
        REQ: begin 
          // During a request, process the outputs from the decode
          if (rf_ren) begin 
            rs1_data_reg <= registers[decoded_rs1];
            rs2_data_reg <= registers[decoded_rs2];
            rimm_data_reg <= registers[decoded_rimm];
          end
        end
        WRITEBACK: begin 
          if (rf_wen) begin 
            if (is_read) begin 
              // If we are loading a value, need to update corresponding register
              registers[decoded_rs1] <= lsu_load_data;
            end
            if (is_const) begin 
              registers[decoded_rd] <= decoded_imm; // !!! Figure if we need to sext this
            end
            if (is_alu) begin 
              registers[decoded_rd] <= alu_out_data;
            end
          end
        end

      endcase
    end
  end
end


wire [15:0] reg0;
wire [15:0] reg1;
wire [15:0] reg2;
wire [15:0] reg3;
wire [15:0] reg4;
wire [15:0] reg5;
wire [15:0] reg6;
wire [15:0] reg7;
wire [15:0] reg8;
wire [15:0] reg9;
wire [15:0] reg10;
wire [15:0] reg11;
wire [15:0] reg12;
wire [15:0] reg13;
wire [15:0] reg14;
wire [15:0] reg15;
assign reg0 = registers[0];
assign reg1 = registers[1];
assign reg2 = registers[2];
assign reg3 = registers[3];
assign reg4 = registers[4];
assign reg5 = registers[5];
assign reg6 = registers[6];
assign reg7 = registers[7];
assign reg8 = registers[8];
assign reg9 = registers[9];
assign reg10 = registers[10];
assign reg11 = registers[11];
assign reg12 = registers[12];
assign reg13 = registers[13];
assign reg14 = registers[14];
assign reg15 = registers[15];

// generate
//   genvar idx;
//   for(idx = 0; idx < 16; idx = idx+1) begin
//     wire [15:0] tmp;
//     assign tmp = registers[idx];
//   end
// endgenerate

endmodule