`default_nettype none

// ============================================================
// ROM síncrona inferível como block RAM / BSRAM
// - Endereço em bytes
// - Leitura de 32 bits alinhada
// - Conteúdo carregado por $readmemh
// ============================================================

module memory_rom #(
    parameter integer ADDR_WIDTH = 12,       // bits de endereço em palavras
    parameter         INIT_FILE  = "rom.hex"
) (
    input  wire        clk,

    input  wire        valid,
    input  wire [31:0] addr,

    output reg  [31:0] rdata,
    output reg         ready
);

    localparam integer WORDS = 1 << ADDR_WIDTH;

    // Em geral isso infere BSRAM/BRAM.
    // Se o Gowin reclamar, podemos ajustar o atributo depois.
    (* ram_style = "block" *)
    reg [31:0] mem [0:WORDS-1];

    wire [ADDR_WIDTH-1:0] word_addr;
    assign word_addr = addr[ADDR_WIDTH+1:2];   // addr em bytes -> índice em words

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        ready <= valid;

        if (valid) begin
            rdata <= mem[word_addr];
        end
    end

endmodule


// ============================================================
// RAM síncrona inferível como block RAM / BSRAM
// - Endereço em bytes
// - Palavra de 32 bits
// - Escrita por byte-enable via wstrb[3:0]
// - wstrb == 0 significa leitura
// ============================================================

module memory_ram #(
    parameter integer ADDR_WIDTH = 12,       // bits de endereço em palavras
    parameter         INIT_FILE  = ""
) (
    input  wire        clk,

    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,

    output reg  [31:0] rdata,
    output reg         ready
);

    localparam integer WORDS = 1 << ADDR_WIDTH;

    (* ram_style = "block" *)
    reg [31:0] mem [0:WORDS-1];

    wire [ADDR_WIDTH-1:0] word_addr;
    assign word_addr = addr[ADDR_WIDTH+1:2];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        ready <= valid;

        if (valid) begin
            // Leitura síncrona
            rdata <= mem[word_addr];

            // Escrita com byte-enable
            if (wstrb[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[word_addr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
        end
    end

endmodule


// ============================================================
// Mapa de memória simples
//
// Exemplo:
//   ROM: 0x0000_0000 - 0x0000_3FFF  16 KiB
//   RAM: 0x0001_0000 - 0x0001_FFFF  64 KiB
//
// Interface compatível com PicoRV32:
//   mem_valid
//   mem_addr
//   mem_wdata
//   mem_wstrb
//   mem_rdata
//   mem_ready
// ============================================================

module memory #(
    parameter integer ROM_ADDR_WIDTH = 12,   // 2^12 words = 16 KiB
    parameter integer RAM_ADDR_WIDTH = 14,   // 2^14 words = 64 KiB

    parameter [31:0]  ROM_BASE       = 32'h0000_0000,
    parameter [31:0]  ROM_SIZE       = 32'h0000_4000,

    parameter [31:0]  RAM_BASE       = 32'h0001_0000,
    parameter [31:0]  RAM_SIZE       = 32'h0001_0000,

    parameter         ROM_INIT_FILE  = "rom.hex",
    parameter         RAM_INIT_FILE  = ""
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg  [31:0] mem_rdata,
    output reg         mem_ready
);

    wire rom_sel;
    wire ram_sel;

    assign rom_sel =
        mem_valid &&
        mem_addr >= ROM_BASE &&
        mem_addr <  ROM_BASE + ROM_SIZE;

    assign ram_sel =
        mem_valid &&
        mem_addr >= RAM_BASE &&
        mem_addr <  RAM_BASE + RAM_SIZE;

    wire        rom_valid;
    wire [31:0] rom_addr;
    wire [31:0] rom_rdata;
    wire        rom_ready;

    assign rom_valid = rom_sel;
    assign rom_addr  = mem_addr - ROM_BASE;

    memory_rom #(
        .ADDR_WIDTH(ROM_ADDR_WIDTH),
        .INIT_FILE(ROM_INIT_FILE)
    ) u_rom (
        .clk   (clk),
        .valid (rom_valid),
        .addr  (rom_addr),
        .rdata (rom_rdata),
        .ready (rom_ready)
    );

    wire        ram_valid;
    wire [31:0] ram_addr;
    wire [31:0] ram_rdata;
    wire        ram_ready;

    assign ram_valid = ram_sel;
    assign ram_addr  = mem_addr - RAM_BASE;

    memory_ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .INIT_FILE(RAM_INIT_FILE)
    ) u_ram (
        .clk   (clk),
        .valid (ram_valid),
        .addr  (ram_addr),
        .wdata (mem_wdata),
        .wstrb (mem_wstrb),
        .rdata (ram_rdata),
        .ready (ram_ready)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0000_0000;
        end else begin
            mem_ready <= 1'b0;

            if (rom_ready) begin
                mem_ready <= 1'b1;
                mem_rdata <= rom_rdata;
            end else if (ram_ready) begin
                mem_ready <= 1'b1;
                mem_rdata <= ram_rdata;
            end else if (mem_valid && !rom_sel && !ram_sel) begin
                // Acesso fora do mapa.
                // Para o PicoRV32, é melhor responder do que travar o barramento.
                mem_ready <= 1'b1;
                mem_rdata <= 32'hDEAD_BEEF;
            end
        end
    end

endmodule

`default_nettype wire