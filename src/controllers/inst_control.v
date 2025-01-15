// ===========================================
// Instruction Memory Controller Module
// 
// Memory controller to handle requests from the fetcher 
// of the different compute units
//
// VERSION 2
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

  // Functional I/O
  input [3:0] compute_state [NUM_CORES-1:0],

  // For debugging
  output [NUM_CORES-1:0] compute_unit
);

localparam  FETCH = 4'd1,
            DECODE = 4'd2;

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
  assign fetch_req_rdy[k] = fetch_req_rdy_reg[k];
  // assign fetch_req_rdy[k] = mem2fetch_req_rdy;
  assign fetch_resp_val[k] = fetch_resp_val_reg[k];
  assign fetch_resp_inst[k] = fetch_resp_inst_reg[k];
end

assign mem2fetch_req_val = mem2fetch_req_val_reg;
assign mem2fetch_req_addr = mem2fetch_req_addr_reg;
assign mem2fetch_resp_rdy = mem2fetch_resp_rdy_reg;

integer i;
always @(posedge clk) begin 
  if (reset) begin 
    for (i=0;i<NUM_CORES;i=i+1) begin 
      fetch_resp_val_reg[i] <= 0;
      fetch_resp_inst_reg[i] <= 0;
      fetch_req_rdy_reg[i] <= mem2fetch_req_rdy;
    end
    mem2fetch_req_val_reg <= 0;
    mem2fetch_req_addr_reg <= 0;
    mem2fetch_resp_rdy_reg <= 0;
    channel_state <= IDLE;
    selected_unit <= 0;
  end else begin 
    case (channel_state)
      IDLE: begin 
        // Iterate through all compute units to select one to process
        for (i=0;i<NUM_CORES;i=i+1)begin 
          fetch_req_rdy_reg[i] <= mem2fetch_req_rdy;
          if (fetch_req_val[i]) begin 
            // unit[i] has an active request
            selected_unit <= i;
            channel_state <= REQUEST;
            i = NUM_CORES-1;
          end
        end
      end
      REQUEST: begin 
        mem2fetch_req_val_reg <= fetch_req_val[selected_unit]; 
        mem2fetch_req_addr_reg <= fetch_req_addr[selected_unit];
        mem2fetch_resp_rdy_reg <= fetch_resp_rdy[selected_unit];
        if (mem2fetch_resp_val && fetch_resp_rdy[selected_unit]) begin 
          fetch_resp_val_reg[selected_unit] <= 1;
          fetch_resp_inst_reg[selected_unit] <= mem2fetch_resp_inst;
          channel_state <= RESPONSE;
        end
      end
      RESPONSE: begin 
        if (compute_state[selected_unit] == DECODE) begin 
          // The compute unit finished processing the fetch, reset all connections
          mem2fetch_req_val_reg <= 0; 
          mem2fetch_req_addr_reg <= 0;
          mem2fetch_resp_rdy_reg <= 0;
          fetch_resp_val_reg[selected_unit] <= 0;
          fetch_resp_inst_reg[selected_unit] <= 0;
          selected_unit <= 0;
          channel_state <= IDLE;
        end
      end
    endcase
  end
end

// For debugging
wire [3:0] state_0;
wire [3:0] state_1;
wire [3:0] state_2;
wire [3:0] state_3;
assign state_0 = compute_state[0];
assign state_1 = compute_state[1];
assign state_2 = compute_state[2];
assign state_3 = compute_state[3];
wire fetch_req_val0;
wire fetch_req_val1;
wire fetch_req_val2;
wire fetch_req_val3;
assign fetch_req_val0 = fetch_req_val[0];
assign fetch_req_val1 = fetch_req_val[1];
assign fetch_req_val2 = fetch_req_val[2];
assign fetch_req_val3 = fetch_req_val[3];
wire fetch_req_rdy0;
wire fetch_req_rdy1;
wire fetch_req_rdy2;
wire fetch_req_rdy3;
assign fetch_req_rdy0 = fetch_req_rdy[0];
assign fetch_req_rdy1 = fetch_req_rdy[1];
assign fetch_req_rdy2 = fetch_req_rdy[2];
assign fetch_req_rdy3 = fetch_req_rdy[3];
wire fetch_resp_rdy0;
wire fetch_resp_rdy1;
wire fetch_resp_rdy2;
wire fetch_resp_rdy3;
wire fetch_resp_val0;
wire fetch_resp_val1;
wire fetch_resp_val2;
wire fetch_resp_val3;
assign fetch_resp_rdy0 = fetch_resp_rdy[0];
assign fetch_resp_rdy1 = fetch_resp_rdy[1];
assign fetch_resp_rdy2 = fetch_resp_rdy[2];
assign fetch_resp_rdy3 = fetch_resp_rdy[3];
assign fetch_resp_val0 = fetch_resp_val[0];
assign fetch_resp_val1 = fetch_resp_val[1];
assign fetch_resp_val2 = fetch_resp_val[2];
assign fetch_resp_val3 = fetch_resp_val[3];


endmodule