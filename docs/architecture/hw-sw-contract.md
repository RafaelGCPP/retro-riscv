# Hardware–Software Contract (HW/SW Contract)

## 1. Purpose

This document defines the **authoritative contract** between RTL hardware and firmware software for `retro-riscv`.

Its goals are to:
- make interfaces explicit for maintainers and coding agents,
- prevent contract drift across RTL/firmware/docs,
- provide clear compatibility rules for future evolution.

> Scope of this version: baseline contract for the current architecture on branch `docs/architecture-baseline`.

---

## 2. Contract Versioning

- **Contract ID:** `hw-sw-contract-v0`
- **Status:** Baseline / active
- **Compatibility policy:**
  - Additive changes are preferred (new MMIO addresses/registers without altering old behavior).
  - Breaking changes require:
    1. contract version bump,
    2. firmware adaptation in same PR,
    3. migration note in `docs/architecture/`.

---

## 3. CPU and Execution Model

### 3.1 CPU Core

- Core: PicoRV32 (RV32IM profile as documented in repository README)
- XLEN: 32 bits
- Endianness: little-endian (RISC-V standard expectation)

### 3.2 Reset/Boot Contract

- CPU reset starts execution from ROM space.
- Firmware image is expected to be present in ROM initialization data before simulation/synthesis run.
- Initial software stack placement convention: `0x0001_2000` (see memory map).

---

## 4. Memory Map (Authoritative)

All addresses are 32-bit physical addresses.

| Region | Start | End | Size | Access | Owner | Notes |
|---|---:|---:|---:|---|---|---|
| ROM | `0x0000_0000` | `0x0000_3FFF` | 16 KiB | Read (exec/read) | RTL + build flow | Firmware/BIOS image |
| RAM | `0x0001_0000` | `0x0001_1FFF` | 8 KiB | Read/Write | RTL | Runtime data/stack |
| Stack initial SP convention | `0x0001_2000` | `0x0001_2000` | n/a | n/a | Firmware | Initial SP value convention |
| UART TX MMIO | `0x1000_0000` | `0x1000_0000` | 4 bytes logical register window | Write-oriented | RTL + firmware driver | Write low byte to transmit |
| Verilator pseudo-device | `0x1000_00FC` | `0x1000_00FC` | 4 bytes | Impl-defined | Verilator harness path | Simulation helper output |

### 4.1 Addressing Rules

- Firmware must use `volatile` MMIO accesses for peripheral addresses.
- Firmware must not assume unmapped address behavior (read value or write side effects are undefined unless documented).
- Alignment assumptions:
  - Byte writes to UART TX low byte are the canonical operation.
  - Wider accesses are implementation-defined unless explicitly validated.

---

## 5. MMIO Register Contract

## 5.1 UART TX Data Register

- **Address:** `0x1000_0000`
- **Name:** `UART_TXDATA`
- **Access:** write
- **Write semantics:**
  - `write[7:0]` is transmitted as one UART frame (8-N-1)
  - upper bits are ignored unless later documented otherwise
- **Read semantics:** undefined / do not rely on return value
- **Reset value:** n/a (transmit datapath)

Recommended C declaration:

```c
#define UART_TXDATA_ADDR 0x10000000u
#define UART_TXDATA (*(volatile unsigned int*)UART_TXDATA_ADDR)
```

## 5.2 Verilator Pseudo Output Register

- **Address:** `0x1000_00FC`
- **Name:** `SIM_PSEUDO_OUT`
- **Access:** simulation-specific (typically write)
- **Semantics:** used by simulation flow for observable output/debug signaling
- **Hardware deployment note:** firmware for physical FPGA should not require this register for correctness

---

## 6. ROM Image Contract

### 6.1 Artifact Format

- Firmware build must produce a HEX image compatible with ROM initialization logic.
- Artifact path conventions are controlled by firmware/build makefiles and may vary per target.

### 6.2 Integration Requirements

Before running Verilator or FPGA synthesis:
1. Correct firmware target must be built.
2. Generated HEX must be in the expected location/name consumed by ROM init flow.

If ROM init file is missing/mismatched, behavior is undefined (typically no useful boot).

---

## 7. Firmware Contract Requirements

Firmware code interacting with hardware must:

1. Centralize base addresses and constants (single header strongly recommended).
2. Use linker scripts consistent with memory map regions.
3. Avoid hardcoding undocumented MMIO behavior.
4. Treat all undocumented reads from write-only/peripheral addresses as undefined.

Target-specific behavior:
- `qemu` target may use different UART model and linker constraints than FPGA/Verilator target.
- `tang20k` and `verilator` targets should remain aligned to this contract unless versioned otherwise.

---

## 8. Undefined / Reserved Behavior

The following are intentionally **unspecified** in this contract version:

- interrupt controller programming model (not standardized here yet),
- timer MMIO registers (not standardized here yet),
- DMA/bus arbitration behavior,
- cache or coherence behavior,
- ordering guarantees beyond baseline single-core execution model.

Software must not infer behavior in these areas without explicit spec updates.

---

## 9. Compatibility and Change Control

## 9.1 Non-Breaking Changes (Allowed in v0)

- Add new MMIO registers at unused addresses.
- Add new peripherals without modifying existing register semantics.
- Add optional features guarded by compile-time or runtime capability checks.

## 9.2 Breaking Changes (Require Version Bump)

Examples:
- moving ROM/RAM base addresses,
- changing UART TX register behavior at `0x1000_0000`,
- removing or redefining existing MMIO addresses,
- changing boot entry assumptions that require firmware rewrite.

Required actions for breaking changes:
1. define `hw-sw-contract-vN+1`,
2. update firmware and linker scripts in same change set,
3. add migration section in architecture docs.

---

## 10. Validation Checklist (PR Gate Suggestion)

For PRs touching RTL/firmware interface:

- [ ] MMIO table in this document still matches RTL decode logic.
- [ ] Firmware constants/header updated accordingly.
- [ ] Linker scripts remain valid for memory map.
- [ ] Verilator smoke run passes.
- [ ] README and architecture docs updated if externally visible behavior changed.

---

## 11. Recommended Single Source of Truth (Next Step)

To reduce ambiguity, adopt a machine-readable contract source, e.g.:

- `docs/architecture/hw-sw-contract.yaml`

and generate:
- firmware C headers,
- RTL `localparam` include file,
- markdown register tables.

This improves consistency and agent automation reliability.

---

## 12. References

Primary repository references backing this contract:
- `README.md`
- `verilog/top.sv`
- `verilog/memory-rom.v`
- `verilog/memory-ram.v`
- `verilog/uart-tx.v`
- `verilog/uart-rx.v`
- `firmware/Makefile`
- `firmware/linker/`
- `verilator/sim_main.cpp`
