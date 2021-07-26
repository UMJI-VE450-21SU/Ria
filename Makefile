# Project: RISC-V SoC Microarchitecture Design & Optimization
#          GNU Makefile
# Author:  Yichao Yuan, Li Shi
# Date:    2021/07/02

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

SOFTWARE_SUBDIR := software

SOFTWARE_TARGET := c_example c_hello

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
VERILATOR_FLAGS += -cc -exe
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

# [use this to change testbench]
# a spike-like environment is sim_main2, not tested yet, the entry point of the CPU should be default to 0x80000000
SIM_TARGET = sim_main
SIM_TARGET_SRC = $(SIM_TARGET).cc

include sim/fesvr450.mk.in

SIM_SRC := $(addprefix sim/,  $(fesvr450_srcs) $(SIM_TARGET_SRC))
VERILATOR_OPTIONS := input.vc

# Input files for Verilator
VERILATOR_INPUT = -f $(VERILATOR_OPTIONS) $(VERILOG_SRC) $(SIM_SRC)

# the program to run
SIMULATOR_PROG = prog/bin/c_example.bin
#SIMULATOR_PROG = myfile
# the dmem init
#SIMULATOR_DATA_INIT = software/c_example/c_example.bin

default: run

verilate:
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
	obj_dir/Vtop ${SIMULATOR_PROG} +trace
	@echo "-- DONE --------------------"
	@echo "To see waveforms, open vlt_dump.vcd in a waveform viewer"
	@echo

view-wave: run
	gtkwave obj_dir/vlt_dump.vcd


######################################################################
# Other targets
.PHONY: build-soft $(SOFTWARE_TARGET_PATH) install-soft sim-spike

build-soft: $(SOFTWARE_TARGET_PATH)

export SOFTWARE_TARGET
$(SOFTWARE_TARGET_PATH):
	$(MAKE) -C $@

SOFTWARE_ELF := $(foreach target, ${SOFTWARE_TARGET}, $(addsuffix .elf, $(addprefix $(SOFTWARE_SUBDIR)/$(target)/, $(target))))
SOFTWARE_BIN := $(foreach target, ${SOFTWARE_TARGET}, $(addsuffix .bin, $(addprefix $(SOFTWARE_SUBDIR)/$(target)/, $(target))))
install-soft: build-soft
	cp ${SOFTWARE_ELF} prog/elf
	cp ${SOFTWARE_BIN} prog/bin


show-config:
	$(VERILATOR) -V

####### spike software, will be merged to the verilator flow when everthing is done ########

SPIKE_BIN := bin/spike
SPIKE_PROG_DIR := spike-software
SPIKE_PROG := sobel.elf
SPIKE_OPT := --isa=rv32i --priv=mu

sim-spike: make-spike
	$(SPIKE_BIN) $(SPIKE_OPT) $(SPIKE_PROG_DIR)/$(SPIKE_PROG)

make-spike:
	$(MAKE) -C $(SPIKE_PROG_DIR)

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.log *.dmp *.vpd coverage.dat core

WAVEFORM_VIEWER := gtkwave

.PHONY: view-waveform

view-waveform:
	$(WAVEFORM_VIEWER) logs/vlt_dump.vcd	
