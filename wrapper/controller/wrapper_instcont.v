`include "../../src/controllers/inst_controller.v"
module wrapper_instcont #(
  parameter NUM_MEM_CHAN = 1,
            NUM_CORES = 4,
            MEM_ADDR_WIDTH = 8,
            MEM_DATA_WIDTH = 16
) (
  input clk,
  input reset,

  // I/O from internal GPU Fetcher blocks 
  output fetch_req_rdy [NUM_CORES-1:0], 
  input fetch_req_val [NUM_CORES-1:0], 
  input [MEM_ADDR_WIDTH-1:0] fetch_req_addr [NUM_CORES-1:0],

  input fetch_resp_rdy [NUM_CORES-1:0], 
  output fetch_resp_val [NUM_CORES-1:0],
  output [MEM_DATA_WIDTH-1:0] fetch_resp_inst [NUM_CORES-1:0],

  // I/O to interface with global memory
  input mem2fetch_req_rdy,
  output mem2fetch_req_val,
  output [MEM_ADDR_WIDTH-1:0] mem2fetch_req_addr, // Uses current pc

  output mem2fetch_resp_rdy, 
  input mem2fetch_resp_val,
  input [MEM_DATA_WIDTH-1:0] mem2fetch_resp_inst,

  output [NUM_CORES-1:0] compute_unit
);

inst_controller #(
  .NUM_MEM_CHAN(NUM_MEM_CHAN),
  .NUM_CORES(NUM_CORES),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .MEM_DATA_WIDTH(MEM_DATA_WIDTH)
) instructions (
  .clk(clk),
  .reset(reset),
  .fetch_req_rdy(fetch_req_rdy),
  .fetch_req_val(fetch_req_val),
  .fetch_req_addr(fetch_req_addr),
  .fetch_resp_rdy(fetch_resp_rdy),
  .fetch_resp_val(fetch_resp_val),
  .fetch_resp_inst(fetch_resp_inst),
  .mem2fetch_req_rdy(mem2fetch_req_rdy),
  .mem2fetch_req_val(mem2fetch_req_val),
  .mem2fetch_req_addr(mem2fetch_req_addr),
  .mem2fetch_resp_rdy(mem2fetch_resp_rdy),
  .mem2fetch_resp_val(mem2fetch_resp_val),
  .mem2fetch_resp_inst(mem2fetch_resp_inst),
  .compute_unit(compute_unit)
);

// Dumping
initial begin 
  $dumpfile("instcont_dump.vcd");
  $dumpvars(0, instructions);
end

endmodule