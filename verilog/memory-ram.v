`default_nettype none

// ============================================================
// RAM simples para PicoRV32 / Verilator / BRAM inference
//
// Protocolo:
//   - valid fica alto enquanto o master espera resposta.
//   - ready pulsa 1 ciclo quando a transação foi aceita.
//   - endereço recebido é relativo à base da RAM, em bytes.
//   - wstrb == 0 significa leitura.
// ============================================================

module memory_ram #(
    parameter integer ADDR_WIDTH = 11,          // palavras de 32 bits
    parameter         INIT_FILE  = ""
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,

    output reg  [31:0] rdata,
    output reg         ready
);

    localparam integer WORDS = 1 << ADDR_WIDTH;

    (* ram_style = "block" *) reg [31:0] ram [0:WORDS-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            ready <= 1'b0;
            rdata <= 32'h0000_0000;
        end else begin
            ready <= 1'b0;

            if (valid && !ready) begin
                ready <= 1'b1;

                // Read-before-write, igual à memory_fixed.v.
                rdata <= ram[word_addr];

                if (wstrb[0]) ram[word_addr][ 7: 0] <= wdata[ 7: 0];
                if (wstrb[1]) ram[word_addr][15: 8] <= wdata[15: 8];
                if (wstrb[2]) ram[word_addr][23:16] <= wdata[23:16];
                if (wstrb[3]) ram[word_addr][31:24] <= wdata[31:24];
            end
        end
    end

endmodule

`default_nettype wire
