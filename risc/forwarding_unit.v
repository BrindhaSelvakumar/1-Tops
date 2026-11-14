`timescale 1ns / 1ps

module forwarding_unit (
    input  wire [4:0] rs1_ex,
    input  wire [4:0] rs2_ex,

    // MEM stage
    input  wire       reg_write_mem,
    input  wire [4:0] rd_mem,

    // WB stage
    input  wire       reg_write_wb,
    input  wire [4:0] rd_wb,

    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

always @(*) begin

    // -------------------------
    // DEFAULT (NO FORWARDING)
    // -------------------------
    forward_a = 2'b00;
    forward_b = 2'b00;

    // -------------------------
    // FORWARDING FOR rs1 (A)
    // MEM has HIGHER PRIORITY
    // -------------------------
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex))
        forward_a = 2'b10;   // from MEM stage
    else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex))
        forward_a = 2'b01;   // from WB stage

    // -------------------------
    // FORWARDING FOR rs2 (B)
    // MEM has HIGHER PRIORITY
    // -------------------------
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex))
        forward_b = 2'b10;   // from MEM stage
    else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex))
        forward_b = 2'b01;   // from WB stage

end

endmodule
