# MINIGPU Project Overview
MINIGPU is an exploration of the basic underlying architecture in a GPU and is a simple hardware RTL implementation of a singular Streaming Multiprocessor Unit. 

Much of the architecture within this project is based off the MIAOW GPU whitepaper which is an open source hardware implementation of a GPU along with Adam Maj's implementation of tiny-gpu. 

Reference Links & Sources:

- https://github.com/adam-maj/tiny-gpu/tree/master?tab=readme-ov-file
- https://miaowgpu.org/

**Table Of Contents**
- [Introduction](#introduction)


## Introduction

Much of the actual architecture wtihin modern GPUs remain largely restricted to the public, however the foundational architecture utilized in this project is roughly similar. In CPU land, the multistage pipelined processor is often taught and built off as the baseline model for understanding CPUs and basic computer architectural principles, however when searching for similar models with respect to GPUs, resources and models like that were hard to come across which inspired me to explore and create a simple model to better understand how GPUs work. 

For the MINIGPU's implementation, a very small custom ISA was created to provide sufficient instruction breadth to accomodate two desired functionalities of this minigpu: Vector-Vector Addition and Matrix-Matrix Multiplication. More details on the ISA are described in later sections. 

A bottom up approach to create MINIGPU was taken, first starting off with smaller submodule blocks interleaved with various cases of unit testing and working my way up towards top level integration and coroutine simulation testing. For this project, ``` icarus verilog ``` and ``` cocotb ``` were used as the main verilog compiler and coroutine simulations. For file development, the standard 2005 verilog was followed. This project is my first time working with these two frameworks which may explain some rudimentary design choices made in earlier files. For debugging, ```gtkwave``` was used to expand and dump vcd files to view specific wires and registers. 

## File Organization 

This directory is organized into several subdirectories for ease of organization. Irrelavant files are removed from the diagram below. The choice of having /wrapper and creating wrapper files is to simply abstract debugging wires from the actual verilog files corresponding to module implementations.

```
src
   |-- alu
   |   |-- alu.v
   |-- controllers
   |   |-- data_control.v
   |   |-- inst_control.v
   |-- cu
   |   |-- cu.v
   |-- decoder
   |   |-- decoder.v
   |-- dispatcher
   |   |-- dispatcher.v
   |-- fetcher
   |   |-- fetcher.v
   |-- gpu
   |   |-- gpu.v
   |-- lsu
   |   |-- lsu.v
   |-- pc
   |   |-- pc.v
   |-- rf
   |   |-- xblock_rf.v
   |-- scheduler
   |   |-- scheduler.v
test
   |-- alu_test
   |   |-- alu_manual_test.v
   |   |-- alu_test.py
   |-- cu_test
   |   |-- cu_test.py
   |-- datacontrol_test
   |   |-- datacontrol_test.py
   |-- decoder_test
   |   |-- decoder_test.py
   |-- dispatcher_test
   |   |-- dispatcher_test.py
   |-- fetcher_test
   |   |-- fetcher_test.py
   |-- gpu_test
   |   |-- gpu_test.py
   |-- instcontrol_test
   |   |-- instr_test.py
   |-- lsu_test
   |   |-- lsu_test.py
   |-- monitors
   |   |-- data_mem.py
   |   |-- inst_mem.py
wrapper
   |-- alu
   |   |-- wrapper_alu.v
   |-- controller
   |   |-- wrapper_datacont.v
   |   |-- wrapper_instcont.v
   |-- cu
   |   |-- wrapper_cu.v
   |-- decoder
   |   |-- wrapper_decoder.v
   |-- dispatcher
   |   |-- wrapper_dispatcher.v
   |-- fetcher
   |   |-- wrapper_fetcher.v
   |-- gpu
   |   |-- wrapper_gpu.v
   |-- lsu
   |   |-- wrapper_lsu.v
```

## Architecture Overview

GPUs can be viewed as essentially SIMT processing units, which stands for Single Instruction Multiple Threads where a single instruction is shared amongst multiple threads enabling a massive throughput of instruction processes. As a result, vectorized computations are much more efficient when using GPUs and in modern GPU architecture, a fairly expansive set of operations are supported within a single Streaming Multiprocessor unit. 

However, for the sake of simplicity and foundational understanding, much of the modern advanced architectures within GPUs are ommitted in MINIGPU including things such as: 

1. Wavepool Scheduling: This can be thought of as trying to efficiently organize and run specific threads of instructions in order to maximize overall GPU efficiency. In CPU land, this can be roughly viewed as pipelining instructions. 
2. Branch Divergence: This concept relates to the one above, but if we have two consecutive warps each with 16 threads and say half of the first warp takes "Branch A" and the rest "Branch B", while the second warp does the same thing, the wavepool scheduler can re-organize which threads belong to which warp to essentially minimize the overall number of cycles it will take to process both warps. 
3. Multi-leveled caching: In most modern systems, having a multi-leveled cache system is crucial to reduce general miss latency penalties and it is no different in a GPU. As described later, but each compute unit generally has its own cache (L1) which is then interfaced with a shared cache in the SM Unit (L2) which either then interfaces with global memory or another "globalized" cache shared between SMs (L3). 
   
For the implementation of MINIGPU, all of the architecture is designed under the assumption that each compute unit will have NO branch divergence and essentially every thread will be running the same instruction at a given time. 

### GPU Level Block Diagram

![GPU top level image](docs/gpu_top_level.svg)

This top level diagram depicts the overall architecture of the gpu.v file, where it contains a dispatcher, 4 instances of compute units, and two controllers one for data and the other for instructions. The implementation of these modules can be observed in their respective src files. 

### Compute Unit Block Diagram

![Compute Unit Top Level](docs/computeunit_top_level.svg)

This diagram displays the top level organization of a singular compute unit. Since GPUs follow SIMT processing architecture, we can see that we effectively have "4" smaller execute blocks that enable each core to perform up to 4 concurrent operations. 

### Thread Operation Overview



### Module Overview

This section will dive deeper into each of the modules listed above and explain their functionalities.

**GPU Top Level Modules**

1. **Dispatcher**: The dispatcher is responsible for "activating" the compute units. In a fully functional MINIGPU model, it is capable of handling up to 16 concurrent threads utilizing all 4 comptue units. However, for additional user-compatability, if, say, we only have an input of 12 threads, then the dispatcher will simply activate 3 of the compute units. One requirement is that the number of threads input to the GPU must be a multiple of 4. 
2. **Data Controller**: The data controller is the main channel of communication of the GPU and the external data memory. The reason we have a data controller in the first place is because in modern GPUs, if we simply provided full transparent global memory access from each of the compute units, when we scale up the overall size of the GPUs and the number of compute units, the width of those wires will begin to grow which may induce undesireable side effects from massive fanouts, cross talk, and general area consumption. To get around this, the data controller acts as an arbitrater essentially only "toggling" one compute unit's data memory request at a single time. (It chooses the compute unit based on a first come first serve round robin algorithm). Thus, instead of supporting a 16 wide communication channel (which in this scenario may not be too costly), it only supports a 4-thread wide communication channel. 
3. **Instruction Controller**: Similar to the data controller above, this instruction controller will only serve a singular compute unit at a time. However, instead of processing data (4 threads), it simply processes only one instruction request since MINIGPU's assumption is that thread executing in a compute unit will operate on the same instruction.  

**Compute Unit Level Modules**
1. Scheduler: The scheduler is the "controller" of each individual compute unit, effectively progressing a single instruction through the different stages of our GPU pipeline. 
2. Fetcher: The fetcher's ports interface with the top level gpu module since it produces a request to retrieve an instruction from memory. Again, since each thread in a compute unit operates on the same instruction, we only have one fetcher per compute unit to acquire the relevant instruction. 
3. Decoder: The decoder takes the retrieved instruction from our fetcher and decodes it into the appropriate parts. On any given instruction, all "possible" combinations of outputs are produced, however we also associate additional flags with each decoded instruction to ensure that our blocks later in the pipeline will understand which relevant data to reference. 
4. LSU (Load-Store-Unit): Unique to GPUs (unlike in a CPU), the load store unit is a small localized module that handles data requests for loading data from memory, and also data write requests for storing data memory. Similar to our fetcher, the ports of this module get bubbled up to interface with the data controller in the top level GPU module. 
5. ALU: The ALU computes the appropriate decoded opcode operation and returns a result. The data inputs to the ALU must be retrieved from the register file so if you want to perform an immediate operation, the immediate value should first be loaded as a CONST into the register file before accessing it. 
6. PC: The PC unit chooses how much to increment our PC which is essentially an internal register value that keeps track of which instruction we start at. For reference, our PC always starts at 0, so MINIGPU is only capable of performing operations on a single kernel at a time. Additionally, to simualate realistic instructions, we assume a 2-byte instruction (16 bits), so our PC increments by 2 on every subsequent operation. For branches, if we run into a branch, the immediate (instruction location) associated with that branch will get loaded onto the PC instead. 
7. RF: Each "execute" block has its own register file, and it is not uncommon to see actually larger register files in a GPU than caches since having additional register files enable us to support "more" complex operations. In MINIGPU, each register file contains 16 active registers, with the last 3 (R13, R14, R15) containing read only memory: (compute_unit_id, compute_unit_width, thread_id), while the first 13 registers (R0 to R12) are accessible and usable. 

## ISA Overview

The ISA for MINIGPU is a 12 instruction ISA based off the TinyRV2 ISA. As mentioned above, the main goal of MINIGPU is to support matrix multiplication and matrix addition which helped dictate which instructions were truly needed. The table below describes our instructions. 

#### ADD
- Usage: ADD RD RS1 RS2
- Semantics: RD <= RS1 + RS2
- Notes: Adds two 16-bit numbers together, both numbers need to be stored in a register beforehand.
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0000  | R-Dest |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### SUB
- Usage: SUB RD RS1 RS2
- Semantics: RD <= RS1 - RS2
- Notes: Performed signed subtraction of two 16-bit numbers. Numbers need to be stored in a register beforehand
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0001  | R-Dest |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### MUL
- Usage: MUL RD RS1 RS2
- Semantics: RD <= RS1 * RS2
- Notes: Multiplies two 16-bit numbers together, both numbers need to be stored in a register beforehand. Resulting value's top 16 bits are truncated. 
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0010  | R-Dest |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### DIV
- Usage: DIV RD RS1 RS2
- Semantics: RD <= RS1 / RS2
- Notes: Performs integer division on two 16 bit numbers. Numbers need to be stored in register beforehand and the result is condensed to only 16 bits.
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0011  | R-Dest |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### BNE
- Usage: BNE RIMM RS1 RS2
- Semantics: PC <= RIMM[ Val ] if RS1 != RS2
- Notes: Branches to the PC value stored on register RIMM if the condition of RS1 != RS2 is met. 
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0100  | R-IMM  |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### BEQ
- Usage: BEQ RIMM RS1 RS2
- Semantics: PC <= RIMM[ Val ] if RS1 == RS2
- Notes: Branches to the PC value stored on register RIMM if the condition of RS1 == RS2 is met. 
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0101  | R-IMM  |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### BLT
- Usage: BLT RIMM RS1 RS2
- Semantics: PC <= RIMM[ Val ] if RS1 < RS2
- Notes: Branches to the PC value stored on register RIMM if the condition of RS1 < RS2 is met. 
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0110  | R-IMM  |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### BGT
- Usage: BGT RIMM RS1 RS2
- Semantics: PC <= RIMM[ Val ] if RS1 > RS2
- Notes: Branches to the PC value stored on register RIMM if the condition of RS1 > RS2 is met. 
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  0111  | R-IMM  |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### CONST
- Usage: CONST RD IMM
- Semantics: RD <= IMM
- Notes: Stores the 8-bit input immediate value onto the register RD.
```
   15    12  11    8  7              0
  +--------+--------+--------+--------+
  |  1000  | RD     |       IMM       |
  +--------+--------+--------+--------+
```
#### LW
- Usage: LW RS1 RS2
- Semantics: RS1 <= Memory[ RS2 ]
- Notes: Loads the value from memory at RS2 onto the register RS2
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  1001  | XXXX   |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### SW
- Usage: SW RS1 RS2
- Semantics: Memory[ RS2 ] <= RS1 [ Val ]
- Notes: Stores the value at RS1 onto the memory location at RS2
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  1010  | XXXX   |  RS1   |  RS2   |
  +--------+--------+--------+--------+
```
#### NOP
- Usage: NOP
- Semantics: NOP
- Notes: A buffer instruction for nothing to happen down the compute unit pipeline
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  1011  | XXXX   |  XXXX  |  XXXX  |
  +--------+--------+--------+--------+
```
#### JR
- Usage: JR
- Semantics: JR
- Notes: An effective "return" statement (jump & return) to signal the end of a kernel. Sets the FSM state of the scheduler to DONE.
```
   15    12  11    8  7     4  3     0
  +--------+--------+--------+--------+
  |  1100  | XXXX   |  XXXX  |  XXXX  |
  +--------+--------+--------+--------+
```

