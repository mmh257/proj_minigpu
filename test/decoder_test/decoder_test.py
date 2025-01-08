import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

# Reset coroutine
async def reset_dut(reset_n, duration_ns):
    reset_n.value = 0
    await Timer(duration_ns, units="ns")
    reset_n.value = 1
    await Timer(duration_ns, units="ns")
    reset_n.value = 0
    reset_n._log.debug("Reset complete")

@cocotb.test()
async def manual_instr_test(dut):
  # Manual Instruction test to check whether or not we are properly decoding
  # Test Set of instructions:
  # ADD: 0000_0001_1000_0100 == ADD RD[1] RS1[8] RS2[4]
  # SUB: 0001_0010_0101_0111 == SUB RD[2] RS1[5] RS2[7]
  # BEQ: 0101_1010_0000_0001 == BEQ RIMM[10] RS1[0] RS2[1]
  # CONST: 1000_0110_1010_1010 == CONST RD[6] IMM[170]
  # LW: 1001_XXXX_0011_0101 == LW RS1[3] RS2[5]
  # SW: 1010_XXXX_0100_1111 == SW RS1[4] RS2[15]
  # NOP: 1011_XXXX_XXXX_XXXX
  # JR: 1100_XXXX_XXXX_XXXX
  opcode = [0, 1, 5, 8, 9, 10, 11, 12]
  rd = [1, 2, 0, 6, 0, 0, 0, 0] # 0's indicate that its not in use
  rs1 = [8, 5, 0, 0, 3, 4, 0, 0]
  rs2 = [4, 7, 1, 0, 5, 15, 0, 0]
  rimm = [0, 0, 10, 0, 0, 0, 0, 0]
  imm = [0, 0, 0, 170, 0, 0, 0, 0]
  alu_func = [0, 1, 8, 0, 0, 0, 0, 0]
  
  # Instruction list
  instr = [ 0b0000_0001_1000_0100, 0b0001_0010_0101_0111,
            0b0101_1010_0000_0001, 0b1000_0110_1010_1010,
            0b1001_0000_0011_0101, 0b1010_0000_0100_1111,
            0b1011_0000_0000_0000, 0b1100_0000_0000_0000
  ]

  # Our pointer to the reset port
  reset_n = dut.reset

  # Starting the clock
  c = Clock(dut.clk, 1, "ns")
  await cocotb.start(c.start())

  # Checking each test case
  for i in range(8):
    await reset_dut(reset_n,10)
    dut.cu_state.value = 2; # Decode = 4'd2
    dut.instr.value=instr[i]

    await Timer(10,units="ns")
    if (dut.is_load.value or dut.is_store.value):
       assert dut.rs1.value == rs1[i],f"rs1 Reg is wrong{dut.rs1.value} != {rs1[i]}"
       assert dut.rs2.value == rs2[i],f"rs2 Reg is wrong{dut.rs2.value} != {rs2[i]}"
    elif (dut.is_const.value): 
       assert dut.rd.value == rd[i],f"Dest Reg is wrong {dut.rd.value} != {rd[i]}"
       assert dut.imm.value == imm[i],f"Immediate Val is wrong {dut.imm.value} != {imm[i]}"
    elif (dut.is_branch.value):
       assert dut.rimm.value == rimm[i],f"Rimm Val is wrong {dut.rimm.value} != {rimm[i]}"
       assert dut.rs1.value == rs1[i],f"rs1 Reg is wrong{dut.rs1.value} != {rs1[i]}"
       assert dut.rs2.value == rs2[i],f"rs2 Reg is wrong{dut.rs2.value} != {rs2[i]}"
    elif (dut.is_alu.value):
      assert dut.rd.value == rd[i],f"Dest Reg is wrong {dut.rd.value} != {rd[i]}"
      assert dut.rs1.value == rs1[i],f"rs1 Reg is wrong{dut.rs1.value} != {rs1[i]}"
      assert dut.rs2.value == rs2[i],f"rs2 Reg is wrong{dut.rs2.value} != {rs2[i]}"
      
    
    
    

