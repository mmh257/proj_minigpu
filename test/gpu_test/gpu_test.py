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
    
    data_memory.log_data()
