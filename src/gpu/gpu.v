// ===========================================
// GPU Module
// 
// Connects the lower level components 
// 1. Compute Units (4)
// 2. Dispatcher
// 3. Instruction Memory Controller
// 4. Data Memory controller
// ===========================================
`include "../../src/dispatcher/dispatcher.v"
`include "../../src/cu/cu.v"
`include "../../src/controllers/data_control.v"
`include "../../src/controllers/inst_control.v"
module gpu #(
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

initial begin 
  $dumpfile("gpu_dump.vcd");
  $dumpvars(0, gpu);
end

// Internal Wire / Register Instantiations - Dispatcher
reg [NUM_CORES-1:0] cu_enable;
reg [NUM_CORES-1:0] cu_reset;
reg [NUM_CORES-1:0] cu_complete;
reg [2:0] active_threads [NUM_CORES-1:0];

// Module Instantiation
dispatcher #(
  .NUM_CORES(NUM_CORES)
) inst_dispatcher (
  .clk(clk),
  .reset(reset),
  .thread_count(5'b10000),
  .kernel_start(kernel_start),
  .cu_complete(cu_complete),
  .cu_enable(cu_enable),
  .cu_reset(cu_reset),
  .cu_active_threads(active_threads),
  .kernel_complete(kernel_complete)
);

// Internal Wire / Register Instantiations - Instructions
wire fetch_req_rdy [NUM_CORES-1:0];
reg fetch_req_val [NUM_CORES-1:0];
reg [MEM_ADDR_WIDTH-1:0] fetch_req_addr [NUM_CORES-1:0];
reg fetch_resp_rdy [NUM_CORES-1:0];
wire fetch_resp_val [NUM_CORES-1:0];
wire [MEM_DATA_WIDTH-1:0] fetch_resp_inst [NUM_CORES-1:0];

wire fetch_req_rdy_gpu0; 
wire mem2fetch_req_rdy_gpu0; 
assign fetch_req_rdy_gpu0 = fetch_req_rdy[0];
assign mem2fetch_req_rdy_gpu0 = mem2fetch_req_rdy;

inst_controller #(
  .NUM_MEM_CHAN(1),
  .NUM_CORES(NUM_CORES),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .MEM_DATA_WIDTH(MEM_DATA_WIDTH)
) instructions (
  .clk(clk),
  .reset(reset),
  // Compute Unit connection
  .fetch_req_rdy(fetch_req_rdy),
  .fetch_req_val(fetch_req_val),
  .fetch_req_addr(fetch_req_addr),
  .fetch_resp_rdy(fetch_resp_rdy),
  .fetch_resp_val(fetch_resp_val),
  .fetch_resp_inst(fetch_resp_inst),
  // Global Memory Connection
  .mem2fetch_req_rdy(mem2fetch_req_rdy),
  .mem2fetch_req_val(mem2fetch_req_val),
  .mem2fetch_req_addr(mem2fetch_req_addr),
  .mem2fetch_resp_rdy(mem2fetch_resp_rdy),
  .mem2fetch_resp_val(mem2fetch_resp_val),
  .mem2fetch_resp_inst(mem2fetch_resp_inst),
  .compute_state(compute_state),
  .compute_unit()
);

// Internal Wire / Register Instantiations - Instructions
wire read_req_rdy [(NUM_CORES*THREADS_PER_CORE)-1:0];
reg read_req_addr_val [(NUM_CORES*THREADS_PER_CORE)-1:0];
reg [MEM_ADDR_WIDTH-1:0] read_req_addr [(NUM_CORES*THREADS_PER_CORE)-1:0];

reg read_resp_rdy [(NUM_CORES*THREADS_PER_CORE)-1:0];
wire [MEM_DATA_WIDTH-1:0] read_resp_data [(NUM_CORES*THREADS_PER_CORE)-1:0];
wire read_resp_data_val [(NUM_CORES*THREADS_PER_CORE)-1:0];

wire write_req_rdy [(NUM_CORES*THREADS_PER_CORE)-1:0];
reg [MEM_ADDR_WIDTH-1:0] write_req_addr [(NUM_CORES*THREADS_PER_CORE)-1:0];
reg [MEM_DATA_WIDTH-1:0] write_req_data [(NUM_CORES*THREADS_PER_CORE)-1:0];
reg write_req_val [(NUM_CORES*THREADS_PER_CORE)-1:0];

wire write_resp_val [(NUM_CORES*THREADS_PER_CORE)-1:0];

// Top level debugging
reg read_req_rdy0; 
reg read_req_rdy1; 
reg read_req_rdy2; 
reg read_req_rdy3; 
assign read_req_rdy0 = read_req_rdy[0]; 
assign read_req_rdy1 = read_req_rdy[1]; 
assign read_req_rdy2 = read_req_rdy[2]; 
assign read_req_rdy3 = read_req_rdy[3]; 

