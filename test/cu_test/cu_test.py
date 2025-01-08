# Simple Compute Unit Test to see if it is capable of processing an instruction
import cocotb
from cocotb.triggers import Timer 
from cocotb.clock import Clock
from random import randint

# Defining coroutine classes for handling memory requests
class InstMemory:
  '''
    An Instruction Memory class interface capable of processing the 
    rdy/val/msg system for handshaking. 
    - Asynchronous memory handler, thus it does not need a clk
    - Different I/O ports from the data memory handler

    Based off the example Monitors from cocotb examples
  '''
  def __init__(self, dut, addr_bits, data_bits): 
    self.dut = dut
    self.addr_bits = addr_bits
    self.data_bits = data_bits
    self.mem = [0] * (2 ** addr_bits)
    self.channels = 1 # 1 Channel because for one compute unit, only the fetcher interacts
    self.chan_progress = [0] * 1 # Internal list to keep track of active memory channels

    # Grabbing the "channels" of the dut that we communicate with 
    self.fetch_req_rdy = getattr(dut, "fetch_req_rdy")
    self.fetch_req_val = getattr(dut, "fetch_req_val")
    self.fetch_req_addr = getattr(dut, "fetch_req_addr")
    self.fetch_resp_rdy = getattr(dut, "fetch_resp_rdy")
    self.fetch_resp_val = getattr(dut, "fetch_resp_val")
    self.fetch_resp_inst = getattr(dut, "fetch_resp_inst")

  def run(self):
    # First updating the fetch_req_val and the fetch_resp_val values
    # These are handled from the POV of the memory
    # Thus we must generate these values when necessary
    fetch_req_rdy = [0] * self.channels
    fetch_resp_val = [0] * self.channels
    fetch_resp_inst = [0] * self.channels

    # These are handled from the POV of the dut
    # Thus, we simply need to grab these values every cycle of "run" to 
    # properly update the output values above
    fetch_req_val = []
    fetch_req_addr = []
    fetch_resp_rdy = []
    for i in range (0, len(str(self.fetch_req_val.value))):
      fetch_req_val.append(int(str(self.fetch_req_val.value[i])))
    

    for i in range(self.channels):
      # If we are not currently processing anything, we are ready for the next memory request
      if (self.chan_progress[i] == 0):
        self.fetch_req_rdy[i] = 1
      

