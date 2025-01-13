import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import sys
import os 
sys.path.append(os.path.abspath('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors'))
import data_mem

# Reset function
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0

def check_all_0(arr):
  for x in arr:
    if x != 0:
      return False
  return True

@cocotb.test()
async def manual_test_read(dut):
  '''
    Simple test case to determine if the controller module can 
    properly arbitrate which unit to select for the data memory
  '''
  data = [
     (0, 1), (1, 2), (2, 3), (3, 4),
     (4, 5), (5, 6), (6, 7), (7, 8),
     (8, 9), (9, 10), (10, 11), (11, 12),
     (12, 13), (13, 14), (14, 15), (15, 16)
  ]

  # Setting Clock    
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Resetting dut
  await cocotb.start(reset_dut(dut.reset, 1))

  # Internal Controls we need to adjust
  read_req_addr_val=[0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  read_req_addr=[0,1,2,3,  4,5,6,7,  8,9,10,11,  12,13,14,15]
  read_resp_rdy= [0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  outputs=[0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  completed=[0,0,0,0]
  compute_state=[2,2,2,2] # WB = 6

  data_memory = data_mem.DataMemory(dut,8,16,4,name="mem2")
  data_memory.load(data)
  # Simulation of dut 
  await Timer(10, units ="ns")
  cycles = 0

  threads_completed = 0

  while (cycles < 50):
    data_memory.run_nostate()

    # dut._log.info(f"{dut.read_req_rdy.value}")
    # First need to set the appropriate req_val signals high
    for i in range (16):
       if (dut.read_req_rdy.value[15-i] and (not completed[(15-i)//4])):
          read_req_addr_val[15-i] = 1


    if ((not completed[3-int(dut.compute_unit.value)])):
      # If we are in progress for the current compute unit, set the response rdy 
      selected_unit = 3-int(dut.compute_unit.value)
      read_resp_rdy[selected_unit*4] = 1
      read_resp_rdy[selected_unit*4+1] = 1
      read_resp_rdy[selected_unit*4+2] = 1
      read_resp_rdy[selected_unit*4+3] = 1

    # dut._log.info(f"{read_resp_rdy}")

    for i in range(16):
      if (dut.read_resp_data_val.value[15-i]): 
        # If the response is valid, 
        outputs[15-i] = dut.read_resp_data.value[15-i]
        selected_unit = 3-int(dut.compute_unit.value)
        read_resp_rdy[15-i] = 0

    # dut._log.info(f"{dut.read_resp_data.value[12:16]}")
    
    selected_unit = 3-int(dut.compute_unit.value)
    if (not completed[selected_unit] and (check_all_0(read_resp_rdy[4*selected_unit:4*selected_unit+4]))):
      completed[selected_unit] = 1

    for i in range(4):
      if (completed[3-i]):
        compute_state[3-i] = 6
        read_req_addr_val[4*(3-i)] = 0
        read_req_addr_val[4*(3-i)+1] = 0
        read_req_addr_val[4*(3-i)+2] = 0
        read_req_addr_val[4*(3-i)+3] = 0
    
    # dut._log.info(f"{dut.read_req_rdy.value}")
    # dut._log.info(f"{completed}")

    dut.read_req_addr_val.value = read_req_addr_val
    dut.read_req_addr.value = read_req_addr
    dut.read_resp_rdy.value = read_resp_rdy
    dut.compute_state.value = compute_state

    await RisingEdge(dut.clk)
    cycles = cycles + 1

  dut._log.info(f"{outputs}")


@cocotb.test()
async def manual_test_write(dut):
  '''
    Simple test case to see if we can pass in write requests
  '''

  # Setting Clock    
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Resetting dut
  await cocotb.start(reset_dut(dut.reset, 1))

  # Internal Controls we need to adjust
  write_req_val=[0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  write_req_addr=[0,1,2,3,  4,5,6,7,  8,9,10,11,  12,13,14,15]
  write_req_data=[10,11,12,13,  14,15,16,17,  18,19,110,111,  112,113,114,115]
  # read_resp_rdy= [0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  outputs=[0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0]
  completed=[0,0,0,0]
  compute_state=[2,2,2,2] # WB = 6
  progress = [0,0,0,0]

  data_memory = data_mem.DataMemory(dut,8,16,4,name="mem2")
  # data_memory.load(data)
  # Simulation of dut 
  await Timer(10, units ="ns")
  cycles = 0

  while (cycles < 50): 
    data_memory.run_nostate()
    # First need to set the appropriate req_val signals high
    for i in range (16):
       if (dut.write_req_rdy.value[15-i] and (not completed[(15-i)//4])):
          write_req_val[15-i] = 1
    
    # dut._log.info(f"{dut.write_resp_val.value}")
    # dut._log.info(f"{dut.write_req_rdy.value}")
    # dut._log.info(f"{3-int(dut.compute_unit.value)}")
    # dut._log.info(f"{progress}")
    
    # Then when the response is valid for the threads corresponding to the unit
    # switch the request valid to low
    for i in range (16):
      if (dut.write_resp_val.value[15-i]):
        progress[selected_unit] = 1
        write_req_val[15-i] = 0

    selected_unit = 3-int(dut.compute_unit.value)
    if ((not completed[selected_unit]) and (check_all_0(write_req_val[4*selected_unit:4*selected_unit+4])) and (progress[selected_unit])):
      # Added additional logic here to ensure we don't prematurely mark a unit as completed
      completed[selected_unit] = 1
      progress[selected_unit] = 0

    # dut._log.info(f"{selected_unit}")

    for i in range(4):
      if (completed[3-i]):
        compute_state[3-i] = 6
        write_req_val[4*(3-i)] = 0
        write_req_val[4*(3-i)+1] = 0
        write_req_val[4*(3-i)+2] = 0
        write_req_val[4*(3-i)+3] = 0
    
    dut.write_req_val.value = write_req_val
    dut.write_req_data.value = write_req_data
    dut.write_req_addr.value = write_req_addr
    dut.compute_state.value = compute_state

    await RisingEdge(dut.clk)
    cycles = cycles + 1
  
  data_memory.log_data()

