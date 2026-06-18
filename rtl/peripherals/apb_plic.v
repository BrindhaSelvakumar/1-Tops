`timescale 1ns/1ps

module apb_plic #(
    parameter integer NIRQ = 2
)(
    input  wire             PCLK,
    input  wire             PRESETn,

    // APB
    input  wire             PSEL,
    input  wire             PENABLE,
    input  wire             PWRITE,
    input  wire [11:0]      PADDR,
    input  wire [31:0]      PWDATA,
    output reg  [31:0]      PRDATA,
    output wire             PREADY,
    output wire             PSLVERR,

    // External IRQ sources
    input  wire [NIRQ-1:0]  ext_irq_i,

    // CPU-side summary IRQ + ID
    output wire             irq_o,
    output wire [1:0]       irq_id_o
);

    localparam integer ID_W = (NIRQ <= 2) ? 1 : $clog2(NIRQ);

    reg [NIRQ-1:0] ie_reg, ie_n;
    reg [NIRQ-1:0] ip_reg, ip_n;

    // 2FF synchronizer
    reg [NIRQ-1:0] ext_ff1, ext_ff2;

    wire apb_wr = PSEL && PENABLE && PWRITE;
    wire [NIRQ-1:0] active = ip_reg & ie_reg;

    reg [ID_W-1:0] claim_id;
    integer i;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // sync async IRQ pads
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ext_ff1 <= {NIRQ{1'b0}};
            ext_ff2 <= {NIRQ{1'b0}};
        end else begin
            ext_ff1 <= ext_irq_i;
            ext_ff2 <= ext_ff1;
        end
    end

    // highest index wins
    always @(*) begin
        claim_id = {ID_W{1'b0}};
        for (i = 0; i < NIRQ; i = i + 1) begin
            if (active[i]) claim_id = i[ID_W-1:0];
        end
    end

    // next-state
    always @(*) begin
        ie_n = ie_reg;
        ip_n = ip_reg | ext_ff2; // latch pending as level-detected

        if (apb_wr) begin
            case (PADDR[5:2])
                4'h0: ie_n = PWDATA[NIRQ-1:0];               // IE
                4'h2: ip_n = ip_n & ~PWDATA[NIRQ-1:0];       // IP_CLR (W1C)
                4'h3: begin                                   // COMPLETE
                    if (PWDATA[ID_W-1:0] < NIRQ)
                        ip_n[PWDATA[ID_W-1:0]] = 1'b0;
                end
                default: ;
            endcase
        end
    end

    // registers
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ie_reg <= {NIRQ{1'b0}};
            ip_reg <= {NIRQ{1'b0}};
        end else begin
            ie_reg <= ie_n;
            ip_reg <= ip_n;
        end
    end

    assign irq_o    = |active;
    assign irq_id_o = {{(2-ID_W){1'b0}}, claim_id};

    // read map: 0x00 IE, 0x04 IP, 0x08 IP_CLR, 0x0C CLAIM
    always @(*) begin
        PRDATA = 32'h0;
        case (PADDR[5:2])
            4'h0: PRDATA[NIRQ-1:0] = ie_reg;
            4'h1: PRDATA[NIRQ-1:0] = ip_reg;
            4'h3: PRDATA[ID_W-1:0] = claim_id;
            default: PRDATA = 32'h0;
        endcase
    end

endmodule
