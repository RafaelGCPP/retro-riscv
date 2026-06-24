.PHONY: clean verilator qemu firmware

FIRMWARE_DIR := firmware
VERILATOR_DIR := verilator
SHELL := /usr/bin/env bash

clean:
	$(MAKE) -C $(FIRMWARE_DIR) clean
	rm -rf $(VERILATOR_DIR)/obj_dir
	rm -f $(VERILATOR_DIR)/firmware.hex firmware.hex
	rm -rf ./impl

verilator:
	$(MAKE) -C $(FIRMWARE_DIR) TARGET=verilator ARCH=rv32im
	$(MAKE) -C $(VERILATOR_DIR)

qemu:
	$(MAKE) -C $(FIRMWARE_DIR) qemu ARCH=rv32im

firmware:
	$(MAKE) -C $(FIRMWARE_DIR) TARGET=tang20k ARCH=rv32im