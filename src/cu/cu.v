// ===========================================
// Compute Unit Module
// 
// Connects all of the smaller sub compute unit modules
// See block diagram for reference 
// 
// ===========================================
`include "../../src/scheduler/scheduler.v"
`include "../../src/fetcher/fetcher.v"
`include "../../src/decoder/decoder.v"
`include "../../src/alu/alu.v"
`include "../../src/lsu/lsu.v"
`include "../../src/pc/pc.v"
`include "../../src/rf/xblock_rf.v"
module cu #(
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
  input [2:0] active_threads,

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

// Internal Connection Regs
// Scheduler
wire rf_wen;
wire rf_ren;
reg mem_ren;
reg mem_wen;
reg [3:0] cu_state;
assign compute_state = cu_state;

// Decoder Outputs
reg [3:0] rd; 
reg [3:0] rs1; 
reg [3:0] rs2; 
reg [3:0] rimm; 
reg [7:0] imm; 
reg [3:0] alu_func; 
reg [3:0] opcode;
reg is_alu; 
reg is_branch;
reg is_const; 
reg is_load; 
reg is_store; 
reg is_nop;
reg is_jr; 

// Fetcher 
reg [1:0] fetch_state;
reg [INST_MSG_WIDTH-1:0] fetch_instr; 

// LSU
reg [1:0] lsu_state [NUM_THREADS-1:0];

// PC - Will this cause an error? multiple blocks assigning same output
reg [PC_ADDR_WIDTH-1:0] curr_pc [NUM_THREADS-1:0];
wire [PC_ADDR_WIDTH-1:0] next_pc [NUM_THREADS-1:0];

// Internal Signals
wire rf_read_en;
assign rf_read_en = is_load || is_store || is_alu || is_branch;
wire rf_write_en;
assign rf_write_en = is_load || is_alu || is_const;

// Module Instantiations (TOP TO BOTTOM INSTANTIATIONS)
scheduler #(
  .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
  .CU_WIDTH(NUM_THREADS)
) inst_scheduler (
  .clk(clk),
  .reset(reset),
  .cu_enable(cu_enable), // Bubble In
  // From Decoder
  .rd(rd),
  .rs1(rs1),
  .rs2(rs2),
  .rimm(rimm),
  .imm(imm),
  .alu_func(alu_func),
  .is_alu(is_alu),
  .is_branch(is_branch),
  .is_const(is_const),
  .is_load(is_load),
  .is_store(is_store),
  .is_nop(is_nop),
  .is_jr(is_jr),
  // From Fetcher
  .fetch_state(fetch_state), 
  // From LSU
  .lsu_state(lsu_state),
  // From PC
  .next_pc(next_pc[0]), // Only using the zero's thread PC
  .curr_pc(curr_pc[0]),
  //Outputs 
  .rf_wen(rf_wen),
  .rf_ren(rf_ren),
  .mem_ren(mem_ren),
  .mem_wen(mem_wen),
  .cu_state(cu_state),
  .cu_complete(cu_complete) // Bubble Out
);

fetcher #(
  .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
  .INST_MSG_WIDTH(INST_MSG_WIDTH)
) inst_fetcher (
  .clk(clk),
  .reset(reset),
  .cu_state(cu_state),
  .curr_pc(curr_pc[0]), // !!! Only referencing the 0th current pc for fetcher
  .fetch_state(fetch_state),
  .fetch_instr(fetch_instr),
  // Memory Interfacing
  .fetch_req_rdy(fetch_req_rdy),
  .fetch_req_val(fetch_req_val),
  .fetch_req_addr(fetch_req_addr),
  .fetch_resp_rdy(fetch_resp_rdy),
  .fetch_resp_val(fetch_resp_val),
  .fetch_resp_inst(fetch_resp_inst)
);

decoder #(
  .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
  .INST_MSG_WIDTH(INST_MSG_WIDTH)
) inst_decoder (
  .clk(clk),
  .reset(reset),
  .cu_state(cu_state),
  .instr(fetch_instr),
  .rd(rd),
  .rs1(rs1),
  .rs2(rs2),
  .rimm(rimm),
  .imm(imm),
  .alu_func(alu_func),
  .opcode(opcode),
  .is_alu(is_alu),
  .is_branch(is_branch),
  .is_const(is_const),
  .is_load(is_load),
  .is_store(is_store),
  .is_nop(is_nop),
  .is_jr(is_jr)
); 

// Register Declarations for the X-Block
reg [DATA_WIDTH-1:0] a [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] b [NUM_THREADS-1:0];
// reg [DATA_WIDTH-1:0] out [NUM_THREADS-1:0];
reg cmp_lt [NUM_THREADS-1:0];
reg cmp_eq [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] lsu_load_data [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] alu_out_data [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] rs1_data [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] rs2_data [NUM_THREADS-1:0];
reg [DATA_WIDTH-1:0] rimm_data [NUM_THREADS-1:0];


// "X"-Block Instantiations
genvar i; 
generate
for (i=0; i < NUM_THREADS; i=i+1) begin 
  xblock_rf #(
    .CU_IDX(CU_IDX),
    .CU_WIDTH(NUM_THREADS),
    .THREAD_ID(i),
    .DATA_WIDTH(DATA_WIDTH)
  ) inst_rf(
    .clk(clk),
    .reset(reset),
    .cu_state(cu_state),
    .rf_enable(i < NUM_THREADS),
    .cu_id(16'b0), // !!! Unsure if needed
    //Decoder outputs
    .decoded_rd(rd),
    .decoded_rs1(rs1),
    .decoded_rs2(rs2),
    .decoded_rimm(rimm),
    .decoded_imm(imm),
    .is_alu(is_alu),
    .is_const(is_const),
    .is_read(is_load),
    // LSU Connection
    .lsu_load_data(lsu_load_data[i]),
    .alu_out_data(alu_out_data[i]),
    // Functional IO
    .rf_wen(rf_write_en),
    .rf_ren(rf_read_en),
    .rs1_data(rs1_data[i]),
    .rs2_data(rs2_data[i]),
    .rimm_data(rimm_data[i])
  );

  alu inst_alu (
    .clk(clk),
    .reset(reset),
    .alu_en(i<NUM_THREADS),
    .alu_func(alu_func),
    .a(rs1_data[i]),
    .b(rs2_data[i]),
    .out(alu_out_data[i]),
    .cmp_lt(cmp_lt[i]),
    .cmp_eq(cmp_eq[i])
  );

  lsu #(
    .DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) inst_lsu (
    .clk(clk),
    .reset(reset),
    .cu_state(cu_state),
    .lsu_en(i<NUM_THREADS),
    .mem_ren(is_load),
    .mem_wen(is_store),
    .rs1(rs1_data[i]),
    .rs2(rs2_data[i]),
    .lsu_data_out(lsu_load_data[i]),
    .lsu_state(lsu_state[i]),
    //Memory Requests
    .read_req_rdy(read_req_rdy[i]),
    .read_req_addr(read_req_addr[i]),
    .read_req_addr_val(read_req_addr_val[i]),
    .read_resp_rdy(read_resp_rdy[i]),
    .read_resp_data(read_resp_data[i]),
    .read_resp_data_val(read_resp_data_val[i]),
    .write_req_rdy(write_req_rdy[i]),
    .write_req_addr(write_req_addr[i]),
    .write_req_data(write_req_data[i]),
    .write_req_val(write_req_val[i]),
    .write_resp_val(write_resp_val[i])
  );

  pc #(
    .PC_ADDR_WIDTH(PC_ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) inst_pc (
    .clk(clk),
    .reset(reset),
    .pc_en(i<NUM_THREADS),
    .cu_state(cu_state),
    .curr_pc(curr_pc[i]),
    .alu_out(alu_out_data[i]),
    .br_imm(rimm_data[i]),
    .opcode(opcode),
    .cmp_lt(cmp_lt[i]),
    .cmp_eq(cmp_eq[i]),
    .alu_func(alu_func),
    .next_pc(next_pc[i]) // Each LSU will have a separate PC, but we will only use the 0th thread's PC to update
  );
end
endgenerate

// // VCD Dumping 
// initial begin 
//   $dumpfile("cu_dump.vcd");
//   $dumpvars(1, cu);
//   $dumpvars(2, inst_scheduler);
//   $dumpvars(2, inst_fetcher);
//   $dumpvars(2, inst_decoder);
// end

endmodule