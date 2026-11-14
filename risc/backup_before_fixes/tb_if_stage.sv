
`timescale 1ns/1ps
`include "defines.v"

`define NOP_INSTR 32'h00000013   // RISC-V NOP (ADDI x0, x0, 0)

module if_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Hazard / flush controls
    input  wire        stall_if,
    input  wire        flush_if,

    // Branch target
    input  wire [31:0] branch_target,

    // AHB-Lite instruction port
    output reg  [31:0] IHADDR,
    output reg  [ 1:0] IHTRANS,
    output wire        IHWRITE,
    output wire [ 2:0] IHSIZE,
    output wire [ 2:0] IHBURST,
    output wire [ 3:0] IHPROT,
    input  wire [31:0] IHRDATA,
    input  wire        IHREADY,
    input  wire        IHRESP,

    // IF/ID outputs
    output reg  [31:0] if_id_pc,
    output reg  [31:0] if_id_pc4,
    output reg  [31:0] if_id_instr
);

    //---------------------------------------------------------------------
    // AHB static signals
    //---------------------------------------------------------------------
    assign IHWRITE = 1'b0;
    assign IHSIZE  = 3'b010;
    assign IHBURST = 3'b000;
    assign IHPROT  = 4'b0011;

    //---------------------------------------------------------------------
    // Program Counter
    //---------------------------------------------------------------------
    reg [31:0] pc_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_r <= 32'h0000_0000;
        else if (flush_if)
            pc_r <= branch_target;
        else if (!stall_if && IHREADY)
            pc_r <= pc_r + 32'd4;
    end

    //---------------------------------------------------------------------
    // AHB Address Phase
    //---------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IHADDR  <= 32'h0;
            IHTRANS <= 2'b00;
        end else if (flush_if) begin
            IHADDR  <= branch_target;
            IHTRANS <= 2'b10;
        end else if (!stall_if) begin
            IHADDR  <= pc_r;
            IHTRANS <= 2'b10;
        end else begin
            IHTRANS <= 2'b00;
        end
    end

    //---------------------------------------------------------------------
    // Prefetch Buffer
    //---------------------------------------------------------------------
    localparam PFB_ENTRIES = 512;
    localparam IDX_W       = 9;

    reg [31:0] pfb_data  [0:PFB_ENTRIES-1];
    reg [31:0] pfb_tag   [0:PFB_ENTRIES-1];
    reg        pfb_valid [0:PFB_ENTRIES-1];

    integer j;

    initial begin
        for (j = 0; j < PFB_ENTRIES; j = j + 1) begin
            pfb_data [j] = 32'h0;
            pfb_tag  [j] = 32'hFFFF_FFFF;
            pfb_valid[j] = 1'b0;
        end
    end

    wire [IDX_W-1:0] pfb_idx = pc_r[IDX_W+1:2];
    wire             pfb_hit = pfb_valid[pfb_idx] &&
                               (pfb_tag[pfb_idx] == pc_r);

    // Fill buffer
    always @(posedge clk) begin
        if (flush_if) begin
            for (j = 0; j < PFB_ENTRIES; j = j + 1)
                pfb_valid[j] <= 1'b0;
        end else if (IHREADY && IHTRANS == 2'b10) begin
            pfb_data [pfb_idx] <= IHRDATA;
            pfb_tag  [pfb_idx] <= IHADDR;
            pfb_valid[pfb_idx] <= 1'b1;
        end
    end

    //---------------------------------------------------------------------
    // IF/ID Pipeline Register
    //---------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_pc    <= 32'h0;
            if_id_pc4   <= 32'h4;
            if_id_instr <= `NOP_INSTR;   // reset inserts NOP
        end else if (flush_if) begin
            if_id_pc    <= 32'h0;
            if_id_pc4   <= 32'h4;
            if_id_instr <= `NOP_INSTR;   // branch flush inserts NOP
        end else if (!stall_if && IHREADY) begin
            if_id_pc    <= pc_r;
            if_id_pc4   <= pc_r + 32'd4;
            if_id_instr <= pfb_hit ? pfb_data[pfb_idx] : IHRDATA;
        end
    end

endmodule
