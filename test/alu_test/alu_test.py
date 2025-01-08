import cocotb 
from cocotb.triggers import Timer 
from cocotb.clock import Clock
from random import randint

# Helper function to convert binary number
def signed_binary_to_int(binary_string):
    # Get the number of bits
    num_bits = len(binary_string)
    
    # Convert binary to integer
    value = int(binary_string, 2)
    
    # Check if the number is negative (MSB is 1)
    if binary_string[1] == '1':
        # Apply two's complement adjustment for negative numbers
        value -= (1 << num_bits)
    
    return value

@cocotb.test()
async def add_test_simple(dut):
  # Simple add tests
  a = [0, 1, 2, 3, -5, -10] 
  b = [10, -1, 3, 5, -8, 20]
  expected = [(a[i] + b[i]) for i in range(len(a))]

  # Establishing our clock?
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())
  
  for i in range(6): 
    dut.a.value = a[i]
    dut.b.value = b[i]
    dut.alu_func.value = 0
    dut.alu_en.value = 1

    await Timer(10, units="ns")
    converted = signed_binary_to_int(str(dut.out.value))
    assert converted == expected[i], f"Addition Result is incorrect for a = {a[i]} b = {b[i]} out = {dut.out.value}"

@cocotb.test()
async def add_test_rand(dut):
  num_tests = 10
  a = []
  b = []
  expected = []
  for i in range (num_tests):
    a_val = randint(-1*(2**4),2**4-1)
    b_val = randint(-1*(2**4),2**4-1)
    e_val = (a_val + b_val) # Temporarily removed the & mask here 
    a.append(a_val)
    b.append(b_val)
    expected.append(e_val)
  
  # Establishing our clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())
  
  for i in range(num_tests): 
    dut.a.value = a[i]
    dut.b.value = b[i]
    dut.alu_func.value = 0
    dut.alu_en.value = 1

    await Timer(4, units="ns")
    converted = signed_binary_to_int(str(dut.out.value))
    assert converted == expected[i], f"Addition Result is incorrect for a = {a[i]} b = {b[i]} out = {dut.out.value}"

@cocotb.test()
async def mult_test_simple(dut):
  # Simple multiply test
  a = [0, 1, 2, 3, -5, -10] 
  b = [10, -1, 3, 5, -8, 20]
  expected = [(a[i] * b[i]) for i in range(len(a))]

  # Establishing our clock?
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())
  
  for i in range(6): 
    dut.a.value = a[i]
    dut.b.value = b[i]
    dut.alu_func.value = 2
    dut.alu_en.value = 1

    await Timer(10, units="ns")
    converted = signed_binary_to_int(str(dut.out.value))
    assert converted == expected[i], f"Mutliplication Result is incorrect for a = {a[i]} b = {b[i]} out = {dut.out.value}"

@cocotb.test()
async def mult_test_rand(dut):
  # Randomized multiply test
  num_tests = 100
  a = []
  b = []
  expected = []
  for i in range (num_tests):
    a_val = randint(-1*(2**4),2**4-1)
    b_val = randint(-1*(2**4),2**4-1)
    e_val = (a_val * b_val)
    a.append(a_val)
    b.append(b_val)
    expected.append(e_val)
  
  # Establishing our clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())
  
  for i in range(num_tests): 
    dut.a.value = a[i]
    dut.b.value = b[i]
    dut.alu_func.value = 2
    dut.alu_en.value = 1

    await Timer(4, units="ns")
    converted = signed_binary_to_int(str(dut.out.value))
    assert converted == expected[i], f"Mult Result is incorrect for a = {a[i]} b = {b[i]} out = {dut.out.value}"
    
