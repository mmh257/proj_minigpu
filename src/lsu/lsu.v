// ===========================================
// LSU Module for the Compute Unit
// This module handles memory requests for loads and stores. 
// Will follow a rdy/val handshaking protocol to ensure proper data flow.
//
// Load Instruction:
// LW r1 r2 -> Loading the data from memory @ r2 onto r1
// r2 in this case is "rs1" since it is the first source register
// 
// Store Instruction:
// SW r1 r2 -> Store the data on register r1 at memory @ r2
// r1 is "rs2" because it contains our data, and r2 is "rs1" 
//
// Port Overview: 
// 1. mem_ren: read-enable signal, indicating we have a load 
// 2. mem_wen: write_enable signal, indicating we have a write
// 3. rs1: an input containing rs1 register data
// 4. rs2: an input containing rs2 register data
// 5. lsu_out: contains the data of the lsu - only has valid outputs on a load request
// 6. lsu_state: a flag to indicate whether the LSU is ready for more data or not
// ===========================================

module lsu #(
  parameter DATA_ADDR_WIDTH = 8,
            DATA_WIDTH = 16
) (
  input clk,
  input reset, 
  input [3:0] cu_state, 
  input lsu_en,

  // Functional Inputs
  input mem_ren, 
  input mem_wen, 
  input [15:0] rs1, 
  input [15:0] rs2,

  // Functional Outputs
  output [DATA_WIDTH-1:0] lsu_data_out,
  output [1:0] lsu_state, 
  
  // Read (Load) Request
  input read_req_rdy, 
  output [DATA_ADDR_WIDTH-1:0] read_req_addr,
  output read_req_addr_val,
  
  // Read (Load) Response
  output read_resp_rdy,
  input [DATA_WIDTH-1:0] read_resp_data,
  input read_resp_data_val,

  // Write (Store) Request
  input write_req_rdy,
  output [DATA_ADDR_WIDTH-1:0] write_req_addr, 
  output [DATA_WIDTH-1:0] write_req_data, 
  output write_req_val,

  // Write (Store) Response : Only one signal to indicate that we are done writing 
  input write_resp_val 

);

// scheduler localparams
localparam  IDLE = 4'd0, 
            FETCH = 4'd1, 
            DECODE = 4'd2,
            REQ = 4'd3, 
            WAIT = 4'd4,
            EXECUTE = 4'd5, 
            WRITEBACK = 4'd6,
            DONE = 4'd7;

// LSU FSM Parameters
localparam  LSU_IDLE = 2'd0, 
            LSU_REQ  = 2'd1, 
            LSU_WAIT = 2'd2, 
            LSU_DONE = 2'd3; 
   
// LSU FSM Progression:
// IDLE: "default" state, nothing going on and ready to accept a request, only able to move on if the cu state is in request mode
// REQ: Processing the initial request, determining if its load/store, which handshaking signal to activate
// WAIT: Waiting for the memory response after sending a request
// DONE: Finished request, we can progress back to IDLE if our core has completed its action, cu state is in writeback 
reg [1:0] lsu_state_reg; 
assign lsu_state = lsu_state_reg;

// Register-ing Ports to enable assignment on output
reg [DATA_WIDTH-1:0] lsu_data_out_reg;
assign lsu_data_out = lsu_data_out_reg;

reg read_req_addr_val_reg; 
assign read_req_addr_val = read_req_addr_val_reg; 

reg read_resp_rdy_reg; 
assign read_resp_rdy = read_resp_rdy_reg;

reg write_req_val_reg;
assign write_req_val = write_req_val_reg;

reg [DATA_ADDR_WIDTH-1:0] read_req_addr_reg; 
assign read_req_addr = read_req_addr_reg;

reg [DATA_ADDR_WIDTH-1:0] write_req_addr_reg; 
assign write_req_addr = write_req_addr_reg;

reg [DATA_WIDTH-1:0] write_req_data_reg;
assign write_req_data = write_req_data_reg;

// FSM Logic
always @(posedge clk) begin 
  if (reset) begin 
    lsu_data_out_reg <= 0;
    lsu_state_reg <= LSU_IDLE;
    read_req_addr_val_reg <= 0; 
    read_resp_rdy_reg <= 0; 
    write_req_val_reg <= 0;  
  end else begin 
    if (lsu_en) begin 
      if (mem_ren) begin 
        // Load Mode
        case (lsu_state_reg) 

          LSU_IDLE: begin 
            // If we are in data request stage in scheduler, proceed
            if (cu_state == REQ) begin 
              lsu_state_reg <= LSU_REQ; 
            end
          end
          LSU_REQ: begin 
            // Setting read request, if memory is not ready, continue to wait
            if (read_req_rdy) begin 
              read_req_addr_reg <= rs2;
              read_req_addr_val_reg <= 1;
              read_resp_rdy_reg <= 1; // now we are sending out a request, we will be ready to handle response
              lsu_state_reg <= LSU_WAIT;
            end
          end
          LSU_WAIT: begin 
            // Waiting for the read response
            if (read_resp_data_val) begin 
              read_req_addr_val_reg <= 0; // Reset back to 0
              lsu_data_out_reg <= read_resp_data;
              lsu_state_reg <= LSU_DONE; 
              read_resp_rdy_reg <= 0;
            end
          end
          LSU_DONE: begin 
            // Wait for us to go into register writeback
            if (cu_state == WRITEBACK) begin 
              lsu_state_reg <= LSU_IDLE;
            end
          end
          default: lsu_state_reg <= LSU_IDLE;
        endcase
      end
      else if (mem_wen) begin 
        // Store Mode
        case (lsu_state_reg) 
          LSU_IDLE: begin 
            // Waiting for core to go into request mode again 
            if (cu_state == REQ) begin 
              lsu_state_reg <= LSU_REQ;
            end
          end
          LSU_REQ: begin 
            // Need to check if memory is ready to send a memory write request
            if (write_req_rdy) begin 
              write_req_addr_reg <= rs2; 
              write_req_data_reg <= rs1; 
              write_req_val_reg <= 1;
              lsu_state_reg <= LSU_WAIT;
            end
          end
          LSU_WAIT: begin 
            // Waiting for the memory to finish writing 
            if (write_resp_val) begin 
              write_req_val_reg <= 0; 
              lsu_state_reg <= LSU_DONE;
            end
          end
          LSU_DONE: begin 
            if (cu_state == WRITEBACK) begin 
              lsu_state_reg <= LSU_IDLE;
            end
          end
          default: lsu_state_reg <= LSU_IDLE;
        endcase
      end
    end
  end
end


endmodule