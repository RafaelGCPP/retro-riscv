#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

pushd "${ROOT_DIR}/firmware"
cp build/verilator/firmware.hex "${ROOT_DIR}/verilator/firmware.hex"
popd

pushd "${SCRIPT_DIR}"
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
popd
