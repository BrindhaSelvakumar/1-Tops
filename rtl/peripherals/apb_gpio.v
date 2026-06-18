`timescale 1ns/1ps

module apb_gpio (
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
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_dir
);

    reg [31:0] dir_reg;
    reg [31:0] out_reg;

    wire apb_wr = PSEL && PENABLE && PWRITE;
    wire apb_rd = PSEL && PENABLE && !PWRITE;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    assign gpio_dir = dir_reg;
    assign gpio_out = out_reg;  // no masking; software controls direction separately

    // 0x000 : DIR
    // 0x004 : OUT
    // 0x008 : IN (RO)
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            dir_reg <= 32'h0000_0000;
            out_reg <= 32'h0000_0000;
        end else if (apb_wr) begin
            case (PADDR[5:2])
                4'h0: dir_reg <= PWDATA;
                4'h1: out_reg <= PWDATA;
                default: ;
            endcase
        end
    end

    always @(*) begin
        PRDATA = 32'h0000_0000;
        if (apb_rd) begin
            case (PADDR[5:2])
                4'h0: PRDATA = dir_reg;
                4'h1: PRDATA = out_reg;
                4'h2: PRDATA = gpio_in;
                default: PRDATA = 32'h0000_0000;
            endcase
        end
    end

endmodule

