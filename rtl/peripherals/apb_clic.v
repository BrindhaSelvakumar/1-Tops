`timescale 1ns/1ps
module apb_clic #(
    parameter integer NIRQ = 6
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

    // Interrupt sources (vector)
    input  wire [NIRQ-1:0]  irq_src_i,

    // Output
    output wire             irq_o,
    output wire [2:0]       irq_id_o
);

    reg [NIRQ-1:0] ie_reg, ie_n;
    reg [NIRQ-1:0] ip_reg, ip_n;

    reg [2:0] top_id;
    reg       top_vld;

    integer i;

    wire apb_wr = PSEL && PENABLE && PWRITE;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // ---------------- Next-state ----------------
    always @(*) begin
        ie_n = ie_reg;

        // latch interrupts (level-latched pending)
        ip_n = ip_reg | irq_src_i;

        if (apb_wr) begin
            case (PADDR[5:2])
                4'h0: ie_n = PWDATA[NIRQ-1:0];               // IE
                4'h2: ip_n = ip_n | PWDATA[NIRQ-1:0];        // IP_SET
                4'h3: ip_n = ip_n & ~PWDATA[NIRQ-1:0];       // IP_CLR
                4'h5: begin                                   // COMPLETE
                    if (PWDATA[2:0] < NIRQ)
                        ip_n[PWDATA[2:0]] = 1'b0;
                end
                default: ;
            endcase
        end
    end

    // ---------------- Registers ----------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ie_reg <= '0;
            ip_reg <= '0;
        end else begin
            ie_reg <= ie_n;
            ip_reg <= ip_n;
        end
    end

    // ---------------- Priority (highest index wins) ----------------
    always @(*) begin
        top_id  = 3'd0;
        top_vld = 1'b0;

        for (i = 0; i < NIRQ; i = i + 1) begin
            if (ip_reg[i] && ie_reg[i]) begin
                top_vld = 1'b1;
                top_id  = i[2:0];
            end
        end
    end

    assign irq_o    = top_vld;
    assign irq_id_o = top_id;

    // ---------------- Read ----------------
    always @(*) begin
        PRDATA = 32'h0;
        case (PADDR[5:2])
            4'h0: PRDATA[NIRQ-1:0] = ie_reg;                 // IE
            4'h1: PRDATA[NIRQ-1:0] = ip_reg;                 // IP
            4'h4: PRDATA[2:0]      = top_vld ? top_id : 3'd0; // CLAIM
            default: PRDATA         = 32'h0;
        endcase
    end

endmodule
