// ===========================================
// Data Memory Controller
// 
// Memory controller to handle requests from the LSU
// To simply things, it processes requests from a single 
// core at a time, essentially supporting a 4-wide data req/resp
// instead of supporting 4 unqiue threads.
// 
// ===========================================
module data_controller #(
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

localparam  REQ = 4'd3, 
            WAIT = 4'd4,
            EXECUTE = 4'd5, 
            WRITEBACK = 4'd6,
            DONE = 4'd7;

// Progression localparam
localparam  IDLE = 4'd0,      // Channel is waiting for a memory request
            READ_REQUEST = 4'd1,   // Channel is processing the mem req
            RESPONSE = 4'd2,  // Channel is sending mem resp to appropriate compute unit
            WRITE_REQUEST = 4'd3;
// Registering Outputs
reg read_req_rdy_reg                        [(NUM_CORES * MAX_THREADS)-1:0];
reg [MEM_DATA_WIDTH-1:0] read_resp_data_reg [(NUM_CORES * MAX_THREADS)-1:0];
reg read_resp_data_val_reg                  [(NUM_CORES * MAX_THREADS)-1:0];
reg write_req_rdy_reg                       [(NUM_CORES * MAX_THREADS)-1:0];
reg write_resp_val_reg                      [(NUM_CORES * MAX_THREADS)-1:0];
reg [MEM_ADDR_WIDTH-1:0] mem2read_req_addr_reg  [MAX_THREADS-1:0];
reg mem2read_req_addr_val_reg                   [MAX_THREADS-1:0];
reg mem2read_resp_rdy_reg                       [MAX_THREADS-1:0];
reg [MEM_ADDR_WIDTH-1:0] mem2write_req_addr_reg [MAX_THREADS-1:0];
reg [MEM_DATA_WIDTH-1:0] mem2write_req_data_reg [MAX_THREADS-1:0];
reg mem2write_req_val_reg                       [MAX_THREADS-1:0];

genvar j;
for (j=0;j<NUM_CORES*MAX_THREADS;j=j+1) begin 
  assign read_req_rdy[j] = read_req_rdy_reg[j];
  // assign read_req_rdy[j] = mem2read_req_rdy[j];
  assign read_resp_data[j] = read_resp_data_reg[j];
  assign read_resp_data_val[j] = read_resp_data_val_reg[j];
  assign write_req_rdy[j] = write_req_rdy_reg[j];
  assign write_resp_val[j] = write_resp_val_reg[j];
end
for (j=0;j<MAX_THREADS;j=j+1) begin 
  assign mem2read_req_addr[j] = mem2read_req_addr_reg[j];
  assign mem2read_req_addr_val[j] = mem2read_req_addr_val_reg[j];
  assign mem2read_resp_rdy[j] = mem2read_resp_rdy_reg[j];
  assign mem2write_req_addr[j] = mem2write_req_addr_reg[j];
  assign mem2write_req_data[j] = mem2write_req_data_reg[j];
  assign mem2write_req_val[j] = mem2write_req_val_reg[j];
end

wire [3:0] is_read_ready [NUM_CORES-1:0]; 
wire [3:0] is_write_ready [NUM_CORES-1:0];
for (j=0;j<MAX_THREADS*NUM_CORES;j=j+1) begin 
  if (j == 3) begin 
    assign is_read_ready[0][0] = read_req_addr_val[0];
    assign is_read_ready[0][1] = read_req_addr_val[1];
    assign is_read_ready[0][2] = read_req_addr_val[2];
    assign is_read_ready[0][3] = read_req_addr_val[3];
    assign is_write_ready[0][0] = write_req_val[0];
    assign is_write_ready[0][1] = write_req_val[1];
    assign is_write_ready[0][2] = write_req_val[2];
    assign is_write_ready[0][3] = write_req_val[3];
  end else if (j == 7) begin 
    assign is_read_ready[1][0] = read_req_addr_val[4];
    assign is_read_ready[1][1] = read_req_addr_val[5];
    assign is_read_ready[1][2] = read_req_addr_val[6];
    assign is_read_ready[1][3] = read_req_addr_val[7];
    assign is_write_ready[1][0] = write_req_val[4];
    assign is_write_ready[1][1] = write_req_val[5];
    assign is_write_ready[1][2] = write_req_val[6];
    assign is_write_ready[1][3] = write_req_val[7];
  end else if (j == 11) begin 
    assign is_read_ready[2][0] = read_req_addr_val[8];
    assign is_read_ready[2][1] = read_req_addr_val[9];
    assign is_read_ready[2][2] = read_req_addr_val[10];
    assign is_read_ready[2][3] = read_req_addr_val[11];
    assign is_write_ready[2][0] = write_req_val[8];
    assign is_write_ready[2][1] = write_req_val[9];
    assign is_write_ready[2][2] = write_req_val[10];
    assign is_write_ready[2][3] = write_req_val[11];
  end else if (j == 15) begin 
    assign is_read_ready[3][0] = read_req_addr_val[12];
    assign is_read_ready[3][1] = read_req_addr_val[13];
    assign is_read_ready[3][2] = read_req_addr_val[14];
    assign is_read_ready[3][3] = read_req_addr_val[15];
    assign is_write_ready[3][0] = write_req_val[12];
    assign is_write_ready[3][1] = write_req_val[13];
    assign is_write_ready[3][2] = write_req_val[14];
    assign is_write_ready[3][3] = write_req_val[15];
  end
