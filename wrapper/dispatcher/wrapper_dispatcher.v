`include "../../src/dispatcher/dispatcher.v"
module wrapper_dispatcher #(
  parameter NUM_CORES = 4
) (
input clk, 
input reset,

// Functional Inputs
input [4:0] thread_count,
input kernel_start, 

// I/O to interact with cores 
input [NUM_CORES-1:0] cu_complete, 
output [NUM_CORES-1:0] cu_enable,
output [NUM_CORES-1:0] cu_reset,
output [2:0] cu_active_threads [NUM_CORES-1:0], 

// Functional Outputs
output kernel_complete
); 

dispatcher #(
  .NUM_CORES(NUM_CORES)
) inst_dispatcher (
  .clk(clk),
  .reset(reset),
  .thread_count(thread_count),
  .kernel_start(kernel_start),
  .cu_complete(cu_complete),
  .cu_enable(cu_enable),
  .cu_reset(cu_reset),
  .cu_active_threads(cu_active_threads),
  .kernel_complete(kernel_complete)
);

initial begin 
  $dumpfile("dispatcher_dump.vcd");
  $dumpvars(0, inst_dispatcher);
end

endmodule