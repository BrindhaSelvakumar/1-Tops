`timescale 1ns/1ps

module ahb_dbus_decoder (
    input  wire [31:0] HADDR,

    output reg         HSEL_DSRAM,
    output reg         HSEL_APB,
    output reg         HSEL_NOMAP
);

    // ============================================================
    // ADDRESS REGIONS (NON-OVERLAPPING ✅)
    // ============================================================

    // DSRAM: 0x2000_0000 - 0x2000_FFFF (64KB)
    localparam [31:0] DSRAM_BASE = 32'h2000_0000;
    localparam [31:0] DSRAM_MASK = 32'hFFFF_0000;

    // APB: 0x4000_0000 - 0x40FF_FFFF (16MB)
    localparam [31:0] APB_BASE   = 32'h4000_0000;
    localparam [31:0] APB_MASK   = 32'hFF00_0000;

    always @(*) begin
        // Default (safe state)
        HSEL_DSRAM = 1'b0;
        HSEL_APB   = 1'b0;
        HSEL_NOMAP = 1'b0;

        // ========================================================
        // DSRAM REGION
        // ========================================================
        if ((HADDR & DSRAM_MASK) == DSRAM_BASE) begin
            HSEL_DSRAM = 1'b1;
        end

        // ========================================================
        // APB REGION
        // ========================================================
        else if ((HADDR & APB_MASK) == APB_BASE) begin
            HSEL_APB = 1'b1;
        end

        // ========================================================
        // INVALID ACCESS
        // ========================================================
        else begin
            HSEL_NOMAP = 1'b1;
        end
    end

endmodule
