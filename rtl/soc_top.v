`timescale 1ns / 1ps

module soc_top #(
    parameter BOOT_MEM_FILE    = "boot.mem",
    parameter PROGRAM_MEM_FILE = "program.mem"
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire [1:0]  ext_irq_pad_i,

    input  wire [31:0] gpio_in_pad,
    output wire [31:0] gpio_out_pad,
    output wire [31:0] gpio_dir_pad,

    input  wire        uart_rxd,
    output wire        uart_txd,

    input  wire        spi_slave_sclk,
    input  wire        spi_slave_mosi,
    output wire        spi_slave_miso,
    input  wire        spi_slave_ss_n,

    output wire        spi_master_sclk,
    output wire        spi_master_mosi,
    input  wire        spi_master_miso,
    output wire        spi_master_ss_n,

    output wire [31:0] debug_pc,
    output wire [31:0] debug_alu_result
);

    // ================= IBUS =================
    wire [31:0] ihaddr, ihrdata;
    wire [1:0]  ihtrans;
    wire [2:0]  ihsize;
    wire        ihwrite;

    wire        ihready_bus;
    wire        ihready_rom, ihready_isram;
    wire [31:0] ihrdata_rom, ihrdata_isram;
    wire        ihsel_rom, ihsel_isram, ihsel_nomap;

    // ================= DBUS =================
    wire [31:0] dhaddr, dhwdata, dhrdata;
    wire [1:0]  dhtrans;
    wire [2:0]  dhsize;
    wire        dhwrite;

    wire        dhready_bus;
    wire        dhready_dsram, dhready_apb;
    wire [31:0] dhrdata_dsram, dhrdata_apb;

    wire        dhsel_dsram, dhsel_apb, dhsel_nomap;
    wire [1:0]  dhresp_bus;   // lint: intentionally read only for debug
    wire [1:0]  dhresp_apb;   // lint: intentionally read only for debug

    // ================= APB =================
    wire [31:0] paddr, pwdata;
    wire        pwrite, penable;
    wire [7:0]  psel;

    wire [31:0] prdata0, prdata1, prdata2, prdata3;
    wire [31:0] prdata4, prdata5, prdata6, prdata7;

    wire        pready0, pready1, pready2, pready3;
    wire        pready4, pready5, pready6, pready7;

    wire        pslverr0, pslverr1, pslverr2, pslverr3;
    wire        pslverr4, pslverr5, pslverr6, pslverr7;

    // ================= IRQ Wiring =================
    wire [3:0] timer_irq_bus;
    wire       clic_irq;
    wire [2:0] clic_irq_id;
    wire       plic_irq;
    wire [1:0] plic_irq_id;    // driven by PLIC; available for future use
    wire [5:0] clic_irq_src;
    wire [1:0] plic_ext_irq_i;
    assign plic_ext_irq_i = ext_irq_pad_i;
    wire       cpu_irq_ack;    // driven by CORE; available for future use
    // Intentionally unused outputs kept for debug/lint visibility
    wire [31:0] unused_isram_rdata, unused_dsram_rdata;

    // ================= CPU =================
    risc_core_top CORE (
        .clk(clk),
        .rst_n(rst_n),

        .IHADDR(ihaddr),
        .IHTRANS(ihtrans),
        .IHWRITE(ihwrite),
        .IHSIZE(ihsize),
        .IHRDATA(ihrdata),
        .IHREADY(ihready_bus),

        .DHADDR(dhaddr),
        .DHWDATA(dhwdata),
        .DHWRITE(dhwrite),
        .DHSIZE(dhsize),
        .DHTRANS(dhtrans),
        .DHRDATA(dhrdata),
        .DHREADY(dhready_bus),

        .irq_i(clic_irq),
        .irq_id_i(clic_irq_id),
        .irq_ack_o(cpu_irq_ack),

        .debug_pc(debug_pc),
        .debug_alu_result(debug_alu_result)
    );

    // ================= IBUS DECODER =================
    ahb_ibus_decoder IBUS_DEC (
        .HADDR(ihaddr),
        .HSEL_ROM(ihsel_rom),
        .HSEL_ISRAM(ihsel_isram),
        .HSEL_NOMAP(ihsel_nomap)
    );

    // ================= IBUS MUX =================
    ahb_slave_imux IBUS_MUX (
    .HCLK(clk),
    .HRESETn(rst_n),
    .HREADYin(ihready_bus),   // ✅ FIXED

    .HSEL_ROM(ihsel_rom),
    .HSEL_ISRAM(ihsel_isram),
    .HSEL_DSRAM(1'b0),
    .HSEL_APB(1'b0),
    .HSEL_NOMAP(ihsel_nomap & ihtrans[1]),

    .HRDATA_ROM(ihrdata_rom),
    .HRDATA_ISRAM(ihrdata_isram),
    .HRDATA_DSRAM(32'h0),
    .HRDATA_APB(32'h0),

    .HREADY_ROM(ihready_rom),
    .HREADY_ISRAM(ihready_isram),
    .HREADY_DSRAM(1'b1),
    .HREADY_APB(1'b1),

    .HRDATA(ihrdata),
    .HREADY(ihready_bus),
    .HRESP()
);

    // ================= BOOT ROM =================
    ahb_boot_rom #(
        .ROM_INIT_FILE(BOOT_MEM_FILE)
    ) BOOT_ROM (
        .HCLK(clk),
        .HRESETn(rst_n),
        .HSEL(ihsel_rom),
        .HADDR(ihaddr),
        .HTRANS(ihtrans),
        .HREADYin(ihready_bus),
        .HRDATA(ihrdata_rom),
        .HREADYout(ihready_rom),
        .HRESP()
    );

    // ================= ISRAM =================
    ahb_isram_slave #(
        .ADDR_WIDTH(14),
        .MEM_INIT_FILE(PROGRAM_MEM_FILE)
    ) ISRAM (
        .HCLK(clk),
        .HRESETn(rst_n),
        .HSEL(ihsel_isram),
        .HADDR(ihaddr),
        .HTRANS(ihtrans),
        .HWRITE(1'b0),          // IF path is read-only
        .HSIZE(ihsize),
        .HWDATA(32'h0),
        .HREADYin(ihready_bus),
        .HRDATA(ihrdata_isram),
        .HREADYout(ihready_isram),
        .HRESP(),
        .sram_rdata_out(unused_isram_rdata)
    );

    // ================= DBUS DECODER =================
    ahb_dbus_decoder DBUS_DEC (
        .HADDR(dhaddr),
        .HSEL_DSRAM(dhsel_dsram),
        .HSEL_APB(dhsel_apb),
        .HSEL_NOMAP(dhsel_nomap)
    );

    // ================= DBUS MUX =================
   ahb_slave_dmux DBUS_MUX (
    .HCLK(clk),
    .HRESETn(rst_n),
    .HREADYin(dhready_bus),   // ✅ FIXED

    .HSEL_ROM(1'b0),
    .HSEL_ISRAM(1'b0),
    .HSEL_DSRAM(dhsel_dsram),
    .HSEL_APB(dhsel_apb),
    .HSEL_NOMAP(dhsel_nomap & dhtrans[1]),

    .HRDATA_ROM(32'h0),
    .HRDATA_ISRAM(32'h0),
    .HRDATA_DSRAM(dhrdata_dsram),
    .HRDATA_APB(dhrdata_apb),

    .HREADY_ROM(1'b1),
    .HREADY_ISRAM(1'b1),
    .HREADY_DSRAM(dhready_dsram),
    .HREADY_APB(dhready_apb),

    .HRDATA(dhrdata),
    .HREADY(dhready_bus),
    .HRESP(dhresp_bus)
);

    // ================= DSRAM =================
    ahb_dsram_slave #(
        .ADDR_WIDTH(14),
        .MEM_INIT_FILE("")
    ) DSRAM (
        .HCLK(clk),
        .HRESETn(rst_n),
        .HSEL(dhsel_dsram),
        .HADDR(dhaddr),
        .HTRANS(dhtrans),
        .HWRITE(dhwrite),
        .HSIZE(dhsize),
        .HWDATA(dhwdata),
        .HREADYin(dhready_bus),
        .HRDATA(dhrdata_dsram),
        .HREADYout(dhready_dsram),
        .HRESP(),
        .sram_rdata_out(unused_dsram_rdata)
    );

    // ================= AHB → APB =================
    ahb_apb_bridge BRIDGE (
        .HCLK(clk),
        .HRESETn(rst_n),
        .HSEL(dhsel_apb),
        .HADDR(dhaddr),
        .HTRANS(dhtrans),
        .HWRITE(dhwrite),
        .HSIZE(dhsize),
        .HWDATA(dhwdata),
        .HREADYin(dhready_bus),
        .HRDATA(dhrdata_apb),
        .HREADYout(dhready_apb),
        .HRESP(dhresp_apb),

        .PADDR(paddr),
        .PWRITE(pwrite),
        .PWDATA(pwdata),
        .PENABLE(penable),
        .PSEL(psel),

        .PRDATA_P0(prdata0), .PRDATA_P1(prdata1),
        .PRDATA_P2(prdata2), .PRDATA_P3(prdata3),
        .PRDATA_P4(prdata4), .PRDATA_P5(prdata5),
        .PRDATA_P6(prdata6), .PRDATA_P7(prdata7),

        .PREADY_P0(pready0), .PREADY_P1(pready1),
        .PREADY_P2(pready2), .PREADY_P3(pready3),
        .PREADY_P4(pready4), .PREADY_P5(pready5),
        .PREADY_P6(pready6), .PREADY_P7(pready7),

        .PSLVERR_P0(pslverr0), .PSLVERR_P1(pslverr1),
        .PSLVERR_P2(pslverr2), .PSLVERR_P3(pslverr3),
        .PSLVERR_P4(pslverr4), .PSLVERR_P5(pslverr5),
        .PSLVERR_P6(pslverr6), .PSLVERR_P7(pslverr7)
    );

    // ================= APB PERIPHERALS =================
    apb_spi_master SPI_MASTER (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[0]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata0), .PREADY(pready0), .PSLVERR(pslverr0),
        .spi_sclk(spi_master_sclk),
        .spi_mosi(spi_master_mosi),
        .spi_miso(spi_master_miso),
        .spi_ss_n(spi_master_ss_n)
    );

    apb_uart UART0 (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[1]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata1), .PREADY(pready1), .PSLVERR(pslverr1),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd)
    );

    apb_uart UART1 (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[2]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata2), .PREADY(pready2), .PSLVERR(pslverr2),
        .uart_rxd(1'b1),
        .uart_txd()
    );

    // GPIO input synchronizer
    reg [31:0] gpio_sync1, gpio_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_sync1 <= 32'h0;
            gpio_sync2 <= 32'h0;
        end else begin
            gpio_sync1 <= gpio_in_pad;
            gpio_sync2 <= gpio_sync1;
        end
    end

    apb_gpio GPIO (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[3]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata3), .PREADY(pready3), .PSLVERR(pslverr3),
        .gpio_in(gpio_sync2),
        .gpio_out(gpio_out_pad),
        .gpio_dir(gpio_dir_pad)
    );

    apb_timer TIMER (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[4]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata4), .PREADY(pready4), .PSLVERR(pslverr4),
        .irq_o(timer_irq_bus)
    );

    // CLIC sources: [5]=0, [4]=PLIC summary, [3:0]=timer lines
    assign clic_irq_src = {1'b0, plic_irq, timer_irq_bus};

    apb_clic #(
        .NIRQ(6)
    ) CLIC (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[5]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata5), .PREADY(pready5), .PSLVERR(pslverr5),
        .irq_o(clic_irq),
        .irq_id_o(clic_irq_id),
        .irq_src_i(clic_irq_src)
    );

    apb_spi SPI_SLAVE (
        .PCLK(clk), .PRESETn(rst_n),
        .PSEL(psel[6]), .PENABLE(penable), .PWRITE(pwrite),
        .PADDR(paddr[11:0]), .PWDATA(pwdata),
        .PRDATA(prdata6), .PREADY(pready6), .PSLVERR(pslverr6),
        .spi_sclk(spi_slave_sclk),
        .spi_mosi(spi_slave_mosi),
        .spi_miso(spi_slave_miso),
        .spi_ss_n(spi_slave_ss_n)
    );

    apb_plic #(
        .NIRQ(2)
    ) PLIC (
        .PCLK(clk),
        .PRESETn(rst_n),
        .PSEL(psel[7]),          // fixed: dedicated APB slot
        .PENABLE(penable),
        .PWRITE(pwrite),
        .PADDR(paddr[11:0]),
        .PWDATA(pwdata),
        .PRDATA(prdata7),        // fixed
        .PREADY(pready7),        // fixed
        .PSLVERR(pslverr7),      // fixed
        .ext_irq_i(plic_ext_irq_i),
        .irq_o(plic_irq),
        .irq_id_o(plic_irq_id)
    );
  

endmodule



