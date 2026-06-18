`timescale 1ns / 1ps

module apb_timer#(
    parameter APB_ADDR_WIDTH = 12,
    parameter TIMER_CNT = 2
) (
input  wire PCLK,    // Renamed from HCLK for APB consistency
input  wire PRESETn, // Renamed from HRESETn for APB consistency
input  wire [APB_ADDR_WIDTH-1:0] PADDR,
input  wire [31:0] PWDATA,
input  wire        PWRITE,
input  wire        PSEL,
input  wire        PENABLE,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,
    output wire [(TIMER_CNT * 2) - 1:0] irq_o
);

    wire [TIMER_CNT-1:0] psel_int;
    wire [TIMER_CNT-1:0] pready_bus;
    wire [TIMER_CNT-1:0] pslverr_bus;
    wire [(TIMER_CNT * 32) - 1:0] prdata_flat;

    // FIX: Using PADDR[11] instead of PADDR[5] to split timers.
    // This ensures offsets 0x00, 0x04, 0x08 all hit TIMER 0.
    assign psel_int[0] = PSEL && (PADDR[11] == 1'b0);
    assign psel_int[1] = PSEL && (PADDR[11] == 1'b1);

    // Mux outputs from the active timer core
    assign PREADY  = (psel_int[1]) ?pready_bus[1] :pready_bus[0];
    assign PSLVERR = (psel_int[1]) ?pslverr_bus[1] :pslverr_bus[0];

    always @(*) begin
        if (psel_int[1])
            PRDATA = prdata_flat[63:32];
        else if (psel_int[0])
            PRDATA = prdata_flat[31:0];
        else
            PRDATA = 32'h0;
    end

genvar k;
    generate
for(k = 0; k < TIMER_CNT; k = k + 1) begin : TIMER_GEN
timer_core #(.APB_ADDR_WIDTH(APB_ADDR_WIDTH)) timer_inst (
.HCLK(PCLK), .HRESETn(PRESETn), .PADDR(PADDR), .PWDATA(PWDATA),
.PWRITE(PWRITE), .PSEL(psel_int[k]), .PENABLE(PENABLE),
.PRDATA(prdata_flat[k*32 +: 32]), .PREADY(pready_bus[k]),
.PSLVERR(pslverr_bus[k]), .irq_o(irq_o[2*k+1 : 2*k])
            );
        end
endgenerate
endmodule
