module top (
    input  logic clk,
    output logic uart_txd
);

    // ------------------------------------------------------------
    // Reset interno simples por contador
    // ------------------------------------------------------------

    logic [7:0] reset_cnt = 8'h00;
    logic resetn;

    always_ff @(posedge clk) begin
        if (reset_cnt != 8'hff)
            reset_cnt <= reset_cnt + 1'b1;
    end

    assign resetn = (reset_cnt == 8'hff);

    // ------------------------------------------------------------
    // Interface PicoRV32
    // ------------------------------------------------------------

    logic        mem_valid;
    logic        mem_instr;
    logic        mem_ready;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic [31:0] mem_rdata;


    // ------------------------------------------------------------
    // Sinais UART
    // ------------------------------------------------------------

    logic       uart_tx_busy;
    logic       uart_enable;
    logic [7:0] uart_data;


    // ------------------------------------------------------------
    // Decodificação MMIO para UART 
    // ------------------------------------------------------------

    localparam logic [31:0] UART_TX_ADDR = 32'h1000_0000; // UART

    logic uart_select;
    logic uart_write;
    logic uart_idle;

    assign uart_select = mem_valid && (mem_addr == UART_TX_ADDR);
    assign uart_write  = uart_select && (mem_wstrb != 4'b0000);
    assign uart_idle   = !uart_tx_busy;

    assign uart_data   = mem_wdata[7:0];
    assign uart_enable = uart_write && mem_wstrb[0] && uart_idle;

    // ------------------------------------------------------------
    // Decodificação MMIO para pseudo-device Verilator 
    // ------------------------------------------------------------
    localparam logic [31:0] SIM_EXIT_ADDR = 32'h1000_00fc; // pseudo-device para o verilator

    logic sim_exit_select;
    logic sim_exit_write;

    `ifdef VERILATOR
        assign sim_exit_select = mem_valid && (mem_addr == SIM_EXIT_ADDR);
        assign sim_exit_write  = sim_exit_select && (mem_wstrb != 4'b0000);
    `else
        assign sim_exit_select = 1'b0;
        assign sim_exit_write  = 1'b0;
    `endif

    // ------------------------------------------------------------
    // Mapa de memória
    // ------------------------------------------------------------

    localparam logic [31:0] ROM_BASE = 32'h0000_0000;
    localparam logic [31:0] ROM_SIZE = 32'h0000_4000;  // 16 KiB

    localparam logic [31:0] RAM_BASE = 32'h0001_0000;
    localparam logic [31:0] RAM_SIZE = 32'h0000_2000;  // 8 KiB

    logic rom_select;
    logic ram_select;
    logic unmapped_select;

    assign rom_select =
        mem_valid &&
        !uart_select &&
        !sim_exit_select &&
        (mem_addr >= ROM_BASE) &&
        (mem_addr <  ROM_BASE + ROM_SIZE);

    assign ram_select =
        mem_valid &&
        !uart_select &&
        !sim_exit_select &&
        (mem_addr >= RAM_BASE) &&
        (mem_addr <  RAM_BASE + RAM_SIZE);

    assign unmapped_select =
        mem_valid &&
        !uart_select &&
        !sim_exit_select &&
        !rom_select &&
        !ram_select;


    // ------------------------------------------------------------
    // Sinais ROM
    // ------------------------------------------------------------

    logic        rom_ready;
    logic [31:0] rom_rdata;


    // ------------------------------------------------------------
    // Sinais RAM
    // ------------------------------------------------------------

    logic        ram_ready;
    logic [31:0] ram_rdata;


    // ------------------------------------------------------------
    // Sinais CPU
    // ------------------------------------------------------------


    logic        cpu_trap;

    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;

    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;

    assign pcpi_wr    = 1'b0;
    assign pcpi_rd    = 32'b0;
    assign pcpi_wait  = 1'b0;
    assign pcpi_ready = 1'b0;

    logic        mem_la_read;
    logic        mem_la_write;
    logic [31:0] mem_la_addr;
    logic [31:0] mem_la_wdata;
    logic [3:0]  mem_la_wstrb;

    logic [31:0] cpu_eoi;
    logic [31:0] cpu_irq;

    assign cpu_irq = 32'b0;

    logic        trace_valid;
    logic [35:0] trace_data;



    // ------------------------------------------------------------
    // CPU
    // ------------------------------------------------------------

    picorv32 #(
        .ENABLE_MUL      (1),
        .ENABLE_DIV      (1),
        .ENABLE_PCPI     (0),
        .COMPRESSED_ISA  (0),
        .PROGADDR_RESET  (32'h0000_0000),
        .STACKADDR       (32'h0001_2000)
    ) cpu (
        .clk        (clk),
        .resetn     (resetn),

        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),

        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready),

        .mem_la_read  (mem_la_read),
        .mem_la_write (mem_la_write),
        .mem_la_addr  (mem_la_addr),
        .mem_la_wdata (mem_la_wdata),
        .mem_la_wstrb (mem_la_wstrb),

        .irq        (cpu_irq),
        .eoi        (cpu_eoi),

        .trace_valid (trace_valid),
        .trace_data  (trace_data),

        .trap       (cpu_trap)
    );


    // ------------------------------------------------------------
    // ROM
    // ------------------------------------------------------------

    memory_rom #(
        .ADDR_WIDTH (12),                 // 2^12 words = 16 KiB
        .INIT_FILE  ("firmware.hex")
    ) rom0 (
        .clk    (clk),
        .resetn (resetn),

        .valid  (rom_select),
        .addr   (mem_addr - ROM_BASE),

        .rdata  (rom_rdata),
        .ready  (rom_ready)
    );


    // ------------------------------------------------------------
    // RAM
    // ------------------------------------------------------------

    memory_ram #(
        .ADDR_WIDTH (11),                 // 2^11 words = 8 KiB
        .INIT_FILE  ("")
    ) ram0 (
        .clk    (clk),
        .resetn (resetn),

        .valid  (ram_select),
        .addr   (mem_addr - RAM_BASE),
        .wdata  (mem_wdata),
        .wstrb  (mem_wstrb),

        .rdata  (ram_rdata),
        .ready  (ram_ready)
    );


    // ------------------------------------------------------------
    // UART TX
    // ------------------------------------------------------------

    `ifdef VERILATOR
        always_ff @(posedge clk) begin
            if (resetn && uart_enable) begin
                $write("%c", uart_data);
                $fflush();
            end
        end
    `endif

    uart_tx #(
        .CLK_HZ       (27_000_000),
        .BIT_RATE     (115_200),
        .PAYLOAD_BITS (8)
    ) uart0 (
        .clk          (clk),
        .resetn       (resetn),
        .uart_txd     (uart_txd),
        .uart_tx_busy (uart_tx_busy),
        .uart_tx_en   (uart_enable),
        .uart_tx_data (uart_data)
    );

    // ------------------------------------------------------------
    // simulation pseudo-device
    // ------------------------------------------------------------


    `ifdef VERILATOR
        always_ff @(posedge clk) begin
            if (resetn && sim_exit_write) begin
                if (mem_wdata == 32'h0000_0000) begin
                    $display("");
                    $display("[VERILATOR] SIM_EXIT: success");
                    $finish;
                end else begin
                    $display("");
                    $fatal(1, "[VERILATOR] SIM_EXIT: failure code 0x%08x", mem_wdata);
                end
            end
        end
    `endif



    // ------------------------------------------------------------
    // Mux de resposta do barramento
    // ------------------------------------------------------------

    always_comb begin
        mem_ready = 1'b0;
        mem_rdata = 32'h0000_0000;

        if (mem_valid) begin
            if (sim_exit_select) begin
                // Pseudo-device de simulação.
                // Responde imediatamente.
                mem_ready = 1'b1;
                mem_rdata = 32'h0000_0000;
            end else if (uart_select) begin
                // Leitura da UART retorna bit 0 = transmissor livre.
                // Escrita espera a UART ficar livre.
                mem_ready = (mem_wstrb == 4'b0000) || uart_idle;
                mem_rdata = {31'b0, uart_idle};
            end else if (rom_select) begin
                mem_ready = rom_ready;
                mem_rdata = rom_rdata;
            end else if (ram_select) begin
                mem_ready = ram_ready;
                mem_rdata = ram_rdata;
            end else begin
                // Acesso fora do mapa: responde para não travar a CPU.
                mem_ready = 1'b1;
                mem_rdata = 32'hDEAD_BEEF;
            end
        end
    end

endmodule