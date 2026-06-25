# Current Architecture (retro-riscv)

## 1. Purpose and Scope

This document describes the **current technical architecture** of the `retro-riscv` solution as implemented today.

It focuses on:
- RTL hardware architecture (CPU, memory, MMIO, UART)
- Firmware architecture and build outputs
- Simulation and FPGA implementation flow
- Key interfaces and constraints
- Near-term technical gaps that impact future evolution with coding agents

---

## 2. System Overview

`retro-riscv` implements a small retro-style computer on FPGA around a **PicoRV32** core.

At a high level:
- **CPU:** PicoRV32 (RV32IM)
- **Clock:** ~27 MHz (board clock)
- **Program storage:** on-chip ROM initialized from firmware HEX
- **Data storage:** on-chip RAM
- **Console I/O:** UART (MMIO)
- **Targets:**
  - Verilator simulation
  - QEMU firmware-only validation
  - Gowin synthesis/programming for Tang Primer 20K Dock

---

## 3. Hardware Architecture (RTL)

### 3.1 Top-Level Composition

The top-level module (`verilog/top.sv`) integrates:
- PicoRV32 CPU instance
- ROM (`verilog/memory-rom.v`)
- RAM (`verilog/memory-ram.v`)
- UART TX (`verilog/uart-tx.v`)
- UART RX (`verilog/uart-rx.v`) (available module; integration level should be validated against current top-level wiring)
- Address decoding / MMIO routing

### 3.2 CPU Core

- Source: `verilog/picorv32.v`
- Architecture: RV32IM-compatible PicoRV32 configuration (per project README)
- Memory access model: PicoRV32 native memory interface with central decode in top-level logic

### 3.3 Memory Map (Current)

As currently documented in the repository:

- `0x0000_0000 – 0x0000_3FFF` → ROM (16 KiB)
- `0x0001_0000 – 0x0001_1FFF` → RAM (8 KiB)
- `0x0001_2000` → initial stack pointer convention
- `0x1000_0000` → UART TX MMIO data register (write low byte)
- `0x1000_00FC` → Verilator pseudo-output device

### 3.4 ROM

- Module: `verilog/memory-rom.v`
- Role: instruction/program image storage
- Initialization source: firmware-generated HEX (flow-dependent path/copy step)
- Typical use: BIOS/monitor bootstrap code

### 3.5 RAM

- Module: `verilog/memory-ram.v`
- Role: runtime writable memory (data, stack, mutable state)
- Current capacity: 8 KiB on-chip block/distributed RAM (implementation inferred from current design scale)

### 3.6 UART Path

- TX module: `verilog/uart-tx.v`
- RX module: `verilog/uart-rx.v`
- Firmware-visible device: TX MMIO at `0x1000_0000`
- Default framing: 8-N-1 (as documented)

### 3.7 Clock/Reset

- Primary board clock target is 27 MHz (per README)
- Reset and clock-domain assumptions appear single-domain in current implementation
- No explicit multi-clock subsystem or asynchronous bridge documented yet

---

## 4. Firmware Architecture

### 4.1 Firmware Layout

Firmware is organized under `firmware/` with:
- `firmware/src/` → startup + C sources + UART drivers
- `firmware/linker/` → target linker scripts
- `firmware/tools/` → helper tools (e.g., binary-to-hex conversion)

### 4.2 Startup and Runtime Model

Current firmware acts as a minimal BIOS-style monitor seed:
- startup code initializes machine context
- UART is configured/used for console output
- firmware prints banner/alive prompt and loops

### 4.3 Target Abstraction

Firmware supports target selection using `TARGET=`:
- `tang20k`
- `verilator`
- `qemu`

Current documented mapping:
- `tang20k` and `verilator` use `tang20k.ld` + simple UART driver
- `qemu` uses `qemu.ld` + 16550-compatible UART driver

### 4.4 Output Artifacts

The firmware build produces artifacts including a HEX image used by hardware/simulation.
The README documents `firmware/build/tang20k/firmware.hex` as a key output.

---

## 5. Build, Simulation, and Deployment Architecture

### 5.1 Top-Level Build Orchestration

Repository root `Makefile` orchestrates common flows:
- firmware build
- Verilator simulation run
- QEMU execution
- cleanup

### 5.2 Verilator Flow

Under `verilator/`:
- `Makefile` for simulation compilation flow
- `sim_main.cpp` as C++ simulation harness
- `run_verilator.sh` helper script

Expected path:
1. Build firmware for simulation-compatible target
2. Compile RTL + harness with Verilator
3. Execute simulation binary and observe UART/pseudo-device output

### 5.3 FPGA (Gowin) Flow

- Project file: `retro-riscv.gprj`
- Constraints/timing are maintained under `gowin/` (board-specific assets)
- User opens project in Gowin EDA and runs synthesis/place-route/bitstream/programming

Important operational dependency:
- Firmware HEX must be available in expected location before synthesis to ensure ROM initialization matches intended firmware version.

### 5.4 Containerized/Dev Environment Support

- `.devcontainer/` and root `Dockerfile` indicate a reproducible development environment strategy for tools and onboarding.

---

## 6. Architectural Decisions (Observed)

1. **Single soft-core CPU baseline** to keep verification and bring-up simple.
2. **Memory-mapped UART** as first I/O primitive for deterministic debugging.
3. **On-chip ROM/RAM only** in current stage for minimal complexity.
4. **Dual validation paths** (QEMU for firmware + Verilator for RTL) to speed iteration.
5. **Vendor flow retained** (Gowin project) for hardware deployment realism.

---

## 7. Current Technical Constraints

1. **Memory capacity is intentionally small** (16 KiB ROM / 8 KiB RAM), limiting richer runtime features.
2. **No standardized peripheral bus layer** (e.g., Wishbone/APB/AHB-Lite abstraction) documented yet.
3. **Interrupt/timer/controller maturity** appears limited or planned rather than complete.
4. **Hardware/software contract is mostly implicit** (addresses and behavior in code + README, not yet centralized in machine-readable specs).
5. **Verification strategy is functional but lightweight** (room for formalized regressions and interface-level assertions).

---

## 8. Recommended Next Architecture Steps (Agent-Ready)

To make future agent-assisted evolution faster and safer:

1. Create a canonical **hardware-software interface spec** (`docs/architecture/hw-sw-contract.md`) including:
   - authoritative MMIO register table
   - read/write side effects
   - reset values
   - interrupt lines/events

2. Introduce a **memory map header generation flow**:
   - single source (YAML/JSON/TOML)
   - generated C headers + generated RTL `localparam` include

3. Add **verification tiers**:
   - smoke tests (firmware boot + UART message)
   - peripheral access tests
   - CI execution for Verilator target

4. Define **evolution seams** explicitly:
   - bus adapter boundary
   - interrupt controller insertion point
   - DDR/SDIO optional subsystem boundaries

5. Track architectural decisions in ADRs under `docs/architecture/adr/`.

---

## 9. Traceability to Current Repository

Primary files/directories used as architecture sources:
- `README.md`
- `verilog/top.sv`
- `verilog/picorv32.v`
- `verilog/memory-rom.v`
- `verilog/memory-ram.v`
- `verilog/uart-tx.v`
- `verilog/uart-rx.v`
- `firmware/Makefile`
- `firmware/src/`
- `firmware/linker/`
- `firmware/tools/`
- `verilator/Makefile`
- `verilator/sim_main.cpp`
- `verilator/run_verilator.sh`
- `gowin/`
- root `Makefile`

---

## 10. Status

This document reflects the repository state at the time of writing on branch `docs/architecture-baseline` and should be revised whenever memory map, MMIO, or build flows change.
