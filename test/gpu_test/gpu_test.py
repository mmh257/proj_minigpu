import cocotb
from cocotb.triggers import Timer , RisingEdge
from cocotb.clock import Clock
from random import randint
import sys
import os 
sys.path.append(os.path.abspath('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors'))
import data_mem
import inst_mem

# Reset Signal Function
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0 

@cocotb.test()
async def simple_vector_add(dut):
    '''
      This test will be similar to the compute unit vector add test,
      except it will be on a 16 wide vector. 

      DATA MEMORY: 
      1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 
      16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1

      INSTR Memory:
      CONST R12 4     | R12 <= 4
      MUL R7 R12 R13  | R7 <= R12 * R13  | R7 <= 4 * Core_ID
      ADD R11 R7 R15  | R11 <= R11 + R15 | R11 <= 4*Core_ID + Thread_ID
      LW R1 R11       | R1 <= Mem[R11]   | R1 <= Mem[4*Core_ID+Thread_ID]
      CONST R10 16    | R10 <= 16        
      ADD R9 R11 R10  | R9 <= R11 + R10  | R9 <= 4*Core_ID+Thread_ID + 16
      LW R2 R9        | R2 <= Mem[R9]    | R2 <= Mem[R11+16]
      ADD R3 R1 R2    | R3 <= R1 + R2    | R3 <= Mem[i] + Mem[i+16]
      ADD R8 R9 R10   | R8 <= R9 + R10   | R8 <= 4*CU_ID+Thread_ID + 32
      SW R3 R8        | MEM[R8] <= R3
      JR
    '''
    instructions = [
      (0,  0b1000_1100_0000_0100), # CONST R12 4
      (2,  0b0010_0111_1100_1101), # MUL R7 R12 R13
      (4,  0b0000_1011_0111_1111), # ADD R11 R7 R15
      (6,  0b1001_0000_0001_1011), # LW R1 R11
      (8,  0b1000_1010_0001_0000), # CONST R10 16
      (10, 0b0000_1001_1011_1010), # ADD R9 R11 R10
      (12, 0b1001_0000_0010_1001), # LW R2 R9
      (14, 0b0000_0011_0001_0010), # ADD R3 R1 R2
      (16, 0b0000_1000_1001_1010), # ADD R8 R9 R10
      (18, 0b1010_0000_0011_1000), # SW R3 R8
      (20, 0b1100_0000_0000_0000)  # JR
    ]
    data = [
      (0, 1), (1, 2), (2, 3), (3, 4), 
      (4, 5), (5, 6), (6, 7), (7, 8),
      (8, 9), (9, 10), (10, 11), (11, 12), 
      (12, 13), (13, 14), (14, 15), (15, 16), 
      (16, 16), (17, 15), (18, 14), (19, 13),
      (20, 12), (21, 11), (22, 10), (23, 9),
      (24, 8), (25, 7), (26, 6), (27, 5), 
      (28, 4), (29, 3), (30, 2), (31, 1)
    ]
    # Setting up instr and data memory
    inst_memory = inst_mem.InstMemory(dut, 8, 16, "mem2fetch")
    data_memory = data_mem.DataMemory(dut, 8, 16, 4, "mem2")
    data_memory.load(data)
    inst_memory.load(instructions)

    # Setting up clock
    c = Clock(dut.clk, 1, "ns")
    await cocotb.start(c.start())

    # Reset dut
    await cocotb.start(reset_dut(dut.reset, 1))
    await Timer(10, units = "ns")

    dut.kernel_start.value = 1
    cycles = 0
    while (cycles < 500 or not dut.kernel_complete.value == 1): 
      inst_memory.run_nostate()
      data_memory.run_nostate() 
    
      await RisingEdge(dut.clk)
      cycles = cycles + 1
    
    # data_memory.log_data()
    data_memory.pretty_log()

