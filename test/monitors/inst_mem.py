import cocotb
from cocotb.triggers import Timer , RisingEdge
from cocotb.clock import Clock

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
    self.progress = [0] * 1 # Internal list to keep track of active memory channels

    # Grabbing the "channels" of the dut that we communicate with 
    self.fetch_req_rdy = getattr(dut, "fetch_req_rdy")
    self.fetch_req_val = getattr(dut, "fetch_req_val")
    self.fetch_req_addr = getattr(dut, "fetch_req_addr")
    self.fetch_resp_rdy = getattr(dut, "fetch_resp_rdy")
    self.fetch_resp_val = getattr(dut, "fetch_resp_val")
    self.fetch_resp_inst = getattr(dut, "fetch_resp_inst")
    self.cu_state = getattr(dut, "compute_state")
    # self.fetch_state = getattr(dut, "fetch_state")
  
  def run(self):
    # First defining data that the memory (this class) handles
    fetch_req_rdy = [0] * self.channels
    fetch_resp_val = [0] * self.channels
    fetch_resp_inst = [0] * self.channels

    # Data that we will read from the fetcher.v module (OUTPUT)
    fetch_req_val = []
    fetch_req_addr = []
    fetch_resp_rdy = []

    # Using fetch_state to help us progress
    fetch_state = []

    # Grabbing the output data for each of the output ports
    for i in range (0, len(self.fetch_req_val)):
      fetch_req_val.append(self.fetch_req_val.value)
    for i in range (0, len(self.fetch_resp_rdy)):
      fetch_resp_rdy.append(self.fetch_resp_rdy.value)
    for i in range (0, len(self.fetch_req_addr), self.addr_bits):
      # This needs to iterate over every "8" bits because we iterate 1 bit per time
      fetch_req_addr.append(self.fetch_req_addr.value[i:i+7])
    for i in range (0, len(self.fetch_state), 2): 
      fetch_state.append(self.fetch_state.value[i:i+1])

    # Updating our output values
    # First updating our fetch_req_rdy signal if nothing is processing
    self.dut._log.info(f"fetch_state = {fetch_state[0]}")
    if fetch_state[0] == 0:
      fetch_req_rdy[0] = 1
    # Then, if we receive a valid request, we need to set the memory response
    if fetch_state[0] == 2 and fetch_resp_rdy[0]:
      fetch_resp_val[0] = 1
      fetch_resp_inst[0] = self.mem[fetch_req_addr[0]]
    # Then in this state we need to reset all of our values back to 0 
    if fetch_state[0] == 3:
      fetch_req_rdy = [0] * self.channels
      fetch_resp_val = [0] * self.channels
      fetch_resp_inst = [0] * self.channels

    # Updating output values
    self.fetch_req_rdy.value = fetch_req_rdy[0]
    self.fetch_resp_val.value = fetch_resp_val[0]
    self.fetch_resp_inst.value = fetch_resp_inst[0]

  def run_nostate(self):
    if (int(self.cu_state.value) == 1):
      # First defining data that the memory (this class) handles
      fetch_req_rdy = [0] * self.channels
      fetch_resp_val = [0] * self.channels
      fetch_resp_inst = [0] * self.channels

      # Data that we will read from the fetcher.v module (OUTPUT)
      fetch_req_val = []
      fetch_req_addr = []
      fetch_resp_rdy = []

      # Using fetch_state to help us progress
      # fetch_state = []

      # Grabbing the output data for each of the output ports
      for i in range (0, len(self.fetch_req_val)):
        fetch_req_val.append(self.fetch_req_val.value)
      for i in range (0, len(self.fetch_resp_rdy)):
        fetch_resp_rdy.append(self.fetch_resp_rdy.value)
      for i in range (0, len(self.fetch_req_addr), self.addr_bits):
        # This needs to iterate over every "8" bits because we iterate 1 bit per time
        fetch_req_addr.append(self.fetch_req_addr.value[i:i+7])

      # Logic to set the rdy/val handshaking signals
      if self.progress[0] == 0: 
        # Waiting to accept a new fetch request
        fetch_req_rdy[0] = 1
      if fetch_req_val[0] == 1: 
        # If we receive a valid fetch request, put our tracker in progress mode
        self.progress[0] = 1
      if self.progress[0] == 1 and fetch_resp_rdy[0]:
        # If we are in progress & the module is ready to accept a response
        fetch_resp_val[0] = 1 
        fetch_resp_inst[0] = self.mem[int(fetch_req_addr[0])]
        fetch_req_rdy[0] = 0
        self.progress[0] = 0
      
      # Updating output values
      self.fetch_req_rdy.value = fetch_req_rdy[0]
      self.fetch_resp_val.value = fetch_resp_val[0]
      self.fetch_resp_inst.value = fetch_resp_inst[0]
    
  def write(self, addr, data):
    self.mem[addr] = data

  def load(self, loaded_data):
    for (key,val) in loaded_data:
      self.write(key, val)

  def read(self, addr):
    return self.mem[addr]
  
  def log_data(self):
    addr = 0
    for data in self.mem:
      self.dut._log.info(f"{addr} : {data}")
      addr = addr + 1
