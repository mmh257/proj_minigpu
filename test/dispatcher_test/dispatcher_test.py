import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

# Simple Test Case to ensure that the dispatcher is properly setting out start/complete
# values

async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0

@cocotb.test()
async def simple_test(dut):
    '''
    Base Test Case -> simulate core completion/execution behavior
    '''

    # Setting Clock
    c = Clock(dut.clk, 1, "ns")
    await cocotb.start(c.start())

    # Resetting dut
    await cocotb.start(reset_dut(dut.reset, 1))

    cu_complete = [0,0,0,0]

    # Manually setting values
    dut.thread_count.value = 8
    dut._log.info(f"HERE{(dut.cu_complete.value)}")
    # dut.cu_complete.value = cu_complete
    dut.cu_complete.value = int(''.join(str(x) for x in cu_complete),2)

    await Timer (4, units="ns")

    cycles = 0
    while (cycles < 20): 
      dut.kernel_start.value = 1
      if (cycles == 4 and dut.cu_enable.value[3]):
        cu_complete[3] = 1
      if (cycles == 8 and dut.cu_enable.value[2]):
        cu_complete[2] = 1

      dut.cu_complete.value = int(''.join(str(x) for x in cu_complete),2)
      dut._log.info(f"dut enables {dut.cu_enable.value[3]} complete inputs {cu_complete}")
      await RisingEdge(dut.clk)
      
      cycles+=1

    assert dut.kernel_complete.value == 1,f"Broken Dispatcher"