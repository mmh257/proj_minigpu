import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

# Data Memory Monitor Controller
# Used to take care of Load/Store requests
class DataMemory:
  '''
  A Data Memory Monitor to handle the ready/valid signal handshaking interface
  for load/store requests from the LSU. 
  The default design for this module will be looking at it from a compute unit's
  perspective where there are 4 active LSU modules interfacing with one shared memory
  '''

  def __init__(self, dut, addr_bits, data_bits, num_chan):
    self.dut = dut
    self.addr_bits = addr_bits
    self.data_bits = data_bits
    self.mem = [0] * (2**addr_bits)
    self.channels = num_chan

    # Interfacing ports of the memory
    # LSU Read Request
    self.read_req_rdy = getattr(dut, "read_req_rdy")
    self.read_req_addr = getattr(dut, "read_req_addr")
    self.read_req_addr_val = getattr(dut, "read_req_addr_val")
    # LSU Read Response
    self.read_resp_rdy = getattr(dut,"read_resp_rdy")
    self.read_resp_data = getattr(dut, "read_resp_data")
    self.read_resp_data_val = getattr(dut, "read_resp_data_val")
    # LSU Write Request
    self.write_req_rdy = getattr(dut,"write_req_rdy")
    self.write_req_addr = getattr(dut, "write_req_addr")
    self.write_req_data = getattr(dut,"write_req_data")
    self.write_req_val = getattr(dut,"write_req_val")
    # LSU Write Response
    self.write_resp_val = getattr(dut,"write_resp_val")
    # Compute Unit State
    self.cu_state = getattr(dut, "compute_state")
    # self.lsu_state = getattr(dut, "lsu_state")

    # Internal progression states
    self.progress = [0] * num_chan
  
  def run(self):
    '''
      This function handles asynchronously and generates the input values 
      for the handshaking memory interface
    '''
    # Initializing lists to contain "output" data from the LSU's
    read_req_addr = []
    read_req_addr_val = []
    read_resp_rdy = []
    write_req_addr = []
    write_req_data = []
    write_req_val = []
  
    # Initializing lists to contain inputs to the LSU that we will generate
    read_req_rdy = [0] * self.channels
    read_resp_data = [0] * self.channels
    read_resp_data_val = [0] * self.channels
    write_req_rdy = [0] * self.channels
    write_resp_val = [0] * self.channels

    # Grabbing output values
    for i in range(0, len(self.read_req_addr), self.addr_bits):
      read_req_addr.append(self.read_req_addr.value[i:i+self.addr_bits-1])
    for i in range(0, len(self.read_req_addr_val)):
      read_req_addr_val.append(self.read_req_addr_val.value)  
    for i in range(0, len(self.read_resp_rdy)):
      read_resp_rdy.append(self.read_resp_rdy.value)  
    for i in range(0, len(self.write_req_addr), self.addr_bits):
      write_req_addr.append(self.write_req_addr.value[i:i+self.addr_bits-1])  
    for i in range(0, len(self.write_req_data), self.data_bits):
      write_req_data.append(self.write_req_data.value[i:i+self.data_bits-1])  
    for i in range(0, len(self.write_req_val)):
      write_req_val.append(self.write_req_val.value)  
    # compute_state = self.cu_state.value
    
    for n in range(self.channels):
      if self.lsu_state.value == 0: 
        # If we are in LSU IDLE state
        read_req_rdy[n] = 1
        write_req_rdy[n] = 1
      if read_resp_rdy[n] == 1: 
        # LSU is ready to handle a read response
        read_resp_data[n] = self.mem[read_req_addr[n]]
        read_resp_data_val[n] = 1
      if write_req_val[n] == 1: 
        # If we have a valid write/store request
        self.mem[int(write_req_addr[n])] = int(write_req_data[n])
        write_resp_val[n] = 1
      if self.lsu_state.value == 3: 
        # If it is done reset all values
        read_req_rdy = [0] * self.channels
        read_resp_data = [0] * self.channels
        read_resp_data_val = [0] * self.channels
        write_req_rdy = [0] * self.channels
        write_resp_val = [0] * self.channels

    # self.dut._log.info(str(len(self.read_req_rdy.value[0])))
    # Updating the values, will have to iterate through the channels
    for n in range (self.channels):
      self.read_req_rdy.value = read_req_rdy[n]
      self.read_resp_data_val.value = read_resp_data_val[n]
      self.write_req_rdy.value = write_req_rdy[n]
      self.write_resp_val.value = write_resp_val[n]
      index = n * self.data_bits
      # self.read_resp_data.value[index:index+self.data_bits-1] = read_resp_data[n]
      self.read_resp_data.value = read_resp_data[n]
      # self.dut._log.info(str(self.read_req_rdy.value[n]))

  # A secondary version of the run function without using the lsu state
  def run_nostate(self):
    '''
      This function handles asynchronously and generates the input values 
      for the handshaking memory interface
      ** Does not use the lsu_state flag to generate values
    '''
    # Only run our module if we are actually doing a data request
    if int(self.cu_state.value) >= 4 and int(self.cu_state.value) <= 6: 
      # Initializing lists to contain "output" data from the LSU's
      read_req_addr = []
      read_req_addr_val = []
      read_resp_rdy = []
      write_req_addr = []
      write_req_data = []
      write_req_val = []
    
      # Initializing lists to contain inputs to the LSU that we will generate
      read_req_rdy = [0] * self.channels
      read_resp_data = [0] * self.channels
      read_resp_data_val = [0] * self.channels
      write_req_rdy = [0] * self.channels
      write_resp_val = [0] * self.channels

      # Grabbing output values 
      read_req_addr = self.read_req_addr.value
      read_req_addr_val = self.read_req_addr_val.value
      read_resp_rdy = self.read_resp_rdy.value
      write_req_addr = self.write_req_addr.value
      write_req_data = self.write_req_data.value
      write_req_val = self.write_req_val.value
      # self.dut._log.info(f"{read_req_addr}")

      # Setting output values
      for n in range(self.channels):
        if (self.progress[n] == 0):
          # Current Channel isn't doing anything
          read_req_rdy[n] = 1
          write_req_rdy[n] = 1
        if read_req_addr_val[n] or write_req_val[n]: 
          # Have a valid write or read request
          self.progress[n] = 1
        if self.progress[n] and read_resp_rdy[n]: 
          self.dut._log.info(f"HERE{(read_resp_rdy)}")
          # Ready to send a read response
          read_resp_data[n] = self.mem[int(read_req_addr[n])]
          read_resp_data_val[n] = 1
          self.progress[n] = 0
        if self.progress[n] and write_req_val[n]: 
          # Redundant to above condition, but ready to write val
          self.mem[int(write_req_addr[n])] = int(write_req_data[n])
          write_resp_val[n] = 1
          self.progress[n] = 0

      # self.dut._log.info(f"{read_req_rdy}")
        
      # Generating output values
      read_req_rdy_str = ""
      read_resp_data_val_str = ""
      write_req_rdy_str = ""
      write_resp_val_str = ""
      read_resp_data_str = ""
      for n in range (self.channels): 
        read_req_rdy_str += str(read_req_rdy[n]) # Only 1s or 0s
        read_resp_data_val_str += str(read_resp_data_val[n])
        write_req_rdy_str += str(write_req_rdy[n])
        write_resp_val_str += str(write_resp_val[n])
        read_resp_data_str += str(format(read_resp_data[n], "016b"))
    
      # self.dut._log.info(f"{read_req_rdy_str}")

      self.read_req_rdy.value = read_req_rdy
      self.write_req_rdy.value = write_req_rdy
      self.write_resp_val.value = write_resp_val
      self.read_resp_data_val.value = read_resp_data_val
      self.read_resp_data.value = read_resp_data


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

      