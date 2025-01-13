// ===========================================
// Instruction Memory Controller Module
// 
// Memory controller to handle requests from the fetcher 
// of the different compute units
// ===========================================
module inst_controller #(
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

  // For debugging
  output [NUM_CORES-1:0] compute_unit
);

// Progression localparam
localparam  IDLE = 2'd0,      // Channel is waiting for a memory request
            REQUEST = 2'd1,   // Channel is processing the mem req
            RESPONSE = 2'd2;  // Channel is sending mem resp to appropriate compute unit

reg [1:0] channel_state;
reg [NUM_CORES-1:0] selected_unit;
assign compute_unit = selected_unit;


// Registering outputs 
reg fetch_req_rdy_reg [NUM_CORES-1:0];
reg fetch_resp_val_reg [NUM_CORES-1:0];
reg [MEM_DATA_WIDTH-1:0] fetch_resp_inst_reg [NUM_CORES-1:0];
reg mem2fetch_req_val_reg;
reg [MEM_ADDR_WIDTH-1:0] mem2fetch_req_addr_reg;
reg mem2fetch_resp_rdy_reg;

genvar k;
for (k=0;k<NUM_CORES;k=k+1) begin 
  // assign fetch_req_rdy[i] = fetch_req_rdy_reg[i];
  assign fetch_req_rdy[k] = mem2fetch_req_rdy;
  assign fetch_resp_val[k] = fetch_resp_val_reg[k];
  assign fetch_resp_inst[k] = fetch_resp_inst_reg[k];
end

// integer j;
// for (j=0;j<NUM_MEM_CHAN;j=j+1)begin 
//   assign fetch_req_val[j] = fetch_req_val_reg[j];
//   assign fetch_req_addr_reg[j] = fetch_req_addr_reg[j];
//   assign fetch_resp_rdy_reg[j] = fetch_resp_rdy_reg[j];
// end

assign mem2fetch_req_val = mem2fetch_req_val_reg;
assign mem2fetch_req_addr = mem2fetch_req_addr_reg;
assign mem2fetch_resp_rdy = mem2fetch_resp_rdy_reg;

integer i;
always @(posedge clk) begin 
  if (reset) begin 
    for (i=0;i<NUM_CORES;i=i+1) begin 
      // fetch_req_rdy_reg[i] <= 0;
      fetch_resp_val_reg[i] <= 0;
      fetch_resp_inst_reg[i] <= 0;
    end
    // for (j=0;j<NUM_MEM_CHAN;j=j+1)begin 
    //   fetch_req_val[j] <= 0;
    //   fetch_req_addr_reg[j] <= 0;
    //   fetch_resp_rdy_reg[j] <= 0;
    //   channel_state[j] <= 0;
    // end
    mem2fetch_req_val_reg <= 0;
    mem2fetch_req_addr_reg <= 0;
    mem2fetch_resp_rdy_reg <= 0;
    channel_state <= IDLE;
    selected_unit <= 0;
  end else begin 
    case (channel_state)
  
      IDLE: begin 
        // Loop through all of our cu to find a fetcher that is ready
        for (i=0;i<NUM_CORES;i=i+1)begin 
          if (fetch_req_val[i]) begin 
            // Identified that cu[i] is ready 
            selected_unit <= i;
            // Selecting cu[i]'s signals to pass onto the output
            mem2fetch_req_addr_reg <= fetch_req_addr[i];
            mem2fetch_req_val_reg <= fetch_req_val[i];
            mem2fetch_resp_rdy_reg <= 1; // Ready to accept response
            channel_state <= REQUEST;
            i = NUM_CORES-1; // Synthesizable logic to quit the loop
          end
        end
      end
      REQUEST: begin 
        // Wait until we hear back from the memory 
        if (mem2fetch_resp_rdy) begin 
          fetch_resp_inst_reg[selected_unit] <= mem2fetch_resp_inst;
          fetch_resp_val_reg[selected_unit] <= mem2fetch_resp_val;
          mem2fetch_resp_rdy_reg <= 0; // Disable the signal 
          channel_state <= RESPONSE;
        end 
      end
      RESPONSE: begin
        // Wait until we hear back from the core 
        // THOUGHT: I think because it only requires 1 cycle in fetcher
        // we can simply move back to IDLE and reset values
        channel_state <= IDLE;
        // "unlink" the wiring
        fetch_resp_inst_reg[selected_unit] <= 0;
        fetch_resp_val_reg[selected_unit] <= 0; 
      end

    endcase
  end
end

// For dumping 


endmodule