@cocotb.test()
async def simple_mat_mul(dut):
  '''
  Second basic test case to perform matrix multiplication
  To simplify the operation, we will be multiplying 2 2x2 matricies together
  | 1 2 |  \/  | 5 6 |    YIELDS:   | 19 22 |
  | 3 4 |  /\  | 7 8 |              | 43 50 |
  '''

  instr = [
    (0 , 0b1000_0000_0000_0000), # CONST R0 0      : R0 <= base addr A 
    (2 , 0b1000_0001_0001_0000), # CONST R1 16     : R1 <= base addr B
    (4 , 0b1000_0010_0010_0000), # CONST R2 32     : R2 <= base addr C 
    (6 , 0b1000_0011_0000_0010), # CONST R3 2      : R3 <= N (N = 2)
    (8 , 0b1000_0100_0000_0000), # CONST R4 0      : R4 <= k (k = 0)
    (10, 0b1000_1100_0000_0001), # CONST R12 1     : R12 <= 1
    (12, 0b1000_1011_0001_1000), # CONST R11 24    : R11 <= RIMM = 24
    (14, 0b0011_0101_1111_0011), # DIV R5 R15 R3   : R5 <= Thread_ID / N    : R5 <= a_row_id
    (16, 0b0010_0110_0101_0011), # MUL R6 R5 R3    : R6 <= R5 * N
    (18, 0b0001_0110_1111_0110), # SUB R6 R15 R6   : R6 <= Thread_ID - Floor(Thread_ID/N) AKA (Thread_ID mod 2) : R6 <= b_col_id
    (20, 0b0000_0110_0110_0001), # ADD R6 R6 R1    : R6 <= base addr B + b_col_id
    (22, 0b0010_0101_0101_0011), # MUL R5 R5 R3    : R5 <= R5 * 2         : R5 <= start of row index
    # LOOP
    (24, 0b1001_0000_0111_0101), # LW R7 R5        : R7 <= mem[a_row_id]
    (26, 0b1001_0000_1000_0110), # LW R8 R6        : R8 <= mem[b_col_id]
    (28, 0b0010_1001_0111_1000), # MUL R9 R7 R8    : R9 <= R7 * R8
    (30, 0b0000_1010_1001_1010), # ADD R10 R9 R10  : R10 <= R9 + R10          
    (32, 0b0000_0101_0101_1100), # ADD R5 R5 R12   : R5 <= R5 + 1             : row_idx = row_idx + 1
    (34, 0b0000_0110_0110_0011), # ADD R6 R6 R3    : R6 <= R6 + 2             : col_idx = col_idx + 2
    (36, 0b0000_0100_0100_1100), # ADD R4 R4 R12   : R4 <= R4 + 1             : k = k+1
    (38, 0b0110_1011_0100_0011), # BNE R11 R4 R3   : if (k < N) redo loop
    # Exit Loop
    (40, 0b0000_0010_0010_1111), # ADD R2 R15      : base addr C = base addr C + thread_ID
    (42, 0b1010_0000_1010_0010), # SW R10 R2       : Store data at register R10 onto mem location R2 mem[R2] <= R10
    (44, 0b1100_0000_0000_0000)  # JR
  ]

  data = [
    (0, 1), (1, 2), (2, 3), (3, 4),
    (16, 5), (17, 6), (18, 7), (19, 8)
  ]
  # Setting up instr and data memory
  inst_memory = inst_mem.InstMemory(dut, 8, 16, "mem2fetch")
  data_memory = data_mem.DataMemory(dut, 8, 16, 4, "mem2")
  data_memory.load(data)
  inst_memory.load(instr)

  # Setting up clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Reset dut
  await cocotb.start(reset_dut(dut.reset, 1))
  await Timer(10, units = "ns")

  dut.kernel_start.value = 1
  cycles = 0
  while (cycles < 500 or not dut.kernel_complete.value == 1): 
    inst_memory.run_nostate()
    data_memory.run_nostate() 
  
    await RisingEdge(dut.clk)
    cycles = cycles + 1
  
  # Checking expected values: 

  expected_data = [19, 22, 43, 50]
  expected_idx = [32, 33, 34, 35]
  result_mem = data_memory.mem
  for i in range(4):
    assert expected_data[i] == result_mem[expected_idx[i]], f"Did not properly calculate values"

  # data_memory.log_data()
  data_memory.pretty_log()
