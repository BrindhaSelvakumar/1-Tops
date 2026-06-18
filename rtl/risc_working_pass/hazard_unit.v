`timescale 1ns / 1ps

module hazard_unit (
    input  wire        id_ex_mem_read,
    input  wire [4:0]  id_ex_rd,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire        m_unit_busy,

    output wire        pc_write,
    output wire        if_id_write,
    output wire        control_mux
);

    // -------------------------
    // LOAD-USE HAZARD
    // -------------------------
    wire load_use_hazard;

    assign load_use_hazard =
        id_ex_mem_read &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == rs1_addr) || (id_ex_rd == rs2_addr));

    // -------------------------
    // M UNIT STALL (FIXED)
    // Only stall when EX stage depends on it indirectly
    // -------------------------
    wire m_stall = m_unit_busy;

    // -------------------------
    // FINAL STALL
    // -------------------------
    wire stall = load_use_hazard || m_stall;

    // -------------------------
    // CONTROL OUTPUTS
    // -------------------------
    assign pc_write    = ~stall;
    assign if_id_write = ~stall;
    assign control_mux =  stall;   // insert NOP in ID/EX

endmodule
