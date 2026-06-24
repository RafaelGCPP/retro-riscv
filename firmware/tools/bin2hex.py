#!/usr/bin/env python3

import sys

if len(sys.argv) != 3:
    print("usage: bin2hex.py input.bin output.hex")
    sys.exit(1)

inp = sys.argv[1]
out = sys.argv[2]

with open(inp, "rb") as f:
    data = f.read()

while len(data) % 4 != 0:
    data += b"\x00"

with open(out, "w") as f:
    for i in range(0, len(data), 4):
        b0, b1, b2, b3 = data[i:i + 4]

        # RISC-V little-endian:
        # bytes 13 00 00 00 viram palavra 00000013
        word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

        f.write(f"{word:08x}\n")