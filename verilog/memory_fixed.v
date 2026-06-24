`default_nettype none

// ============================================================
// Memória simples para PicoRV32 / Verilator / BRAM inference
//
// Regra importante da interface PicoRV32:
//   - mem_ready deve pulsar como acknowledge da transação atual.
//   - não pode ficar alto "sobrando" para a próxima transação,
//     senão a CPU pode aceitar rdata antigo em fetches back-to-back.
//
// Esta versão usa o padrão canônico:
//   if (mem_valid && !mem_ready) begin
//       mem_ready <= 1;
//       mem_rdata <= ...;
//   end else begin
//       mem_ready <= 0;
//   end
// ============================================================

module memory #(
    parameter integer ROM_ADDR_WIDTH = 12,
    parameter integer RAM_ADDR_WIDTH = 14,

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

    localparam integer ROM_WORDS = 1 << ROM_ADDR_WIDTH;
    localparam integer RAM_WORDS = 1 << RAM_ADDR_WIDTH;

    (* ram_style = "block" *) reg [31:0] rom [0:ROM_WORDS-1];
    (* ram_style = "block" *) reg [31:0] ram [0:RAM_WORDS-1];

    wire rom_sel = (mem_addr >= ROM_BASE) && (mem_addr < ROM_BASE + ROM_SIZE);
    wire ram_sel = (mem_addr >= RAM_BASE) && (mem_addr < RAM_BASE + RAM_SIZE);

    wire [ROM_ADDR_WIDTH-1:0] rom_word_addr = (mem_addr - ROM_BASE) >> 2;
    wire [RAM_ADDR_WIDTH-1:0] ram_word_addr = (mem_addr - RAM_BASE) >> 2;

    initial begin
        if (ROM_INIT_FILE != "") begin
            $readmemh(ROM_INIT_FILE, rom);
        end
        if (RAM_INIT_FILE != "") begin
            $readmemh(RAM_INIT_FILE, ram);
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0000_0000;
        end else begin
            mem_ready <= 1'b0;

            if (mem_valid && !mem_ready) begin
                mem_ready <= 1'b1;

                if (rom_sel) begin
                    // ROM: ignora escrita; retorna palavra.
                    mem_rdata <= rom[rom_word_addr];
                end else if (ram_sel) begin
                    // RAM: read-before/write no mesmo ciclo para simplicidade.
                    mem_rdata <= ram[ram_word_addr];

                    if (mem_wstrb[0]) ram[ram_word_addr][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) ram[ram_word_addr][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) ram[ram_word_addr][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) ram[ram_word_addr][31:24] <= mem_wdata[31:24];
                end else begin
                    mem_rdata <= 32'hDEAD_BEEF;
                end
            end
        end
    end

endmodule

`default_nettype wire
