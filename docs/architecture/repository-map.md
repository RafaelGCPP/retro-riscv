# Repository Map (retro-riscv)

## 1. Objective

This document maps the repository structure, explains ownership/responsibilities of each area, and highlights key files that define system behavior.

It is intended to accelerate onboarding for humans and coding agents.

---

## 2. Root-Level Layout

```text
.devcontainer/                 Dev container setup
.gitattributes                 Git attributes
.gitignore                     Ignored files
Dockerfile                     Containerized build/dev environment
LICENSE                        Licensing information
Makefile                       Top-level orchestration (firmware, simulation, qemu, clean)
README.md                      Project overview, memory map, usage
docs/                          Documentation root
firmware/                      Firmware sources, linker scripts, build tooling
gowin/                         Gowin FPGA project support files (constraints/timing/etc.)
memory-ram.v                   Legacy/placeholder file at repo root (empty)
retro-riscv.gprj               Gowin project file
retro-riscv.gprj.user          Gowin user-local project metadata
verilator/                     RTL simulation harness and scripts
verilog/                       RTL sources (top, CPU core, memories, UART)
```

---

## 3. Directory-by-Directory Technical Map

### 3.1 `docs/`

Documentation area. Currently includes architecture documentation directory.

#### 3.1.1 `docs/architecture/`

Suggested canonical architecture docs location.
Current/new baseline docs include:
- `current-architecture.md`
- `repository-map.md`

Recommended future additions:
- `hw-sw-contract.md`
- `adr/` (architecture decision records)
- `verification-strategy.md`

---

### 3.2 `verilog/` (Core RTL)

Main RTL implementation for the SoC-like design.

Key files:
- `verilog/top.sv` — top-level integration, decode, and system wiring
- `verilog/picorv32.v` — PicoRV32 CPU core source
- `verilog/memory-rom.v` — ROM block and firmware initialization behavior
- `verilog/memory-ram.v` — RAM block implementation
- `verilog/uart-tx.v` — UART transmitter peripheral logic
- `verilog/uart-rx.v` — UART receiver peripheral logic

Responsibility boundary:
- **Defines hardware behavior** and memory/MMIO visibility to firmware.

Change impact:
- Any address/decode modification here typically requires firmware/header/docs updates.

---

### 3.3 `firmware/` (Software running on CPU)

Contains firmware/BIOS and target-specific build logic.

Key elements:
- `firmware/Makefile` — cross-compilation and target selection (`TARGET=`)
- `firmware/src/` — startup assembly, main loop, UART drivers and runtime logic
- `firmware/linker/` — linker scripts (`tang20k.ld`, `qemu.ld`, etc.)
- `firmware/tools/` — utilities (e.g., binary/ELF → HEX transformation)

Responsibility boundary:
- **Defines boot/runtime software behavior** over stable hardware interfaces.

Change impact:
- Linker/script changes affect memory placement and ROM image correctness.

---

### 3.4 `verilator/` (Cycle-accurate-ish simulation workflow)

Simulation integration layer for RTL validation.

Key files:
- `verilator/Makefile` — simulation build/run orchestration
- `verilator/sim_main.cpp` — C++ testbench entry/harness
- `verilator/run_verilator.sh` — wrapper script for local execution

Responsibility boundary:
- **Validates RTL + firmware integration** before FPGA deployment.

Change impact:
- Useful for detecting decode/peripheral regressions quickly.

---

### 3.5 `gowin/` + `retro-riscv.gprj` (FPGA implementation path)

Vendor flow assets for Tang Primer 20K Dock target.

Key assets:
- `retro-riscv.gprj` — project definition loaded in Gowin EDA
- `gowin/` — constraints, timing, and synthesis support files
- `retro-riscv.gprj.user` — user-local IDE state (non-portable preferences)

Responsibility boundary:
- **Transforms RTL into bitstream** for physical hardware.

Change impact:
- Pin/timing updates here can break runtime even when simulation passes.

---

### 3.6 `.devcontainer/` and `Dockerfile`

Developer environment reproducibility.

Responsibility boundary:
- Standardized tools/runtime for local and cloud development.

---

## 4. Cross-Cutting Build/Execution Flows

### 4.1 Firmware Build Flow

Entry: root `Makefile` and/or `firmware/Makefile`.
Output: firmware artifacts including `.hex` used by ROM initialization.

### 4.2 Verilator Flow

Entry: root `make verilator` / `verilator/Makefile`.
Consumes: RTL + firmware image.
Produces: simulation executable and UART/pseudo-device output.

### 4.3 QEMU Flow

Entry: root `make qemu`.
Purpose: firmware behavior sanity check in software-only emulation.

### 4.4 Gowin FPGA Flow

Entry: `retro-riscv.gprj` in Gowin EDA.
Consumes: RTL + constraints + firmware image.
Produces: FPGA programming artifact.

---

## 5. Key Technical Dependencies

- RISC-V GNU toolchain (`riscv64-unknown-elf-gcc`)
- Verilator
- QEMU (`qemu-system-riscv32`)
- Python 3 (tooling scripts)
- Gowin EDA (Tang 20K synthesis/programming)

---

## 6. Hotspots for Future Agent Work

These areas are likely high-value and high-impact:

1. `verilog/top.sv`
   - central integration and decode logic

2. `firmware/linker/*.ld`
   - memory contract between software and hardware

3. `firmware/src/*uart*` + MMIO constants
   - peripheral contract and debug visibility

4. `verilator/sim_main.cpp`
   - fast verification hooks and automated checks

5. `README.md` + `docs/architecture/*`
   - architecture truth sources (avoid divergence)

---

## 7. Observed Cleanup/Normalization Opportunities

1. Root-level `memory-ram.v` appears empty while active RAM RTL exists in `verilog/memory-ram.v`.
   - Consider removing or clearly marking root file as deprecated.

2. Establish one canonical place for memory map constants.
   - Prevent drift between README, firmware headers, and top-level RTL decode.

3. Add explicit CI targets for:
   - firmware build
   - Verilator smoke test
   - lint/style checks

---

## 8. Suggested Ownership Model (for Humans + Agents)

- `verilog/` owner: hardware architecture changes
- `firmware/` owner: software/runtime changes
- `verilator/` owner: verification and simulation quality
- `gowin/` owner: physical target constraints and implementation
- `docs/architecture/` owner: system-level coherence and contracts

This ownership model can be mirrored in issue labels and agent task routing.

---

## 9. File Quick-Reference Index

- `README.md` — project intent, memory map, usage commands
- `Makefile` — top-level command entrypoints
- `verilog/top.sv` — system integration root
- `verilog/picorv32.v` — CPU implementation
- `verilog/memory-rom.v` — ROM model/init
- `verilog/memory-ram.v` — RAM model
- `verilog/uart-tx.v` / `verilog/uart-rx.v` — UART peripherals
- `firmware/Makefile` — firmware target matrix/build
- `firmware/linker/*.ld` — memory layout policy
- `verilator/sim_main.cpp` — simulation harness entry point
- `retro-riscv.gprj` — Gowin project anchor

---

## 10. Maintenance Rule

Whenever one of the following changes, update this map in the same PR:
- directory structure
- memory map ownership/location
- build entrypoints
- verification flow entrypoints
