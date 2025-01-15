`include "../../src/gpu/gpu.v"
module wrapper_gpu #(
  parameter NUM_CORES = 4, 
            MEM_DATA_WIDTH = 16,
            MEM_ADDR_WIDTH = 8,
            THREADS_PER_CORE = 4
) (
  input clk,
  input reset,

  // Global Memory Interfacing - Intstruction Controller
  // Read Request
  input mem2fetch_req_rdy,
  output mem2fetch_req_val,
  output [MEM_ADDR_WIDTH-1:0] mem2fetch_req_addr, // Uses current pc
  // Read Response
  output mem2fetch_resp_rdy, 
  input mem2fetch_resp_val,
  input [MEM_DATA_WIDTH-1:0] mem2fetch_resp_inst,

  // Global Memory Interfacing - Data Memory Controller
  // Read Request
  input mem2read_req_rdy                        [THREADS_PER_CORE-1:0], 
  output [MEM_ADDR_WIDTH-1:0] mem2read_req_addr [THREADS_PER_CORE-1:0],
  output mem2read_req_addr_val                  [THREADS_PER_CORE-1:0],
  // Read (Load) Response
  output mem2read_resp_rdy                      [THREADS_PER_CORE-1:0],
  input [MEM_DATA_WIDTH-1:0] mem2read_resp_data [THREADS_PER_CORE-1:0],
  input mem2read_resp_data_val                  [THREADS_PER_CORE-1:0],
  // Write (Store) Request
  input mem2write_req_rdy                         [THREADS_PER_CORE-1:0],
  output [MEM_ADDR_WIDTH-1:0] mem2write_req_addr  [THREADS_PER_CORE-1:0], 
  output [MEM_DATA_WIDTH-1:0] mem2write_req_data  [THREADS_PER_CORE-1:0], 
  output mem2write_req_val                        [THREADS_PER_CORE-1:0],
  // Write Response
  input mem2write_resp_val                        [THREADS_PER_CORE-1:0],

  // Functional I/O
  input kernel_start,
  output kernel_complete
);

gpu #(
  .NUM_CORES(NUM_CORES),
  .MEM_DATA_WIDTH(MEM_DATA_WIDTH),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .THREADS_PER_CORE(THREADS_PER_CORE)
) inst_gpu (
  .clk(clk),
  .reset(reset),
  .mem2fetch_req_rdy(mem2fetch_req_rdy),
  .mem2fetch_req_val(mem2fetch_req_val),
  .mem2fetch_req_addr(mem2fetch_req_addr),
  .mem2fetch_resp_rdy(mem2fetch_resp_rdy),
  .mem2fetch_resp_inst(mem2fetch_resp_inst),
  .mem2read_req_rdy(mem2read_req_rdy),
  .mem2read_req_addr(mem2read_req_addr),
  .mem2read_req_addr_val(mem2read_req_addr_val),
  .mem2read_resp_rdy(mem2read_resp_rdy),
  .mem2read_resp_data(mem2read_resp_data),
  .mem2read_resp_data_val(mem2read_resp_data_val),
  .mem2write_req_rdy(mem2write_req_rdy),
  .mem2write_req_addr(mem2write_req_addr),
  .mem2write_req_data(mem2write_req_data),
  .mem2write_req_val(mem2write_req_val),
  .mem2write_resp_val(mem2write_resp_val),
  .kernel_start(kernel_start),
  .kernel_complete(kernel_complete)
);

initial begin 
  $dumpfile("gpu_dump.vcd");
  $dumpvars(0, inst_gpu);
end

endmodule