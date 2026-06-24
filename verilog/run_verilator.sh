#!/usr/bin/env bash
set -euo pipefail

# Rode este script no diretório onde estão:
#   top.sv memory.v picorv32.v uart-tx.v.v firmware.hex sim_main.cpp

verilator \
  --cc \
  --exe sim_main.cpp \
  --build \
  --top-module top \
  --sv \
  -DVERILATOR \
  -Wno-fatal \
  top.sv memory_fixed.v picorv32.v uart-tx.v.v

./obj_dir/Vtop
printf '\n'
