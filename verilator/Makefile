.PHONY: verilator copy-firmware clean

ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
FIRMWARE_DIR := $(ROOT_DIR)/../firmware
VERILOG_DIR := $(ROOT_DIR)/../verilog
VERILOG_SOURCES := $(wildcard $(VERILOG_DIR)/*.sv $(VERILOG_DIR)/*.v)
FIRMWARE_FILE := $(FIRMWARE_DIR)/build/verilator/firmware.hex

verilator: copy-firmware $(VERILOG_SOURCES)
	verilator \
	  --cc \
	  --exe sim_main.cpp \
	  --build \
	  --top-module top \
	  --sv \
	  -DVERILATOR \
	  -Wno-fatal \
	  $(VERILOG_DIR)/*.sv $(VERILOG_DIR)/*.v
	./obj_dir/Vtop
	printf '\n'

copy-firmware: $(FIRMWARE_FILE)
	@mkdir -p $(ROOT_DIR)
	cp $(FIRMWARE_FILE) $(ROOT_DIR)/firmware.hex

$(FIRMWARE_FILE):	
	$(MAKE) -C $(FIRMWARE_DIR) TARGET=verilator ARCH=rv32im

clean:
	rm -rf obj_dir firmware.hex
