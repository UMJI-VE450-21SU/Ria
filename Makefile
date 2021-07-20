# Project: RISC-V SoC Microarchitecture Design & Optimization
#          GNU Makefile
# Author:  Yichao Yuan, Li Shi
# Date:    2021/07/02

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

SOFTWARE_SUBDIR := software

SOFTWARE_TARGET := c_example

SOFTWARE_TARGET_PATH := $(addprefix $(SOFTWARE_SUBDIR)/, $(SOFTWARE_TARGET))


ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS += --top-module top

# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# suppress all warnings
VERILATOR_FLAGS += -Wno-UNOPTFLAT
VERILATOR_FLAGS += -Wno-WIDTH
VERILATOR_FLAGS += -Wno-PINMISSING


# Optimize
# VERILATOR_FLAGS += -Os -x-assign 0
# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert

VERILATOR_FLAGS += --unroll-count 128

VERILOG_ROOT := src
# Input files for Verilator
VERILOG_SRC = $(wildcard src/common/*.svh src/external/fifo/*.v src/external/*.sv src/frontend/*.sv src/backend/*.sv src/*.sv)

SIM_SRC := $(wildcard sim/sim_*.cpp)

VERILATOR_OPTIONS := input.vc

# Input files for Verilator
VERILATOR_INPUT = -f $(VERILATOR_OPTIONS) $(VERILOG_SRC) $(SIM_SRC)

# the program to run
SIMULATOR_PROG = software/c_example/c_example.bin
#SIMULATOR_PROG = myfile
# the dmem init
SIMULATOR_DATA_INIT = software/c_example/c_example.bin

default: run

verilate: build-soft
	@echo
	@echo "-- VERILATE ----------------"
	@echo "Inputs: "
	@echo $(VERILATOR_INPUT)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)
	@echo


build: verilate
	$(MAKE) -j -C obj_dir -f ../Makefile_obj
	@echo

run: build
	@rm -rf logs
	@mkdir -p logs
	obj_dir/Vtop ${SIMULATOR_PROG} ${SIMULATOR_DATA_INIT} +trace
	@echo "-- DONE --------------------"
	@echo "To see waveforms, open vlt_dump.vcd in a waveform viewer"
	@echo


######################################################################
# Other targets
.PHONY: build-soft $(SOFTWARE_TARGET_PATH)

build-soft: $(SOFTWARE_TARGET_PATH)

export SOFTWARE_TARGET
$(SOFTWARE_TARGET_PATH):
	$(MAKE) -C $@


show-config:
	$(VERILATOR) -V

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.log *.dmp *.vpd coverage.dat core

WAVEFORM_VIEWER := gtkwave

.PHONY: view-waveform

view-waveform:
	$(WAVEFORM_VIEWER) logs/vlt_dump.vcd	
