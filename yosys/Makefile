# Configurações de caminhos
SRC_DIR  = ../verilog
SRC_FILES = $(wildcard $(SRC_DIR)/*.v) $(wildcard $(SRC_DIR)/*.sv) ../src/gowin_rpll/gowin_rpll.v
FIRMWARE = ../firmware/build/tang20k/firmware.hex
DEVICE = GW2A-LV18PG256C8/I7
FAMILY = GW2A-18C
NETLIST      = tang20k-primer-synth.json
PNRNETLIST    = tang20k-primer.json
BITSTREAM    = tang20k-primer.fs
CST = ../gowin/retro-riscv.cst

# Alvo principal
all: synth 

synth: $(BITSTREAM)

$(BITSTREAM): $(PNRNETLIST)
	@echo "Gerando bitstream: $(BITSTREAM)"
	gowin_pack -c -d $(DEVICE) -o $(BITSTREAM) $(PNRNETLIST)

$(PNRNETLIST): $(NETLIST)
	@echo "Realizando Place and Route: $(PNRNETLIST)"
	nextpnr-himbaechel --timing-allow-fail -r --json $(NETLIST) --write $(PNRNETLIST) --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST)


$(NETLIST): $(SRC_FILES) $(FIRMWARE)
	@echo "Sintetizando os arquivos: $(SRC_FILES)"
	yosys -D FIRMWARE_FILE_PATH=\"$(FIRMWARE)\" \
	      -p "read_verilog -sv $(SRC_FILES); script synth.ys ; synth_gowin -json $(NETLIST) -family gw2a ; stat"

clean:
	rm -f $(NETLIST) $(PNRNETLIST) $(BITSTREAM)

.PHONY: all synth clean