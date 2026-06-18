`timescale 1ns/1ps
module ahb_decoder (
    input  wire [31:0] HADDR,
    output reg         HSEL_ROM,
    output reg         HSEL_ISRAM,
    output reg         HSEL_NOMAP
);

    always @(*) begin
        HSEL_ROM   = 1'b0;
        HSEL_ISRAM = 1'b0;
        HSEL_NOMAP = 1'b0;

        if (HADDR[31:28] == 4'h0)
            HSEL_ROM = 1'b1;
        else if (HADDR[31:28] == 4'h1)
            HSEL_ISRAM = 1'b1;
        else
            HSEL_NOMAP = 1'b1;
    end

endmodule
