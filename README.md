# retro-riscv

Um computador em estilo retrô, implementado em FPGA, com um processador RISC-V ([PicoRV32](https://github.com/YosysHQ/picorv32)).

> **Hardware alvo:** [Sipeed Tang Primer 20K Dock](https://wiki.sipeed.com/hardware/en/tang/tang-primer-20k/primer-20k.html) (Gowin GW2A-18)

---

## Visão geral

O projeto reimagina a experiência dos computadores de 8/16 bits dos anos 80, mas substituindo o hardware original por um soft-core RISC-V moderno rodando em FPGA. O objetivo é ter um ambiente completo — da CPU ao monitor de linguagem de máquina, passando por armazenamento e saída de som.

### Hardware implementado

| Componente | Detalhes |
|---|---|
| CPU | PicoRV32 — RV32IM (inteiros + multiplicação/divisão) |
| Clock | 27 MHz (~37 ns de período) |
| ROM | 16 KiB em `0x0000_0000` (inicializada com o firmware) |
| RAM | 8 KiB em `0x0001_0000` |
| UART TX | MMIO em `0x1000_0000` (8-N-1) |

### Mapa de memória

```
0x0000_0000 – 0x0000_3FFF   ROM (16 KiB) — firmware / BIOS
0x0001_0000 – 0x0001_1FFF   RAM (8 KiB)
0x0001_2000                 Stack pointer inicial
0x1000_0000                 UART TX (MMIO — escrever byte no bit[7:0])
0x1000_00FC                 Pseudo-device de saída do Verilator
```

---

## Estrutura do repositório

```
firmware/           Firmware em C/Assembly (BIOS)
  src/              Código-fonte (main.c, start.S, drivers UART)
  linker/           Linker scripts (qemu.ld, tang20k.ld)
  tools/            Utilitários (bin2hex.py)
gowin/              Arquivos de projeto Gowin EDA (.cst, .sdc)
verilator/          Testbench de simulação com Verilator
verilog/            RTL do projeto (top.sv, picorv32.v, memórias, UART)
Makefile            Orquestrador principal
```

---

## Dependências

| Ferramenta | Uso |
|---|---|
| [Gowin EDA](https://www.gowinsemi.com/en/support/home/) (Education ≥ 1.9.11) | Síntese e place-and-route para o Tang 20K |
| `riscv64-unknown-elf-gcc` | Cross-compilador para o firmware |
| [Verilator](https://www.veripool.org/verilator/) | Simulação RTL |
| [QEMU](https://www.qemu.org/) (`qemu-system-riscv32`) | Teste do firmware sem hardware |
| Python 3 | Script `bin2hex.py` |

---

## Como usar

### 1. Compilar o firmware para o Tang 20K

```bash
make firmware
# Gera firmware/build/tang20k/firmware.hex
```

### 2. Simular com Verilator

```bash
make verilator
# Compila o firmware (target verilator) e executa a simulação
```

### 3. Testar o firmware no QEMU

```bash
make qemu
```

### 4. Síntese no Gowin EDA

Abra o projeto `retro-riscv.gprj` no Gowin EDA e execute **Synthesis → Place & Route → Program Device**.  
O arquivo `firmware.hex` gerado pelo `make firmware` deve estar na raiz do projeto antes da síntese.

### 5. Limpar artefatos

```bash
make clean
```

---

## Firmware / BIOS

O firmware atual exibe uma mensagem de boas-vindas pela UART e entra em loop com um heartbeat (prompt `> alive`). Serve como base para o desenvolvimento do monitor de linguagem de máquina.

Targets suportados:

| `TARGET=` | Linker script | Driver UART |
|---|---|---|
| `tang20k` | `tang20k.ld` | `uart_tang_simple.c` |
| `verilator` | `tang20k.ld` | `uart_tang_simple.c` |
| `qemu` | `qemu.ld` | `uart_qemu_16550.c` |

---

## Backlog

### Planejado

- [ ] **DDR3 como RAM principal** — expandir a memória disponível usando a DDR3 da placa Tang 20K Dock via controlador Gowin DDRX IP
- [ ] **SDIO / SD Card** — leitura de arquivos do cartão SD (base para carregar programas e dados)
- [ ] **Monitor de linguagem de máquina** — interface interativa via UART para inspecionar/modificar memória, registradores e executar código
- [ ] **Linguagem de alto nível** — interpretador embutido (candidatos: Forth, Tiny BASIC, Lua)
- [ ] **Emulação de chip de som** — PSG (AY-3-8910 / YM2149) ou SID (MOS 6581) em RTL ou via soft-core

### Sugeridos

- [ ] **Saída de vídeo VGA/HDMI** — modo texto (80×25) e/ou modo gráfico bitmap; a placa Tang 20K Dock possui conector HDMI onboard
- [ ] **Entrada por teclado** — suporte a PS/2 ou USB HID para digitar diretamente no hardware
- [ ] **Bootloader serial** — carregar programas via UART (protocolo XMODEM/SREC) sem resintetizar
- [ ] **Sistema de arquivos FAT** — camada FAT16/FAT32 sobre o SDIO para facilitar troca de arquivos com o PC
- [ ] **Modo gráfico tile/sprite** — PPU simples (tiles de 8×8) para jogos e demos, inspirado no VDP do MSX/NES
- [ ] **Controlador de interrupções** — IRQ para UART RX, timer e outros periféricos, permitindo firmware orientado a eventos
- [ ] **Timer de sistema** — contador de 32/64 bits mapeado em MMIO para multitarefa e delays precisos
- [ ] **SPI Flash** — armazenamento persistente de programas sem SD Card (W25Qxx onboard)
- [ ] **Barramento de expansão** — pinos GPIO expostos no header da placa para periféricos externos (PMOD etc.)
- [ ] **RTC (relógio em tempo real)** — integração com chip I²C externo ou emulação via contador interno

---

## Licença

Este projeto é licenciado sob a [CERN Open Hardware Licence Version 2 – Weakly Reciprocal (CERN-OHL-W v2)](https://ohwr.org/cern_ohl_w_v2.txt).

Modificações ao design devem ser distribuídas sob os mesmos termos.  
Componentes de terceiros (PicoRV32 — ISC License; IPs Gowin — licença proprietária Gowin) mantêm suas licenças originais.
