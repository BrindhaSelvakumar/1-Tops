`timescale 1ns / 1ps

module ahb_boot_rom #(
    parameter integer ROM_ADDR_WIDTH = 10,
    parameter         ROM_INIT_FILE  = ""
) (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HREADYin,
    output wire [31:0] HRDATA,
    output wire        HREADYout,
    output wire [1:0]  HRESP
);

    assign HREADYout = 1'b1;
    assign HRESP     = 2'b00;

    localparam integer ROM_DEPTH = (1 << ROM_ADDR_WIDTH);

    reg [31:0] rom_data [0:ROM_DEPTH-1];

    // 🔥 ADD THESE (IMPORTANT)
    reg [ROM_ADDR_WIDTH-1:0] addr_latched;
    reg                      valid_latched;

    integer i;

`ifndef SYNTHESIS
    initial begin
        for (i = 0; i < ROM_DEPTH; i = i + 1)
            rom_data[i] = 32'h0;

        if (ROM_INIT_FILE != "") begin
            $display("[ROM] Loading %s", ROM_INIT_FILE);
            $readmemh(ROM_INIT_FILE, rom_data);
        end
    end
`endif

    // ---------------------------
    // ADDRESS PHASE (latch)
    // ---------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_latched  <= 0;
            valid_latched <= 0;
        end 
        else if (HREADYin) begin
            valid_latched <= HSEL && HTRANS[1];

            if (HSEL && HTRANS[1]) begin
                addr_latched <= HADDR[ROM_ADDR_WIDTH+1:2];
            end
        end
    end

    // ---------------------------
    // DATA PHASE (Combinational in Data Phase)
    // ---------------------------
    assign HRDATA = rom_data[addr_latched];

endmodule
