# F1 - UART RX Channel: Rollout and Testing Plan

## Phased Implementation Strategy

To ensure manageable token usage and incremental validation, the implementation is split into **6 discrete development stories** (dev stories DS1-DS6).

---

## Phase 1: Foundation (Data Section Fix)

### **Dev Story DS1: Fix .data Section Initialization in start.S**

**Priority:** CRITICAL (blocks all subsequent work)

**Objective:** Ensure initialized global variables are correctly copied from ROM to RAM.

**Scope:**
- Modify `firmware/src/start.S` to add `.data` copy loop
- Update `firmware/linker/tang20k.ld` and `firmware/linker/qemu.ld` to define `__data_lma_start`

**Acceptance Criteria:**
- Assembly builds without errors
- Linker produces valid ELF with correct `.data` LMA/VMA
- QEMU smoke test: firmware boots and prints banner

**Files Modified:**
1. `firmware/src/start.S` (add copy_data section)
2. `firmware/linker/tang20k.ld` (add __data_lma_start symbol)
3. `firmware/linker/qemu.ld` (add __data_lma_start symbol)

**Estimated Complexity:** Low  
**Dependencies:** None  
**Testing:** QEMU smoke test, Verilator smoke test

---

## Phase 2: Hardware Implementation

### **Dev Story DS2: Define New UART Register Map in RTL**

**Objective:** Update `top.sv` to implement 3-register UART interface (TXDATA, RXDATA, STATUS).

**Scope:**
- Add address decode logic for three UART registers
- Update memory response mux to handle new addresses
- **DO NOT wire UART RX module yet** (stub RX_VALID=0)

**Acceptance Criteria:**
- RTL compiles in Verilator without errors
- Firmware reading UART_STATUS returns TX_IDLE bit correctly
- Reading UART_RXDATA returns 0x00000000 (stub)

**Files Modified:**
1. `verilog/top.sv` (register decode + mux logic)

**Estimated Complexity:** Medium  
**Dependencies:** None  
**Testing:** Verilator compilation check

---

### **Dev Story DS3: Integrate UART RX Module into top.sv**

**Objective:** Wire `uart-rx.v` module and implement RX data latch logic.

**Scope:**
- Add `uart_rxd` input pin to `top.sv` module interface
- Instantiate `uart_rx` module with correct parameters
- Implement RX data latch register and valid flag logic
- Connect latch to UART_RXDATA and UART_STATUS registers

**Acceptance Criteria:**
- RTL compiles successfully
- Verilator simulation can read characters injected via uart_rxd
- RX_VALID flag toggles correctly on receive

**Files Modified:**
1. `verilog/top.sv` (module instantiation + latch logic)

**Estimated Complexity:** Medium-High  
**Dependencies:** DS2  
**Testing:** Verilator waveform inspection

---

## Phase 3: Firmware Driver Development

### **Dev Story DS4: Implement UART RX Driver Functions**

**Objective:** Create firmware functions to read UART input.

**Scope:**
- Extend `uart.h` with RX function prototypes
- Implement `uart_rx_available()`, `uart_getc()`, `uart_getc_nowait()` in `uart_tang_simple.c`
- Update constants to use new register map (UART_TXDATA, UART_RXDATA, UART_STATUS)
- Update `uart_qemu_16550.c` to match same API

**Acceptance Criteria:**
- Firmware compiles for all targets (tang20k, verilator, qemu)
- UART TX functionality still works correctly
- No regressions in existing banner print

**Files Modified:**
1. `firmware/src/uart.h` (add prototypes)
2. `firmware/src/uart_tang_simple.c` (implement RX functions, update TX)
3. `firmware/src/uart_qemu_16550.c` (update for new register map)

**Estimated Complexity:** Medium  
**Dependencies:** DS3 (for Verilator), DS1 (for build system)  
**Testing:** Compilation test for all targets

---

## Phase 4: Application Integration

### **Dev Story DS5: Implement Acceptance Test in main.c**

**Objective:** Update main firmware to wait for 'h' key and respond.

**Scope:**
- Modify `firmware/src/main.c` to implement interactive loop
- Print banner and prompt
- Wait for user input using `uart_rx_available()` and `uart_getc()`
- Echo received character and print "alive" when 'h' is pressed

**Acceptance Criteria:**
- QEMU: user can type 'h' and see echo + "alive"
- Verilator: simulation with injected 'h' input passes
- Verilator: simulation calls `simulation_exit(0)` after successful interaction

**Files Modified:**
1. `firmware/src/main.c` (replace heartbeat loop with interactive code)

**Estimated Complexity:** Low  
**Dependencies:** DS4  
**Testing:** QEMU manual test, Verilator automated test

---

### **Dev Story DS6: Enhance Verilator Test Harness for Input Injection**

**Objective:** Make Verilator simulation inject 'h' character automatically.

