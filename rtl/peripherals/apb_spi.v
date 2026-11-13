`timescale 1ns / 1ps

module apb_spi (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [11:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    input  wire        spi_sclk,
    input  wire        spi_mosi,
    output reg         spi_miso,
    input  wire        spi_ss_n
);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // Sync external SPI pins into PCLK domain
    reg [2:0] sck_sync, cs_sync, mosi_sync;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            sck_sync  <= 3'b000;
            cs_sync   <= 3'b111;
            mosi_sync <= 3'b000;
        end else begin
            sck_sync  <= {sck_sync[1:0], spi_sclk};
            cs_sync   <= {cs_sync[1:0], spi_ss_n};
            mosi_sync <= {mosi_sync[1:0], spi_mosi};
        end
    end

    wire sck_rising  = (sck_sync[2:1] == 2'b01);
    wire sck_falling = (sck_sync[2:1] == 2'b10);
    wire cs_active   = ~cs_sync[2];

    // Registers
    reg [31:0] rx_shift_reg;
    reg [31:0] tx_shift_reg;
    reg [31:0] stored_data;   // last received 32-bit word
    reg [31:0] tx_data_reg;   // next transmit word
    reg [5:0]  bit_count;

    // APB clear flag — set by APB write, consumed by SPI block
    reg apb_clear_stored;

    // APB: write tx_data, set clear flag
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data_reg      <= 32'h0;
            apb_clear_stored <= 1'b0;
        end else begin
            apb_clear_stored <= 1'b0; // default: de-assert

            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[5:0])
                    6'h00: tx_data_reg      <= PWDATA;     // preload MISO data
                    6'h04: apb_clear_stored <= 1'b1;       // request clear
                    default: ;
                endcase
            end
        end
    end

    // APB: combinational read (matches other peripherals)
    always @(*) begin
        case (PADDR[5:0])
            6'h00:   PRDATA = stored_data;
            6'h04:   PRDATA = tx_data_reg;
            default: PRDATA = 32'h0;
        endcase
    end

    // SPI slave transfer (32-bit) — single driver for stored_data
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            bit_count    <= 6'd0;
            rx_shift_reg <= 32'h0;
            tx_shift_reg <= 32'h0;
            stored_data  <= 32'h0;
            spi_miso     <= 1'b0;
        end else begin
            // APB clear takes priority when SPI is idle
            if (apb_clear_stored)
                stored_data <= 32'h0;

            if (!cs_active) begin
                bit_count    <= 6'd0;
                tx_shift_reg <= tx_data_reg;
                spi_miso     <= tx_data_reg[31];
            end else begin
                // master samples MISO on falling edge, so update MISO on rising edge
                if (sck_rising) begin
                    spi_miso     <= tx_shift_reg[31];
                    tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};
                end

                // sample MOSI on falling edge (stable after master rising-edge update)
                if (sck_falling) begin
                    rx_shift_reg <= {rx_shift_reg[30:0], mosi_sync[2]};
                    bit_count    <= bit_count + 6'd1;

                    if (bit_count == 6'd31)
                        stored_data <= {rx_shift_reg[30:0], mosi_sync[2]};
                end
            end
        end
    end

endmodule
