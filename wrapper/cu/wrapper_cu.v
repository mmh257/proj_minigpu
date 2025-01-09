`include "../../src/cu/cu.v"
module wrapper_cu #(
  parameter NUM_THREADS = 4, 
            DATA_WIDTH = 16,
            DATA_ADDR_WIDTH = 8,
            PC_ADDR_WIDTH = 8,
            INST_MSG_WIDTH=16,
            CU_IDX=0
) (
  input clk,
  input reset,

  // Compute Unit Functional Inputs
  input cu_enable,
  output cu_complete,
  input [1:0] active_threads,

  // Compute Unit Functional Outputs
  output [3:0] compute_state,

  // Memory Access Signals - Fetcher
  input fetch_req_rdy,
  output fetch_req_val,
  output [PC_ADDR_WIDTH-1:0] fetch_req_addr, // Uses current pc

  output fetch_resp_rdy, 
  input fetch_resp_val,
  input [INST_MSG_WIDTH-1:0] fetch_resp_inst,

  // Memory Access Signals - LSU
  input read_req_rdy [NUM_THREADS-1:0], 
  output [DATA_ADDR_WIDTH-1:0] read_req_addr [NUM_THREADS-1:0],
  output read_req_addr_val [NUM_THREADS-1:0],
  
  // Read (Load) Response
  output read_resp_rdy [NUM_THREADS-1:0],
  input [DATA_WIDTH-1:0] read_resp_data [NUM_THREADS-1:0],
  input read_resp_data_val [NUM_THREADS-1:0],

  // Write (Store) Request
  input write_req_rdy [NUM_THREADS-1:0],
  output [DATA_ADDR_WIDTH-1:0] write_req_addr [NUM_THREADS-1:0], 
  output [DATA_WIDTH-1:0] write_req_data [NUM_THREADS-1:0], 
  output write_req_val [NUM_THREADS-1:0],

  // Write Response
  input write_resp_val [NUM_THREADS-1:0]

);

cu #(
  .NUM_THREADS(NUM_THREADS),
  .DATA_WIDTH(DATA_WIDTH),
  .DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
  .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
  .INST_MSG_WIDTH(INST_MSG_WIDTH),
  .CU_IDX(CU_IDX)
) inst_cu (
  .clk(clk),
  .reset(reset),
  .cu_enable(cu_enable),
  .cu_complete(cu_complete),
  .active_threads(active_threads),
  .compute_state(compute_state),
  .fetch_req_rdy(fetch_req_rdy),
  .fetch_req_val(fetch_req_val),
  .fetch_req_addr(fetch_req_addr),
  .fetch_resp_rdy(fetch_resp_rdy),
  .fetch_resp_val(fetch_resp_val),
  .fetch_resp_inst(fetch_resp_inst),
  .read_req_rdy(read_req_rdy),
  .read_req_addr(read_req_addr),
  .read_req_addr_val(read_req_addr_val),
  .read_resp_rdy(read_resp_rdy),
  .read_resp_data(read_resp_data),
  .read_resp_data_val(read_resp_data_val),
  .write_req_rdy(write_req_rdy),
  .write_req_addr(write_req_addr),
  .write_req_data(write_req_data),
  .write_req_val(write_req_val),
  .write_resp_val(write_resp_val)
);

initial begin 
  $dumpfile("cu_dump.vcd");
  $dumpvars(1, inst_cu);
end

endmodule