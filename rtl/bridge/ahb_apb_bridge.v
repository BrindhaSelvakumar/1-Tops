`timescale 1ns / 1ps

module ahb_apb_bridge (
    input  wire        HCLK,
    input  wire        HRESETn,

    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [31:0] HWDATA,
    input  wire        HREADYin,

    output reg  [31:0] HRDATA,
    output reg         HREADYout,
    output reg  [1:0]  HRESP,

    output reg  [31:0] PADDR,
    output reg         PWRITE,
    output reg  [31:0] PWDATA,
    output reg         PENABLE,
    output reg  [7:0]  PSEL,

    input  wire [31:0] PRDATA_P0, PRDATA_P1, PRDATA_P2, PRDATA_P3,
                       PRDATA_P4, PRDATA_P5, PRDATA_P6, PRDATA_P7,

    input  wire        PREADY_P0, PREADY_P1, PREADY_P2, PREADY_P3,
                       PREADY_P4, PREADY_P5, PREADY_P6, PREADY_P7,

    input  wire        PSLVERR_P0, PSLVERR_P1, PSLVERR_P2, PSLVERR_P3,
                       PSLVERR_P4, PSLVERR_P5, PSLVERR_P6, PSLVERR_P7
);

    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;
    localparam ST_ERROR  = 2'b11;

    reg [1:0] state, next_state;
    reg [31:0] addr_latched, wdata_latched;
    reg        write_latched;
    reg [7:0]  psel_latched;

    wire [7:0] psel_from_decoder;
    wire       ahb_valid;
    wire       transfer_done;

    assign ahb_valid = HSEL && HREADYin && HTRANS[1];

    assign transfer_done =
        (psel_latched[0] && PREADY_P0) ||
        (psel_latched[1] && PREADY_P1) ||
        (psel_latched[2] && PREADY_P2) ||
        (psel_latched[3] && PREADY_P3) ||
        (psel_latched[4] && PREADY_P4) ||
        (psel_latched[5] && PREADY_P5) ||
        (psel_latched[6] && PREADY_P6) ||
        (psel_latched[7] && PREADY_P7);

    apb_decoder APB_DEC (
        .PADDR(HADDR),
        .PSEL (psel_from_decoder)
    );

    // State + request capture
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state         <= ST_IDLE;
            psel_latched  <= 8'h00;
            addr_latched  <= 32'h0000_0000;
            wdata_latched <= 32'h0000_0000;
            write_latched <= 1'b0;
        end else begin
            state <= next_state;

            // Capture request in IDLE or immediately after ACCESS completion
            if ((state == ST_IDLE && ahb_valid) ||
                (state == ST_ACCESS && transfer_done && ahb_valid)) begin
                addr_latched  <= HADDR;
                write_latched <= HWRITE;
                psel_latched  <= psel_from_decoder;
                wdata_latched <= HWDATA;
            end
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (ahb_valid)
                    next_state = (|psel_from_decoder) ? ST_SETUP : ST_ERROR;
            end

            ST_SETUP: begin
                next_state = ST_ACCESS;
            end

            ST_ACCESS: begin
                if (transfer_done)
                    next_state = ahb_valid ? ST_SETUP : ST_IDLE;
            end

            ST_ERROR: begin
                next_state = ST_IDLE;
            end

            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // Output / response mux
    always @(*) begin
        PADDR   = addr_latched;
        PWRITE  = write_latched;
        PWDATA  = wdata_latched;
        PSEL    = (state == ST_IDLE) ? 8'h00 : psel_latched;
        PENABLE = (state == ST_ACCESS);

        HRDATA    = 32'h0000_0000;
        HRESP     = 2'b00;
        HREADYout = 1'b1;

        case (state)
            ST_IDLE: begin
                HREADYout = 1'b1;
            end

            ST_SETUP: begin
                HREADYout = 1'b0;
            end

            ST_ACCESS: begin
                if (psel_latched[0]) begin
                    HRDATA    = PRDATA_P0;
                    HREADYout = PREADY_P0;
                    HRESP     = PSLVERR_P0 ? 2'b01 : 2'b00;
                end else if (psel_latched[1]) begin
                    HRDATA    = PRDATA_P1;
                    HREADYout = PREADY_P1;
                    HRESP     = PSLVERR_P1 ? 2'b01 : 2'b00;
                end else if (psel_latched[2]) begin
                    HRDATA    = PRDATA_P2;
                    HREADYout = PREADY_P2;
                    HRESP     = PSLVERR_P2 ? 2'b01 : 2'b00;
                end else if (psel_latched[3]) begin
                    HRDATA    = PRDATA_P3;
                    HREADYout = PREADY_P3;
                    HRESP     = PSLVERR_P3 ? 2'b01 : 2'b00;
                end else if (psel_latched[4]) begin
                    HRDATA    = PRDATA_P4;
                    HREADYout = PREADY_P4;
                    HRESP     = PSLVERR_P4 ? 2'b01 : 2'b00;
                end else if (psel_latched[5]) begin
                    HRDATA    = PRDATA_P5;
                    HREADYout = PREADY_P5;
                    HRESP     = PSLVERR_P5 ? 2'b01 : 2'b00;
                end else if (psel_latched[6]) begin
                    HRDATA    = PRDATA_P6;
                    HREADYout = PREADY_P6;
                    HRESP     = PSLVERR_P6 ? 2'b01 : 2'b00;
                end else if (psel_latched[7]) begin
                    HRDATA    = PRDATA_P7;
                    HREADYout = PREADY_P7;
                    HRESP     = PSLVERR_P7 ? 2'b01 : 2'b00;
                end else begin
                    HRDATA    = 32'hDEAD_BEEF;
                    HREADYout = 1'b1;
                    HRESP     = 2'b01;
                end
            end

            ST_ERROR: begin
                HRDATA    = 32'hDEAD_BEEF;
                HREADYout = 1'b1;
                HRESP     = 2'b01;
            end
        endcase
    end

endmodule

