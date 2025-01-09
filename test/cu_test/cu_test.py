# Simple Compute Unit Test to see if it is capable of processing an instruction
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

# Starting our Test
@cocotb.test()
async def simple_compute_unit_test(dut):
  '''
    This test will perform a series of basic operations on a singular compute unit
    with 4 active threads. Instruction Memory and Data Memory will be initialized 
    beforehand following our custom 12 inst ISA.
    The end result will be a simple vector add, two vectors of size 4.

    DATA Memory: 
    1 2 3 4 4 3 2 1

    INSTR Memory: 
    LW R1 ThreadIdx : R1 = Mem[threadIdx] : Load data from Register 15 onto Register 1                          : 
    CONST R10 4     : R10 = 4             : Load the constant value of 4 onto R10
    ADD R9 R1 R10   : R9 = threadIdx + 4  : Add the ThreadIdx + 4 and store it onto R9 
    LW R2 R9        : R2 = Mem[id+4]      : Load the value from data @ R9 onto R2
    ADD R3 R1 R2    : R3 = R1 + R2        : Sum the value on R1 and R2
    ADD R8 R9 R10   : R8 = threadIdx + 8  : Increment threadIdx by 4 again to get the next data memory location
    SW R3 R8        : Mem[R8] = R3        : Store the Result
  '''
  instructions = [
    (0,  0b1001_0000_0001_1111), # LW R1 R15
    (2,  0b1000_1010_0000_0100), # CONST R10 (4)
    (4,  0b0000_1001_0001_1010), # ADD R9 R1 R10
    (6,  0b1001_0000_0010_1001), # LW R2 R9
    (8,  0b0000_0011_0001_0010), # ADD R3 R1 R2
    (10, 0b0000_1000_1001_1010), # ADD R8 R9 R10
    (12, 0b1010_0000_0011_1000), # SW R3 R8
    (14, 0b1100_0000_0000_0000)  # JR - Signal End of Kernel
  ]
  data = [
     (0, 1), (1, 2), (2, 3), (3, 4),
     (4, 4), (5, 3), (6, 2), (7, 2)
  ]

  # Setting up instr and data memory
  inst_memory = inst_mem.InstMemory(dut, 8, 16, "")
  data_memory = data_mem.DataMemory(dut, 8, 16, 4)
  data_memory.load(data)
  inst_memory.load(instructions)

  # Setting up clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Reset dut
  await cocotb.start(reset_dut(dut.reset, 1))

  await Timer(10, units = "ns")
  dut.cu_enable.value = 1
  dut.active_threads.value = 4;

  # Progression
  cycles = 0 
  while (not dut.cu_complete.value):
    inst_memory.run()
    data_memory.run() 
    
    await RisingEdge(dut.clk)

    # Logic to progress & handle our input data


    cycles = cycles + 1