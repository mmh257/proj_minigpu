`include "../../src/fetcher/fetcher.v"
module wrapper_fetcher #(
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

fetcher #(
  .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
  .INST_MSG_WIDTH(INST_MSG_WIDTH)
) inst_fetcher(
  .clk(clk),
  .reset(reset),
  .cu_state(cu_state),
  .curr_pc(curr_pc),
  .fetch_state(fetch_state),
  .fetch_instr(fetch_instr),
  .fetch_req_rdy(fetch_req_rdy),
  .fetch_req_val(fetch_req_val),
  .fetch_req_addr(fetch_req_addr),
  .fetch_resp_rdy(fetch_resp_rdy),
  .fetch_resp_val(fetch_resp_val),
  .fetch_resp_inst(fetch_resp_inst)
);

initial begin 
  $dumpfile("fetcher_dump.vcd");
  $dumpvars(1, inst_fetcher);
end

endmodule