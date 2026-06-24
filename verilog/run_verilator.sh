#!/usr/bin/env bash
set -euo pipefail

# Rode este script no diretório onde estão:
#   top.sv memory-ram.v memory-rom.v picorv32.v uart-tx.v firmware.hex sim_main.cpp

verilator \
  --cc \
  --exe sim_main.cpp \
  --build \
  --top-module top \
  --sv \
  -DVERILATOR \
  -Wno-fatal \
  top.sv memory-ram.v memory-rom.v picorv32.v uart-tx.v

./obj_dir/Vtop
printf '\n'
