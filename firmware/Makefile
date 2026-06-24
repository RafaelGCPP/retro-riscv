CROSS ?= riscv64-unknown-elf-

CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
SIZE    := $(CROSS)size
READELF := $(CROSS)readelf

PYTHON ?= python3

ARCH ?= rv32i
ABI  ?= ilp32

TARGET ?= qemu

BUILD_DIR  := build/$(TARGET)
SRC_DIR    := src
LINKER_DIR := linker
TOOLS_DIR  := tools

# ------------------------------------------------------------
# Plataforma
# ------------------------------------------------------------

ifeq ($(TARGET),qemu)
    LDSCRIPT := $(LINKER_DIR)/qemu.ld
    UART_SRC := $(SRC_DIR)/uart_qemu_16550.c
else ifeq ($(TARGET),tang20k)
    LDSCRIPT := $(LINKER_DIR)/tang20k.ld
    UART_SRC := $(SRC_DIR)/uart_tang_simple.c
else ifeq ($(TARGET),verilator)
    LDSCRIPT := $(LINKER_DIR)/tang20k.ld
    UART_SRC := $(SRC_DIR)/uart_tang_simple.c
    CFLAGS += -DHEARTBEAT_COUNT=1000u
else
    $(error Unknown TARGET=$(TARGET). Use TARGET=qemu or TARGET=tang20k)
endif

# ------------------------------------------------------------
# Fontes
# ------------------------------------------------------------

SRCS := \
    $(SRC_DIR)/start.S \
    $(SRC_DIR)/main.c \
    $(UART_SRC)

# ------------------------------------------------------------
# Saídas
# ------------------------------------------------------------

ELF  := $(BUILD_DIR)/bios.elf
BIN  := $(BUILD_DIR)/bios.bin
HEX  := $(BUILD_DIR)/firmware.hex
DUMP := $(BUILD_DIR)/bios.dump
MAP  := $(BUILD_DIR)/bios.map

# ------------------------------------------------------------
# Flags
# ------------------------------------------------------------

CFLAGS += \
    -march=$(ARCH) \
    -mabi=$(ABI) \
    -O2 \
    -Wall \
    -Wextra \
    -ffreestanding \
    -fno-builtin \
    -fno-stack-protector \
    -nostdlib \
    -nostartfiles

LDFLAGS := \
    -T $(LDSCRIPT) \
    -nostdlib \
    -nostartfiles \
    -Wl,--gc-sections \
    -Wl,-Map=$(MAP)

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------

.PHONY: all clean qemu debug dump size readelf hex copyhex

all: $(ELF) $(BIN) $(HEX) $(DUMP)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(ELF): $(SRCS) $(LDSCRIPT) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SRCS) $(LDFLAGS) -o $@
	$(SIZE) $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(BIN) $(TOOLS_DIR)/bin2hex.py
	$(PYTHON) $(TOOLS_DIR)/bin2hex.py $< $@

$(DUMP): $(ELF)
	$(OBJDUMP) -D $< > $@

hex: $(HEX)

# Copia o firmware.hex para a raiz do projeto, se o Gowin/Verilator
# estiver procurando "firmware.hex" no diretório atual.
copyhex: $(HEX)
	cp $(HEX) firmware.hex

qemu: TARGET=qemu
qemu: $(ELF)
	qemu-system-riscv32 \
		-machine virt \
		-nographic \
		-bios none \
		-kernel $(ELF)

debug: TARGET=qemu
debug: $(ELF)
	qemu-system-riscv32 \
		-machine virt \
		-nographic \
		-bios none \
		-kernel $(ELF) \
		-S -s

dump: $(DUMP)
	less $(DUMP)

size: $(ELF)
	$(SIZE) $(ELF)

readelf: $(ELF)
	$(READELF) -a $(ELF)

clean:
	rm -rf build firmware.hex