#!/bin/make

HARDWARE_SUBDIR := hardware
SOFTWARE_SUBDIR := software

SOFTWARE_TARGET := c_example \
				   c_test \

SOFTWARE_TARGET_PATH := $(addprefix $(SOFTWARE_SUBDIR)/, $(SOFTWARE_TARGET))

# the sim src should later be redefined
SIM_SRC := $(wildcard sim/sim_main.cpp)


all: build-soft
	@echo "$(SOFTWARE_TARGET)"
	@echo "$(SOFTWARE_TARGET_PATH)"

.PHONY: build-soft $(SOFTWARE_TARGET_PATH)

build-soft: $(SOFTWARE_TARGET_PATH)

$(SOFTWARE_TARGET_PATH):
	$(MAKE) -C $@

export SOFTWARE_TARGET
.PHONY: build-hard

build-hard: 
	$(MAKE) -C $(HARDWARE_SUBDIR)
