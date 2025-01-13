// ===========================================
// Memory Controller Module
//
// Simple module that contains signal logic for the 
// different memory interfaces for each of our compute units
//
// To simulate memory in a larger system, since the baseline 
// iteration does not have any caches and instead in a hypothetical 
// scenario, all 4 compute units will be operating on the same 
// instruction which may have up to 4 sets of memory requests going 
// to global memory. In a realistic system, this level of throughput 
// may be expensive to implement, thus a queue like system will be 
// used instead to handle all global memory requests.
//
// Parameter Breakdown:
// NUM_MEM_CHAN: Number of available channels to access global memory
// MEM_ADDR_WIDTH: Width of the address requests
// MEM_DATA_WIDTH: Width of the corresponding data
// NUM_CORES: Number of total cores in the SM (AKA Num of fetchers)
// NUM_THREADS: Number of total threads (AKA num of LSUs)
// ===========================================
module controller #(
  parameter NUM_MEM_CHAN = 1, 
            MEM_ADDR_WIDTH = 8, 
            MEM_DATA_WIDTH = 16,
            NUM_CORES = 4,
            NUM_THREADS = 16,
            NUM_DATA_CHAN = 4
) (
  input clk,
  input reset,

  // I/O from gpu internal blocks (LSU, Fetcher)
  output fetch_req_rdy [NUM_CORES-1:0], 
  input fetch_req_val [NUM_CORES-1:0], 
  input [MEM_ADDR_WIDTH-1:0] fetch_req_addr [NUM_CORES-1:0],

  input fetch_resp_rdy [NUM_CORES-1:0], 
  output fetch_resp_val [NUM_CORES-1:0],
  output [MEM_DATA_WIDTH-1:0] fetch_resp_inst [NUM_CORES-1:0],

  output read_req_rdy [NUM_THREADS-1:0],
  input [MEM_DATA_WIDTH-1:0] read_req_addr [NUM_THREADS-1:0],
  input read_req_addr_val [NUM_THREADS-1:0],

  input read_resp_rdy [NUM_THREADS-1:0],
  output [MEM_DATA_WIDTH-1:0] read_resp_data [NUM_THREADS-1:0],
  output read_resp_data_val [NUM_THREADS-1:0],

  output write_req_rdy [NUM_THREADS-1:0],
  input [MEM_ADDR_WIDTH-1:0] write_req_addr [NUM_THREADS-1:0],
  input [MEM_DATA_WIDTH-1:0] write_req_data [NUM_THREADS-1:0],
  input write_req_val [NUM_THREADS-1:0], 

  output write_resp_val [NUM_THREADS-1:0],

  // I/O to interface with global memory
  input fetch_req_rdy [NUM_MEM_CHAN-1:0],
  output fetch_req_val [NUM_MEM_CHAN-1:0],
  output [MEM_ADDR_WIDTH-1:0] fetch_req_addr [NUM_MEM_CHAN-1:0], // Uses current pc

  output fetch_resp_rdy [NUM_MEM_CHAN-1:0], 
  input fetch_resp_val [NUM_MEM_CHAN-1:0],
  input [MEM_DATA_WIDTH-1:0] fetch_resp_inst [NUM_MEM_CHAN-1:0],

  // Memory Access Signals - LSU
  input read_req_rdy [NUM_DATA_CHAN-1:0], 
  output [MEM_ADDR_WIDTH-1:0] read_req_addr [NUM_DATA_CHAN-1:0],
  output read_req_addr_val [NUM_DATA_CHAN-1:0],
  
  // Read (Load) Response
  output read_resp_rdy [NUM_DATA_CHAN-1:0],
  input [MEM_DATA_WIDTH-1:0] read_resp_data [NUM_DATA_CHAN-1:0],
  input read_resp_data_val [NUM_DATA_CHAN-1:0],

  // Write (Store) Request
  input write_req_rdy [NUM_DATA_CHAN-1:0],
  output [MEM_ADDR_WIDTH-1:0] write_req_addr [NUM_DATA_CHAN-1:0], 
  output [MEM_DATA_WIDTH-1:0] write_req_data [NUM_DATA_CHAN-1:0], 
  output write_req_val [NUM_DATA_CHAN-1:0],

  // Write Response
  input write_resp_val [NUM_DATA_CHAN-1:0]
);

// Logic to arbitrate which sets of requests to send out 
// Only send out data in groups of 4 for data, and groups of 1 for fetcher
// Logic Progression: 
// For each active memory channel, find a core/thread to 
endmodule