# Simple Fetcher Test to see if it is capable of processing an instruction
import cocotb
from cocotb.triggers import Timer , RisingEdge
from cocotb.clock import Clock

import os
import sys
sys.path.append(os.path.abspath('/Users/mhui/Documents/proj_hdl/proj_minigpu/test/monitors'))
import inst_mem

# # Defining coroutine classes for handling memory requests
# class InstMemory:
#   '''
#     An Instruction Memory class interface capable of processing the 
#     rdy/val/msg system for handshaking. 
#     - Asynchronous memory handler, thus it does not need a clk
#     - Different I/O ports from the data memory handler

#     Based off the example Monitors from cocotb examples
#   '''
#   def __init__(self, dut, addr_bits, data_bits): 
#     self.dut = dut
#     self.addr_bits = addr_bits
#     self.data_bits = data_bits
#     self.mem = [0] * (2 ** addr_bits)
#     self.channels = 1 # 1 Channel because for one compute unit, only the fetcher interacts
#     self.chan_progress = [0] * 1 # Internal list to keep track of active memory channels

#     # Grabbing the "channels" of the dut that we communicate with 
#     self.fetch_req_rdy = getattr(dut, "fetch_req_rdy")
#     self.fetch_req_val = getattr(dut, "fetch_req_val")
#     self.fetch_req_addr = getattr(dut, "fetch_req_addr")
#     self.fetch_resp_rdy = getattr(dut, "fetch_resp_rdy")
#     self.fetch_resp_val = getattr(dut, "fetch_resp_val")
#     self.fetch_resp_inst = getattr(dut, "fetch_resp_inst")
#     self.fetch_state = getattr(dut, "fetch_state")

#   # def run(self):
#   #   # First updating the fetch_req_val and the fetch_resp_val values
#   #   # These are handled from the POV of the memory (THIS)
#   #   # Thus we must generate these values when necessary
#   #   fetch_req_rdy = [0] * self.channels
#   #   fetch_resp_val = [0] * self.channels
#   #   fetch_resp_inst = [0] * self.channels

#   #   # These are handled from the POV of the dut
#   #   # Thus, we simply need to grab these values every cycle of "run" to 
#   #   # properly update the output values above
#   #   fetch_req_val = []
#   #   fetch_req_addr = []
#   #   fetch_resp_rdy = []

#   #   for i in range (0, len(self.fetch_req_val)):
#   #     # self.dut._log.info(str(self.fetch_req_val))
#   #     # self.dut._log.info("TESTING")
#   #     fetch_req_val.append(self.fetch_req_val.value)
    
#   #   for i in range (0, len(self.fetch_req_addr), self.addr_bits):
#   #     # self.dut._log.info(str(len(self.fetch_req_addr)))
#   #     # self.dut._log.info("TESTING ADDR")
#   #     fetch_req_addr.append(self.fetch_req_addr.value[i:i+self.addr_bits-1])
    
#   #   for i in range (0, len(self.fetch_resp_rdy)): 
#   #     fetch_resp_rdy.append(self.fetch_resp_rdy.value)
  
#   #   # Determining our output data
#   #   for i in range(self.channels):
#   #     # If we are not currently processing anything, we are ready for the next memory request
#   #     if (self.chan_progress[i] == 0):
#   #       fetch_req_rdy[i] = 1
#   #     if (self.chan_progress[i] and fetch_resp_rdy[i]):
#   #       fetch_resp_val[i] = 1
#   #       fetch_resp_inst[i] = self.mem[fetch_req_addr[i]] # Temporary check
#   #       self.chan_progress[i] = 0

#   #   # Make sure we update our rdy/val interface values accordingly 
#   #   for i in range(self.channels):
#   #     # If we have a valid request, need to toggle the rdy signal
#   #     if (fetch_req_val[i]): 
#   #       self.chan_progress[i] = 1
#   #       fetch_req_rdy[i] = 0

