# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += /Users/mhui/Documents/proj_hdl/proj_minigpu/wrapper/controller/wrapper_instcont.v
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = wrapper_instcont

# MODULE is the basename of the Python test file
MODULE = instr_test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim