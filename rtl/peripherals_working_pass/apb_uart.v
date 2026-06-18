
`timescale 1ns / 1ps

module apb_uart (
input  wire        PCLK,
input  wire PRESETn,
input  wire        PSEL,
input  wire        PENABLE,
input  wire        PWRITE,
input  wire [11:0] PADDR,
input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    // Serial Interface
input  wire uart_rxd,
    output wire        uart_txd
);

    // Register Map Offsets
localparam ADDR_DATA   = 12'h000; // [R] RX pop data, [W] TX push data
localparam ADDR_STATUS = 12'h004; // [R] FIFO/TX status

    // Internal Signals
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;
    reg        tx_en;
    reg [7:0]  tx_data;
    wire [7:0] rx_fifo_rdata;
    wire [7:0] tx_fifo_rdata;
    wire       rx_fifo_full, rx_fifo_empty;
    wire       tx_fifo_full, tx_fifo_empty;
    reg        rx_fifo_rd_en;
    reg        tx_fifo_rd_en;
    wire       rx_fifo_wr_en;
    reg        tx_fifo_wr_en;
    reg [7:0]  tx_fifo_wdata;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    assign rx_fifo_wr_en = rx_valid;

    // --- UART Instance: Receiver ---
uart_rx #(.CLK_HZ(50_000_000), .BIT_RATE(9600)) i_rx (
.clk(PCLK), .resetn(PRESETn),
.uart_rxd(uart_rxd), .uart_rx_en(1'b1),
.uart_rx_valid(rx_valid), .uart_rx_data(rx_data),
.uart_rx_break()
    );

    // --- UART Instance: Transmitter ---
uart_tx #(.CLK_HZ(50_000_000), .BIT_RATE(9600)) i_tx (
.clk(PCLK), .resetn(PRESETn),
.uart_txd(uart_txd), .uart_tx_en(tx_en),
.uart_tx_busy(tx_busy), .uart_tx_data(tx_data)
    );

    sync_fifo #(.WIDTH(8), .DEPTH(16)) u_rx_fifo (
        .clk    (PCLK),
        .rst_n  (PRESETn),
        .wr_en  (rx_fifo_wr_en),
        .wr_data(rx_data),
        .rd_en  (rx_fifo_rd_en),
        .rd_data(rx_fifo_rdata),
        .full   (rx_fifo_full),
        .empty  (rx_fifo_empty)
    );

    sync_fifo #(.WIDTH(8), .DEPTH(16)) u_tx_fifo (
        .clk    (PCLK),
        .rst_n  (PRESETn),
        .wr_en  (tx_fifo_wr_en),
        .wr_data(tx_fifo_wdata),
        .rd_en  (tx_fifo_rd_en),
        .rd_data(tx_fifo_rdata),
        .full   (tx_fifo_full),
        .empty  (tx_fifo_empty)
    );

    // --- Register / FIFO Control ---
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
tx_en <= 1'b0;
tx_data <= 8'h0;
rx_fifo_rd_en <= 1'b0;
tx_fifo_rd_en <= 1'b0;
tx_fifo_wr_en <= 1'b0;
tx_fifo_wdata <= 8'h0;
        end else begin
tx_en <= 1'b0; // Pulse tx_en for only one cycle
rx_fifo_rd_en <= 1'b0;
tx_fifo_rd_en <= 1'b0;
tx_fifo_wr_en <= 1'b0;

            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    // Push TX byte into FIFO
                    if ((PADDR == ADDR_DATA) && !tx_fifo_full) begin
tx_fifo_wdata <= PWDATA[7:0];
tx_fifo_wr_en <= 1'b1;
                    end
                end else begin
                    // Pop one RX byte on DATA register read
                    if ((PADDR == ADDR_DATA) && !rx_fifo_empty) begin
rx_fifo_rd_en <= 1'b1;
                    end
                end
            end

            // Feed TX shifter from TX FIFO when available
            if (!tx_busy && !tx_fifo_empty) begin
tx_data <= tx_fifo_rdata;
tx_en   <= 1'b1;
tx_fifo_rd_en <= 1'b1;
            end
        end
    end

    // --- Read Interface ---
    always @(*) begin
        case (PADDR)
            ADDR_DATA:   PRDATA = rx_fifo_empty ? 32'h0 : {24'h0, rx_fifo_rdata};
            // [4]=tx_fifo_full, [3]=tx_fifo_empty, [2]=rx_fifo_full, [1]=rx_fifo_empty, [0]=tx_busy
            ADDR_STATUS: PRDATA = {27'h0, tx_fifo_full, tx_fifo_empty, rx_fifo_full, rx_fifo_empty, tx_busy};
            default:     PRDATA = 32'h0;
endcase
    end

endmodule
