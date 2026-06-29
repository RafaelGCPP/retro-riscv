`default_nettype none
`include "defines.vh"

// ============================================================
// ROM simples para PicoRV32 / Verilator / BRAM inference
//
// Protocolo:
//   - valid fica alto enquanto o master espera resposta.
//   - ready pulsa 1 ciclo quando rdata está válido.
//   - endereço recebido é relativo à base da ROM, em bytes.
// ============================================================

`ifndef FIRMWARE_FILE_PATH
`define FIRMWARE_FILE_PATH "firmware.hex"
`endif 

module memory_rom #(
    parameter integer ADDR_WIDTH = 12,          // palavras de 32 bits
    parameter         INIT_FILE  = `FIRMWARE_FILE_PATH
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        valid,
    input  wire [31:0] addr,

    output reg  [31:0] rdata,
    output reg         ready
);

    localparam integer WORDS = 1 << ADDR_WIDTH;

    (* ram_style = "block" *) reg [31:0] rom [0:WORDS-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, rom);
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
                rdata <= rom[word_addr];
            end
        end
    end

endmodule

`default_nettype wire
