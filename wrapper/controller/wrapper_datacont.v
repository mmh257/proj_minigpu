`include "../../src/controllers/data_control.v"
module wrapper_datacontroller #(
  parameter NUM_DATA_CHAN = 1, 
            NUM_CORES = 4,
            MEM_ADDR_WIDTH = 8,
            MEM_DATA_WIDTH = 16,
            MAX_THREADS = 4
) (
  input clk,
  input reset,
  // I/O With Compute Units
  // LSU Read Request
  output read_req_rdy                         [(NUM_CORES * MAX_THREADS)-1:0], 
  input [MEM_ADDR_WIDTH-1:0] read_req_addr    [(NUM_CORES * MAX_THREADS)-1:0],
  input read_req_addr_val                     [(NUM_CORES * MAX_THREADS)-1:0],
  // LSU Read Response
  input read_resp_rdy                         [(NUM_CORES * MAX_THREADS)-1:0],
  output [MEM_DATA_WIDTH-1:0] read_resp_data  [(NUM_CORES * MAX_THREADS)-1:0],
  output read_resp_data_val                   [(NUM_CORES * MAX_THREADS)-1:0],
  // Write Request
  output write_req_rdy                        [(NUM_CORES * MAX_THREADS)-1:0],
  input [MEM_ADDR_WIDTH-1:0] write_req_addr   [(NUM_CORES * MAX_THREADS)-1:0],
  input [MEM_DATA_WIDTH-1:0] write_req_data   [(NUM_CORES * MAX_THREADS)-1:0],
  input write_req_val                         [(NUM_CORES * MAX_THREADS)-1:0],
  // Write Response
  output write_resp_val                       [(NUM_CORES * MAX_THREADS)-1:0],

  // I/O With Global Memory
  // Memory Access Signals - LSU
  input mem2read_req_rdy                        [MAX_THREADS-1:0], 
  output [MEM_ADDR_WIDTH-1:0] mem2read_req_addr [MAX_THREADS-1:0],
  output mem2read_req_addr_val                  [MAX_THREADS-1:0],
  
  // Read (Load) Response
  output mem2read_resp_rdy                      [MAX_THREADS-1:0],
  input [MEM_DATA_WIDTH-1:0] mem2read_resp_data [MAX_THREADS-1:0],
  input mem2read_resp_data_val                  [MAX_THREADS-1:0],

  // Write (Store) Request
  input mem2write_req_rdy                         [MAX_THREADS-1:0],
  output [MEM_ADDR_WIDTH-1:0] mem2write_req_addr  [MAX_THREADS-1:0], 
  output [MEM_DATA_WIDTH-1:0] mem2write_req_data  [MAX_THREADS-1:0], 
  output mem2write_req_val                        [MAX_THREADS-1:0],

  // Write Response
  input mem2write_resp_val                        [MAX_THREADS-1:0],

  // Functional I/O (For TB)
  input [3:0] compute_state [NUM_CORES-1:0],
  // For debugging
  output [NUM_CORES-1:0] compute_unit
);

data_controller #(
  .NUM_DATA_CHAN(NUM_DATA_CHAN),
  .NUM_CORES(NUM_CORES),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .MEM_DATA_WIDTH(MEM_DATA_WIDTH),
  .MAX_THREADS(MAX_THREADS)
) inst_datacont (
  .clk(clk),
  .reset(reset),
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
  .write_resp_val(write_resp_val),
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
  .compute_state(compute_state),
  .compute_unit(compute_unit)
);

// Dump
initial begin 
  $dumpfile("datacont_dump.vcd");
  $dumpvars(0, inst_datacont);
end

endmodule