**Scope:**
- Update `verilator/sim_main.cpp` to drive `uart_rxd` pin
- Simulate UART serial protocol (start bit, 8 data bits, stop bit at 115200 baud)
- Inject 'h' character after banner is printed
- Validate firmware response and clean exit

**Acceptance Criteria:**
- `make verilator` runs end-to-end without user interaction
- Simulation output shows banner, echoed 'h', and "alive"
- Simulation exits with code 0

**Files Modified:**
1. `verilator/sim_main.cpp` (add UART RX injection logic)

**Estimated Complexity:** Medium-High  
**Dependencies:** DS5  
**Testing:** Automated Verilator test

---

## Phase 5: Documentation Updates

### **Dev Story DS7: Update Architecture Documentation**

**Objective:** Synchronize all architecture documents with implemented changes.

**Scope:**
- Update `docs/architecture/hw-sw-contract.md`:
  - Document UART_TXDATA, UART_RXDATA, UART_STATUS registers
  - Document register bitmaps and side effects
  - Mark old register layout as deprecated
- Update `docs/architecture/current-architecture.md`:
  - Add UART RX data flow diagram
  - Update memory map table
  - Document .data section initialization requirement
- Update `docs/architecture/repository-map.md`:
  - Add note about `uart-rx.v` integration

**Acceptance Criteria:**
- All register addresses in docs match RTL implementation
- Side effects (RX_VALID clear on read) are documented
- Migration notes for breaking changes are clear

**Files Modified:**
1. `docs/architecture/hw-sw-contract.md`
2. `docs/architecture/current-architecture.md`
3. `docs/architecture/repository-map.md`

**Estimated Complexity:** Low  
**Dependencies:** DS1-DS6 (all implementation complete)  
**Testing:** Documentation review, manual cross-check with code

---

## Testing Matrix

| Test Case | Target | Type | Pass Criteria |
|---|---|---|---|
| TC1: Banner print | QEMU | Smoke | Banner appears correctly |
| TC2: Banner print | Verilator | Smoke | Banner appears in simulation output |
| TC3: .data init | QEMU | Functional | Initialized globals have correct values |
| TC4: UART TX | QEMU | Regression | "alive" message prints correctly |
| TC5: UART TX | Verilator | Regression | UART TX still functional |
| TC6: UART RX polling | QEMU | Functional | uart_rx_available() detects input |
| TC7: UART RX read | QEMU | Functional | uart_getc() returns typed character |
| TC8: Echo test | QEMU | Integration | Typing 'h' produces "h\nalive\n" |
| TC9: Echo test | Verilator | Integration | Injected 'h' produces correct output |
| TC10: Auto-exit | Verilator | Integration | Simulation exits with code 0 |

---

## Implementation Timeline

| Phase | Dev Stories | Estimated Duration | Dependencies |
|---|---|---|---|
| Phase 1 | DS1 | 1-2 hours | None |
| Phase 2 | DS2, DS3 | 3-4 hours | DS1 (for testing) |
| Phase 3 | DS4 | 2-3 hours | DS3 |
| Phase 4 | DS5, DS6 | 2-3 hours | DS4 |
| Phase 5 | DS7 | 1-2 hours | DS1-DS6 complete |
| **Total** | **7 stories** | **9-14 hours** | Sequential execution |

---

## Risk Mitigation

### Risk 1: UART RX Module Parameter Mismatch
- **Mitigation:** Verify CLK_HZ parameter matches FREQ localparam in top.sv
- **Detection:** Verilator waveform analysis shows incorrect baud rate

### Risk 2: Verilator UART RX Input Injection Complexity
- **Mitigation:** Start with simple bit-banging, verify with waveform
- **Fallback:** Manual testing on QEMU only for Phase 4

### Risk 3: QEMU 16550 Driver Incompatibility
- **Mitigation:** QEMU uses different hardware model, test early
- **Fallback:** Document QEMU-specific limitations

---

## Rollback Plan

If critical issues arise after merging:

1. **Firmware-only rollback:**
   - Revert `uart_tang_simple.c` to single-register access
   - Keep `.data` section fix (safe improvement)

2. **Full rollback:**
   - Revert RTL changes in `top.sv`
   - Revert firmware driver changes
   - Keep documentation updates as "proposed architecture"

---

## Post-Deployment Tasks

After successful merge:

1. **Performance Validation:**
   - Measure firmware binary size growth
   - Verify no timing violations in GoWin synthesis

2. **User Documentation:**
   - Update README.md with interactive command example
   - Add troubleshooting guide for UART issues

3. **Baseline Regression Suite:**
   - Codify TC1-TC10 as automated CI tests
   - Add to repository Makefile targets

4. **Architecture Freeze:**
   - Tag commit as `hw-sw-contract-v1`
   - Document in `docs/architecture/CHANGELOG.md`