#   #   # Assigning the output values
#   #   self.fetch_req_rdy.value = fetch_req_rdy[0]
#   #   self.fetch_resp_val.value = fetch_resp_val[0]
#   #   self.fetch_resp_inst.value = fetch_resp_inst[0]

#   def run_2(self):
#     # First defining data that the memory (this class) handles
#     fetch_req_rdy = [0] * self.channels
#     fetch_resp_val = [0] * self.channels
#     fetch_resp_inst = [0] * self.channels

#     # Data that we will read from the fetcher.v module (OUTPUT)
#     fetch_req_val = []
#     fetch_req_addr = []
#     fetch_resp_rdy = []

#     # Using fetch_state to help us progress
#     fetch_state = []

#     # Grabbing the output data for each of the output ports
#     for i in range (0, len(self.fetch_req_val)):
#       fetch_req_val.append(self.fetch_req_val.value)
#     for i in range (0, len(self.fetch_resp_rdy)):
#       fetch_resp_rdy.append(self.fetch_resp_rdy.value)
#     for i in range (0, len(self.fetch_req_addr), self.addr_bits):
#       # This needs to iterate over every "8" bits because we iterate 1 bit per time
#       fetch_req_addr.append(self.fetch_req_addr.value[i:i+7])
#     for i in range (0, len(self.fetch_state), 2): 
#       fetch_state.append(self.fetch_state.value[i:i+1])

#     # Updating our output values
#     # First updating our fetch_req_rdy signal if nothing is processing
#     self.dut._log.info(f"fetch_state = {fetch_state[0]}")
#     if fetch_state[0] == 0:
#       fetch_req_rdy[0] = 1
#     # Then, if we receive a valid request, we need to set the memory response
#     if fetch_state[0] == 2 and fetch_resp_rdy[0]:
#       fetch_resp_val[0] = 1
#       fetch_resp_inst[0] = self.mem[fetch_req_addr[0]]
#     # Then in this state we need to reset all of our values back to 0 
#     if fetch_state[0] == 3:
#       fetch_req_rdy = [0] * self.channels
#       fetch_resp_val = [0] * self.channels
#       fetch_resp_inst = [0] * self.channels

#     # Updating output values
#     self.fetch_req_rdy.value = fetch_req_rdy[0]
#     self.fetch_resp_val.value = fetch_resp_val[0]
#     self.fetch_resp_inst.value = fetch_resp_inst[0]
  
#   def write(self, addr, data):
#     self.mem[addr] = data

#   def load(self, loaded_data):
#     for (key,val) in loaded_data:
#       self.write(key, val)

#   def read(self, addr):
#     return self.mem[addr]
  
#   def log_data(self):
#     addr = 0
#     for data in self.mem:
#       self.dut._log.info(f"{addr} : {data}")
#       addr = addr + 1
  
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0

# Defining simple progression test case to test if the memory can interface with our dut
@cocotb.test()
async def simple_progression(dut):

  # Defining our program data
  instr_data = [(1, 0b1111_1111_1111_1111), (3, 0b0000_1010_1011_0111)]

  # Clock Setup
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Setting up our data
  instr_mem = inst_mem.InstMemory(dut, 8, 16)
  instr_mem.load(instr_data)

  # instr_mem.log_data()

  # Reset DUT
  await cocotb.start(reset_dut(dut.reset, 1))

  # Timer to wait until everything loads before running 
  await Timer(10, units="ns")
  cycles = 0
  curr_pc = 0
  
  cu_state = 1
  while cycles < 15:
    instr_mem.run_nostate()

    # Assigning values on our fetcher to make sure that it can enter loops
    # dut.curr_pc.value = curr_pc
    # dut.cu_state.value = cu_state

    await RisingEdge(dut.clk)

    if (dut.fetch_state == 2):
      # cu_state = 2
      dut.cu_state.value = 2

    if (dut.fetch_state == 0):
      dut.curr_pc.value = curr_pc
      dut.cu_state.value = 1
      # cu_state = 1
      curr_pc = curr_pc + 1
    cycles += 1







      