end

for (j=0;j<MAX_THREADS*NUM_CORES;j=j+1) begin 
  if (j < 4) begin 
    assign read_req_rdy_reg[j] = mem2read_req_rdy[0];
    assign write_req_rdy_reg[j] = mem2write_req_rdy[0];
  end else if (j < 8) begin 
    assign read_req_rdy_reg[j] = mem2read_req_rdy[1];
    assign write_req_rdy_reg[j] = mem2write_req_rdy[1];
  end else if (j < 12) begin 
    assign read_req_rdy_reg[j] = mem2read_req_rdy[2]; 
    assign write_req_rdy_reg[j] = mem2write_req_rdy[2];
  end else if (j < 16) begin 
    assign read_req_rdy_reg[j] = mem2read_req_rdy[3]; 
    assign write_req_rdy_reg[j] = mem2write_req_rdy[3];
  end
end

// Internal states
reg [3:0] channel_state;
reg [NUM_CORES-1:0] selected_unit;
assign compute_unit = selected_unit;

integer i;
always @(posedge clk) begin 
  if (reset) begin 
      // read_req_rdy_reg[i] <= 0;
      // read_req_rdy_reg[i] <= mem2read_req_rdy[mem_chan];
      read_resp_data_reg[i] <= 0;
      read_resp_data_val_reg[i] <= 0;
      // write_req_rdy_reg[i] <= mem2write_req_rdy[mem_chan];
      write_resp_val_reg[i] <= 0;
    for (i=0;i<MAX_THREADS;i=i+1)begin 
      mem2read_req_addr_reg[i] <= 0;
      mem2read_req_addr_val_reg[i] <= 0;
      mem2read_resp_rdy_reg[i] <= 0;
      mem2write_req_addr_reg[i] <= 0;
      mem2write_req_data_reg[i] <= 0;
      mem2write_req_val_reg[i] <= 0;
    end
    channel_state <= IDLE;
    selected_unit <= 0;
  end else begin 
    case (channel_state)
      IDLE: begin 
        // Iterate through the active cores to find one with all 4 channels ready 
        for (i=0;i<NUM_CORES;i=i+1)begin 
          // First Conducting read request check 
          if (is_read_ready[i] == 15) begin 
            selected_unit <= i;
            channel_state <= READ_REQUEST;
            i = NUM_CORES-1;
          end
          // Also conduct a write check
          if (is_write_ready[i] == 15) begin 
            selected_unit <= i;
            channel_state <= WRITE_REQUEST;
            i = NUM_CORES-1;
          end
        end
      end
      READ_REQUEST: begin 
        // Pass through the values
        for (i=0;i<MAX_THREADS;i=i+1) begin 
          mem2read_req_addr_val_reg[i] <= read_req_addr_val[4*selected_unit+i];
          mem2read_req_addr_reg[i] <= read_req_addr[4*selected_unit+i];
          mem2read_resp_rdy_reg[i] <= read_resp_rdy[4*selected_unit+i];
          if (mem2read_resp_data_val[i] && read_resp_rdy[4*selected_unit+i]) begin 
            read_resp_data_reg[4*selected_unit+i] <= mem2read_resp_data[i];
            read_resp_data_val_reg[4*selected_unit+i] <= mem2read_resp_data_val[i];
            channel_state <= RESPONSE;
          end
        end
      end
      WRITE_REQUEST: begin 
        for (i=0;i<MAX_THREADS;i=i+1) begin 
          mem2write_req_addr_reg[i] <= write_req_addr[4*selected_unit+i];
          mem2write_req_data_reg[i] <= write_req_data[4*selected_unit+i];
          mem2write_req_val_reg[i] <= write_req_val[4*selected_unit+i];
          if (mem2write_resp_val[i]) begin
            write_resp_val_reg[4*selected_unit+i] <= mem2write_resp_val[i]; // !!! Not sure if we even use this signal
            channel_state <= RESPONSE;
          end
        end
      end
      RESPONSE: begin 
        // Reset values if we have finished accepting the request
        if (compute_state[selected_unit] == WRITEBACK) begin
          for (i=0;i<MAX_THREADS;i=i+1) begin 
            // Resetting Read Signals
            mem2read_req_addr_val_reg[i] <= 0;
            mem2read_req_addr_reg[i] <= 0;
            mem2read_resp_rdy_reg[i] <= 0;
            read_resp_data_reg[4*selected_unit+i] <= 0;
            read_resp_data_val_reg[4*selected_unit+i] <= 0;

            // Resetting Write Signals
            mem2write_req_addr_reg[i] <= 0;
            mem2write_req_data_reg[i] <= 0;
            mem2write_req_val_reg[i] <= 0;
            write_resp_val_reg[4*selected_unit+i] <= 0;
            channel_state <= IDLE;
            selected_unit <= 0;
          end
        end
      end
    endcase
  end
end

// Debugging wires
wire read_req_rdy0;
wire mem2read_req_rdy0;
assign read_req_rdy0 = read_req_rdy_reg[0];
assign mem2read_req_rdy0 = mem2read_req_rdy[0];




endmodule