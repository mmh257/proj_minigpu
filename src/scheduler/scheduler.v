// ===========================================
// Scheduler Design for the CU
// -  The scheduler will assign a thread to 
//    one of our available "X-Units" to perform 
//    a scalar operation
// -  It will also be the "brain" of our compute unit,
//    moving it through different stages of our compute
//    unit, similar to how a simple CPU can be a 5-stage
//    pipelined processor
// Stages of our Scheduler:
// 0. Idle
// 1. Fetch (Fetch block)
// 2. Decode (Decoder)
// 3. Data Load/Request (LSU, Read Register set)
// 4. Data Wait (LSU)
// 5. Execute (X-Unit)
// 6. Writeback (LSU/Register set Update)
// 7. Done
// 
// I/O Ports
// 1. Decoder outputs
// ===========================================
module scheduler #(
  parameter PC_ADDR_WIDTH = 8,
            CU_WIDTH = 4
) (
  input clk,
  input reset,
  input cu_enable,

  // Decoder Outputs
  input [3:0] rd, 
  input [3:0] rs1, 
  input [3:0] rs2, 
  input [3:0] rimm, 
  input [7:0] imm, 
  input [3:0] alu_func,
  input is_alu, 
  input is_branch, 
  input is_const, 
  input is_load, 
  input is_store,
  input is_nop,
  input is_jr, 

  // Fetcher Control
  input [1:0] fetch_state,

  // LSU Control - Need to vectorize it to account for the total number of LSUs enabled
  input [1:0] lsu_state [CU_WIDTH-1:0],

  // PC logic
  input [PC_ADDR_WIDTH-1:0] next_pc, 
  output [PC_ADDR_WIDTH-1:0] curr_pc,

  // Functional Outputs
  output rf_wen,
  output rf_ren,
  output mem_ren,
  output mem_wen,
  output [3:0] cu_state,
  output cu_complete
);

// Scheduler / Compute Unit States
localparam  IDLE = 4'd0, 
            FETCH = 4'd1, 
            DECODE = 4'd2,
            REQ = 4'd3, 
            WAIT = 4'd4,
            EXECUTE = 4'd5, 
            WRITEBACK = 4'd6,
            DONE = 4'd7;

// Fetcher States
localparam  FT_IDLE = 2'd0,
            FT_REQ  = 2'd1,
            FT_WAIT = 2'd2,
            FT_DONE = 2'd3;

// LSU States
localparam  LSU_IDLE = 2'd0, 
            LSU_REQ  = 2'd1, 
            LSU_WAIT = 2'd2, 
            LSU_DONE = 2'd3; 

// Registering outputs
// reg [PC_ADDR_WIDTH-1:0] curr_pc_reg [CU_WIDTH-1:0];
reg [PC_ADDR_WIDTH-1:0] curr_pc_reg;
reg [3:0] cu_state_reg;
reg cu_complete_reg;
reg rf_wen_reg;
reg rf_ren_reg;
reg mem_wen_reg;
reg mem_ren_reg;
assign curr_pc = curr_pc_reg;
assign cu_state = cu_state_reg;
assign cu_complete = cu_complete_reg;
assign rf_wen = rf_wen_reg;
assign rf_ren = rf_ren_reg;
assign mem_wen = mem_wen_reg;
assign mem_ren = mem_ren_reg;

// generate
// genvar i; 
// for (i=0;i<CU_WIDTH;i=i+1)begin 
//   assign curr_pc[i] = curr_pc_reg[i];
// end
// endgenerate

// Internal wire?/reg? to determine what request mode we are in 
integer ii;
reg wait_check;

always @(posedge clk) begin 
  if (reset) begin 
    curr_pc_reg <= 0; 
    // for (ii=0;ii<CU_WIDTH;ii=ii+1) begin 
    //   curr_pc_reg[ii] <= 0;
    // end

    cu_state_reg <= IDLE;
    cu_complete_reg <= 0;
    rf_ren_reg <= 0; 
    rf_wen_reg <= 0; 
    mem_ren_reg <= 0; 
    mem_wen_reg <= 0; 
    wait_check <= 0;
  end else begin 
      case (cu_state_reg) 
        IDLE: begin 
          // If we are in the idle phase, we simply wait until we recieve a start signal 
          if (cu_enable) begin 
            cu_state_reg <= FETCH; 
            curr_pc_reg <= 0; 

            // for (ii=0;ii<CU_WIDTH;ii=ii+1) begin 
            //   curr_pc_reg[ii] <= 0;
            // end

            cu_complete_reg <= 0;
            rf_ren_reg <= 0; 
            rf_wen_reg <= 0; 
            mem_ren_reg <= 0; 
            mem_wen_reg <= 0; 
            wait_check <= 0;
          end
        end
        FETCH: begin 
          // Need to wait until the fetch is completed before moving on 
          if (fetch_state == FT_DONE) begin 
            // Decode the instruction
            cu_state_reg <= DECODE;
          end
        end
        DECODE: begin 
          // In theory this state only takes one cycle, so can immediately move on
          cu_state_reg <= REQ;
          // Assign the rf write and read enable signals here
          rf_ren_reg <= is_load | is_store | is_alu | is_branch;
          rf_wen_reg <= is_load | is_alu | is_const;
          // mem enable signals
          mem_ren_reg <= is_load;
          mem_wen_reg <= is_store;
        end
        REQ: begin 
          // In this stage, the LSU/RF will perform the correct action, so we proceed to wait 
          cu_state_reg <= WAIT;
        end
        WAIT: begin 
          // RF has a latency of 1 cycle, so this cycle only waits until all LSU's are ready 
          wait_check = 1'b0;
          for (ii=0; ii<CU_WIDTH; ii=ii+1) begin 
            if (lsu_state[ii] == LSU_REQ || lsu_state[ii] == LSU_WAIT ) begin 
              wait_check = 1'b1;
            end
          end

          // If all LSU's are done, proceed
          if (~wait_check) begin 
            cu_state_reg <= EXECUTE; 
          end
        end
        EXECUTE: begin 
          // Assume that ALU and PC updates in 1 cycle
          cu_state_reg <= WRITEBACK; 
        end
        WRITEBACK: begin 
          // need to update our rf with the proper if we are here
          // Also check to see if we have a jr operation here
          if (is_jr) begin 
            cu_complete_reg <= 1;
            cu_state_reg <= DONE;
          end else begin 
            // need to update the "next" PC, re-enter fetch
            // NOTE: ASSUME NO BRANCH DIVERGENCE
            curr_pc_reg <= next_pc;

            // for (ii=0;ii<CU_WIDTH;ii=ii+1) begin 
            //   curr_pc_reg[ii] <= next_pc;
            // end

            cu_state_reg <= FETCH;
          end
        end
      endcase
    end

end

endmodule