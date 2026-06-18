`timescale 1ns / 1ps

module ahb_ibus_decoder (
input  wire [31:0] HADDR,
    output wire        HSEL_ROM,
    output wire        HSEL_ISRAM,
    output wire        HSEL_NOMAP
);
    // Boot ROM: 0x0000_0000 to 0x0000_0FFF (4KB)
    // We check [31:12] to ensure we only select the first 4KB
    assign HSEL_ROM   = (HADDR[31:12] == 20'h00000); 

    // ISRAM: 0x0001_0000 to 0x0001_FFFF (64KB)
    assign HSEL_ISRAM = (HADDR[31:16] == 16'h0001);

    assign HSEL_NOMAP = !(HSEL_ROM || HSEL_ISRAM);
endmodule
