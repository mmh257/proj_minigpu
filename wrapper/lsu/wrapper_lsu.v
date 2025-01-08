`include "../../src/lsu/lsu.v"
`timescale 1ns/1ps
module wrapper_lsu #(
  parameter DATA_ADDR_WIDTH = 8,
            DATA_WIDTH = 16
) (
  input clk,
  input reset, 
  input [3:0] cu_state, 
  input lsu_en,

  // Functional Inputs
  input mem_ren, 
  input mem_wen, 
  input [15:0] rs1, 
  input [15:0] rs2,

  // Functional Outputs
  output [DATA_WIDTH-1:0] lsu_data_out,
  output [1:0] lsu_state, 
  
  // Read (Load) Request
  input read_req_rdy, 
  output [DATA_ADDR_WIDTH-1:0] read_req_addr,
  output read_req_addr_val,
  
  // Read (Load) Response
  output read_resp_rdy,
  input [DATA_WIDTH-1:0] read_resp_data,
  input read_resp_data_val,

  // Write (Store) Request
  input write_req_rdy,
  output [DATA_ADDR_WIDTH-1:0] write_req_addr, 
  output [DATA_WIDTH-1:0] write_req_data, 
  output write_req_val,

  // Write (Store) Response : Only one signal to indicate that we are done writing 
  input write_resp_val 
);

lsu #(
  .DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
) inst_lsu(
  .clk(clk),
  .reset(reset),
  .cu_state(cu_state),
  .lsu_en(lsu_en),
  .mem_ren(mem_ren),
  .mem_wen(mem_wen),
  .rs1(rs1),
  .rs2(rs2),
  .lsu_data_out(lsu_data_out),
  .lsu_state(lsu_state),
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
  .write_resp_val(write_resp_val)
);

initial begin 
  $dumpfile("lsu_dump.vcd");
  $dumpvars(1, inst_lsu);
end
endmodule