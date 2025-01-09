# from monitors.data_mem import DataMemory
# import sys
# sys.path.append('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors')
# from data_mem import DataMemory
# from ..monitors.data_mem import DataMemory
import sys
import os 
sys.path.append(os.path.abspath('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors'))
import data_mem
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

# Reset Signal
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0 

# Sample Test module to confirm that we are able to process data memory
# requests with our LSU
@cocotb.test()
async def simple_progression(dut):
  # Starting with setting up the data
  data = [(0, 0b1111_0000_1111_0000), (1, 0b0000_1111_0000_1111),
          (2, 0b1010_1010_1010_1010), (3, 0b0101_0101_0101_0101),
          (4, 0b1100_1100_1100_1100), (5, 0b0011_0011_0011_0011),
          (6, 0b0110_0110_0110_0110), (7, 0b1001_1001_1001_1001)]
  
  # Order of our operations: LW, LW, SW, SW, LW
  # Pairs of (r1, r2)
  # Load data @ R2 = 0, expect: F0F0
  # Load data @ R2 = 5, expect 3333
  # Store @ addr 8, 0000_1111_1111_0000: 0FF0
  # Store @ addr 10, 1111_0000_0000_1111: F00F
  # Load the data on R2, addr = 10, expect F00F
  # instr_type: 0 = LW, 1 = SW
  instr_type = [0, -10, 0, -10, 1, -10, 1, -10, 0]
  instr = [(0, 0), (100,100), (1, 5), (100,100), (0b0000_1111_1111_0000, 8), (100,100), 
           (0b1111_0000_0000_1111,10), (100,100), (2, 10)]

  # Setting up data 
  data_memory = data_mem.DataMemory(dut, 8, 16, 1)
  data_memory.load(data)

  # data_memory.log_data()
  
  # setting up clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Reset the DUT
  await cocotb.start(reset_dut(dut.reset, 1))

  # Progression
  cycles = 0 
  index = 0
  dut.lsu_en.value = 1

  await Timer(10, units = "ns")

  while (cycles < 50 and index < 9):

    # Run the test
    data_memory.run_nostate()

    await RisingEdge(dut.clk)
    # dut._log.info(str(index))

    # Logic to change input states
    if (dut.lsu_state.value == 0):
      # set our cu_state = request, 3
      dut.cu_state.value = 3
      # Set the mem_ren, mem_wen, rs1 and rs2 data
      dut.mem_ren.value = not instr_type[index]
      dut.mem_wen.value = instr_type[index]
      dut.rs1.value = instr[index][0]
      dut.rs2.value = instr[index][1]
    if (dut.lsu_state.value == 3): 
       # Set the cu_state to writeback to set it back to 0
      dut.cu_state.value = 6
      # dut.mem_ren.value = 0
      # dut.mem_wen.value = 0
      index = index + 1

    # Progress by 1
    cycles = cycles+1 

  # Print memory after to check 
  data_memory.log_data()


    