data_controller #(
  .NUM_DATA_CHAN(4),
  .NUM_CORES(NUM_CORES),
  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
  .MEM_DATA_WIDTH(MEM_DATA_WIDTH),
  .MAX_THREADS(THREADS_PER_CORE)
) data (
  .clk(clk),
  .reset(reset),
  // Internal Compute Unit Connections
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
  // Global Memory Connection
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
  .compute_unit()
);

reg [3:0] compute_state [NUM_CORES-1:0];

genvar i;
for (i=0;i<NUM_CORES;i=i+1) begin 
  // Creating the separate registers here to help with slicing
  reg read_req_rdy_unit [THREADS_PER_CORE-1:0]; 
  wire read_req_addr_val_unit [THREADS_PER_CORE-1:0];
  wire [MEM_ADDR_WIDTH-1:0] read_req_addr_unit [THREADS_PER_CORE-1:0];
  wire read_resp_rdy_unit [THREADS_PER_CORE-1:0]; 
  reg [MEM_DATA_WIDTH-1:0] read_resp_data_unit [THREADS_PER_CORE-1:0];
  reg read_resp_data_val_unit [THREADS_PER_CORE-1:0];
  reg write_req_rdy_unit [THREADS_PER_CORE-1:0];
  wire [MEM_ADDR_WIDTH-1:0] write_req_addr_unit [THREADS_PER_CORE-1:0];
  wire [MEM_DATA_WIDTH-1:0] write_req_data_unit [THREADS_PER_CORE-1:0];
  wire write_req_val_unit [THREADS_PER_CORE-1:0];
  reg write_resp_val_unit [THREADS_PER_CORE-1:0];

  // Assigning the appropriate value
  genvar k;
  for (k=0;k<THREADS_PER_CORE;k=k+1) begin
    always @(posedge clk) begin 
      localparam selected_thread= 4*i + k;
      read_req_rdy_unit[k] <= read_req_rdy[selected_thread];
      read_req_addr_val[selected_thread] <= read_req_addr_val_unit[k];
      read_req_addr[selected_thread] <= read_req_addr_unit[k]; 

      read_resp_rdy[selected_thread] <= read_resp_rdy_unit[k];
      read_resp_data_unit[k] <= read_resp_data[selected_thread];
      read_resp_data_val_unit[k] <= read_resp_data_val[selected_thread];

      write_req_rdy_unit[k] <= write_req_rdy[selected_thread];
      write_req_addr[selected_thread] <= write_req_addr_unit[k];
      write_req_data[selected_thread] <= write_req_data_unit[k];
      write_req_val[selected_thread] <= write_req_val_unit[k];
      write_resp_val_unit[k] <= write_resp_val[selected_thread];
    end
  end

  cu #(
    .NUM_THREADS(THREADS_PER_CORE),
    .DATA_WIDTH(MEM_DATA_WIDTH),
    .DATA_ADDR_WIDTH(MEM_ADDR_WIDTH),
    .PC_ADDR_WIDTH(MEM_ADDR_WIDTH),
    .INST_MSG_WIDTH(MEM_DATA_WIDTH),
    .CU_IDX(i)
  ) inst_cu (
    .clk(clk),
    .reset(cu_reset[i]),
    // Internal Compute Unit I/O
    .cu_enable(cu_enable[i]),
    .cu_complete(cu_complete[i]),
    .active_threads(active_threads[i]),
    .compute_state(compute_state[i]),
    // Fetcher Interface <==> Instruction Mem Controller
    .fetch_req_rdy(fetch_req_rdy[i]),
    .fetch_req_val(fetch_req_val[i]),
    .fetch_req_addr(fetch_req_addr[i]),
    .fetch_resp_rdy(fetch_resp_rdy[i]),
    .fetch_resp_val(fetch_resp_val[i]),
    .fetch_resp_inst(fetch_resp_inst[i]),
    // LSU Interface <==> Data Mem Controller
    .read_req_rdy(read_req_rdy_unit),
    .read_req_addr(read_req_addr_unit),
    .read_req_addr_val(read_req_addr_val_unit),
    .read_resp_rdy(read_resp_rdy_unit),
    .read_resp_data(read_resp_data_unit),
    .read_resp_data_val(read_resp_data_val_unit),
    .write_req_rdy(write_req_rdy_unit),
    .write_req_addr(write_req_addr_unit),
    .write_req_data(write_req_data_unit),
    .write_req_val(write_req_val_unit),
    .write_resp_val(write_resp_val_unit)
  );

  initial begin 
    $dumpvars (1, inst_cu);
  end

end

endmodule