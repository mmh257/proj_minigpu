// ===========================================
// Fetcher Block for the Compute Unit
// 
// Fetches the instruction to decode and operate
// on the selected number of execute units. 
//
// Uses the current pc value to fetch the memory at 
// that instruction location, and it interfaces with 
// our global memory. 
// ===========================================

module fetcher #(
  parameter PC_ADDR_WIDTH = 8, 
            INST_MSG_WIDTH = 16
) (
  input clk,
  input reset,
  input [3:0] cu_state, 

  // Functional Block Inputs
  input [PC_ADDR_WIDTH-1:0] curr_pc, 

  // Functional Block Outputs
  output [1:0] fetch_state,
  output [INST_MSG_WIDTH-1:0] fetch_instr, 

  // Memory Fetch Request
  input fetch_req_rdy,
  output fetch_req_val,
  output [PC_ADDR_WIDTH-1:0] fetch_req_addr, // Uses current pc

  // Memory Fetch Response
  output fetch_resp_rdy, 
  input fetch_resp_val,
  input [INST_MSG_WIDTH-1:0] fetch_resp_inst
); 

// localparams for the scheduler states
localparam  IDLE = 4'd0, 
            FETCH = 4'd1, 
            DECODE = 4'd2,
            REQ = 4'd3, 
            WAIT = 4'd4,
            EXECUTE = 4'd5, 
            WRITEBACK = 4'd6,
            DONE = 4'd7;

// Localparams for the fetch state
localparam  FT_IDLE = 2'b00,
            FT_REQ  = 2'b01,
            FT_WAIT = 2'b10,
            FT_DONE = 2'b11;

// Assigning Registers to the different outputs
reg fetch_req_val_reg;
reg [PC_ADDR_WIDTH-1:0] fetch_req_addr_reg; 
reg fetch_resp_rdy_reg;
reg [INST_MSG_WIDTH-1:0] fetch_instr_reg; 
assign fetch_req_val = fetch_req_val_reg; 
assign fetch_req_addr = fetch_req_addr_reg; 
assign fetch_resp_rdy = fetch_resp_rdy_reg; 
assign fetch_instr = fetch_instr_reg;

// State Transitioning logic 
reg [1:0] fetch_state_reg; 
assign fetch_state = fetch_state_reg;

always @(posedge clk) begin 
  if (reset) begin 
    // Set all outputs to default value 0 
    fetch_req_val_reg <= 0; 
    fetch_req_addr_reg <= 0; 
    fetch_resp_rdy_reg <= 0;
    fetch_state_reg <= FT_IDLE;
  end else begin 
    case (fetch_state_reg)
      FT_IDLE: begin 
        if (cu_state == FETCH) begin 
          fetch_state_reg <= FT_REQ;
        end
      end
      FT_REQ: begin 
        if (fetch_req_rdy) begin 
          fetch_req_val_reg <= 1;
          fetch_req_addr_reg <= curr_pc;
          fetch_resp_rdy_reg <= 1;
          fetch_state_reg <= FT_WAIT;
        end
      end
      FT_WAIT: begin 
        if (fetch_resp_val) begin 
          fetch_req_val_reg <= 0;
          fetch_resp_rdy_reg <= 0;
          fetch_instr_reg <= fetch_resp_inst;
          fetch_state_reg <= FT_DONE;
        end
      end
      FT_DONE: begin 
        if (cu_state == DECODE) begin 
          fetch_state_reg <= FT_IDLE;
        end
      end

      // Leave out default case for now
      default: fetch_state_reg <= FT_IDLE;  
    endcase
  end
end


endmodule