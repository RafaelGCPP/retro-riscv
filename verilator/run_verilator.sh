#!/usr/bin/env bash
set -euo pipefail

cp ../firmware/build/verilator/firmware.hex firmware.hex

verilator \
  --cc \
  --exe sim_main.cpp \
  --build \
  --top-module top \
  --sv \
  -DVERILATOR \
  -Wno-fatal \
  ../verilog/*.sv ../verilog/*.v

./obj_dir/Vtop
printf '\n'
