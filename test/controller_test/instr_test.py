import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import sys
import os 
sys.path.append(os.path.abspath('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors'))
import inst_mem

# Reset function
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0

@cocotb.test()
async def manual_test(dut):
  '''
    Simple test case to determine if the controller module can 
    properly arbitrate which unit to select
  '''
  instructions = [
  (0,  0b1001_0000_0001_1111), # LW R1 R15
  (2,  0b1000_1010_0000_0100), # CONST R10 (4)
  (4,  0b0000_1001_1010_1111), # ADD R9 R10 R15
  (6,  0b1001_0000_0010_1001), # LW R2 R9
  (8,  0b0000_0011_0001_0010), # ADD R3 R1 R2
  (10, 0b0000_1000_1001_1010), # ADD R8 R9 R10
  (12, 0b1010_0000_0011_1000), # SW R3 R8
  (14, 0b1100_0000_0000_0000)  # JR - Signal End of Kernel
  ]

  # Setting Clock    
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Resetting dut
  await cocotb.start(reset_dut(dut.reset, 1))

  # Defining controls to manually adjust - simulating the units
  fetch_req_val = [0,0,0,0]
  fetch_req_addr = [2,4,6,8]
  fetch_resp_rdy = [0,0,0,0]
  completed = [0,0,0,0]
  output_inst = [0,0,0,0]
  compute_state = [1,1,1,1]

  # Initializing monitor for test
  inst_memory = inst_mem.InstMemory(dut, 8, 16, "mem2fetch")
  inst_memory.load(instructions)

  # Simulation of dut 
  await Timer(10, units ="ns")
  cycles = 0

  while (cycles < 100):
    inst_memory.run_nostate()

    for i in range(4):
      if (dut.fetch_req_rdy.value[3-i] and (not completed[3-i])):
        fetch_req_val[3-i] = 1
    
    if ((not completed[3-int(dut.compute_unit.value)])):
      fetch_resp_rdy[3-int(dut.compute_unit.value)] = 1

    # dut._log.info(f"{fetch_resp_rdy}")
    
    for i in range(4):
      if (dut.fetch_resp_val.value[3-i]):
        completed[3-i] = 1
        output_inst[3-i] = dut.fetch_resp_inst.value[3-i]
        fetch_resp_rdy[3-i] = 0

    for i in range(4):
      # Determine if the core has completed, then move it to decode & reset values
      if (completed[3-i]):
        compute_state[3-i] = 2
        fetch_req_val[3-i] = 0

    dut._log.info(f"{completed}")
    dut.fetch_req_val.value = fetch_req_val
    dut.fetch_req_addr.value = fetch_req_addr
    dut.fetch_resp_rdy.value = fetch_resp_rdy
    dut.compute_state.value = compute_state

    await RisingEdge(dut.clk)
    cycles = cycles + 1

  dut._log.info(f"{output_inst}")