`timescale 1ns/1ps

// ============================================================
// RISC-V EXECUTE STAGE - BIND FILE
// ============================================================
// Verification only.
// Do NOT add this file to synthesis sources.
//
// This file connects:
//   1. execute_stage_assertions
//   2. execute_stage_cover
//
// to the DUT: execute_stage
// ============================================================


// ============================================================
// BIND ASSERTION MODULE
// ============================================================

bind execute_stage execute_stage_assertions
    u_execute_stage_assertions (

    .clk              (clk),
    .rst_n            (rst_n),

    .ex_pc            (ex_pc),
    .rdata1           (rdata1),
    .rdata2           (rdata2),
    .imm              (imm),

    .funct3            (funct3),
    .funct7            (funct7),

    .alu_ctrl          (alu_ctrl),
    .op1_src           (op1_src),
    .alu_src_ctrl      (alu_src_ctrl),
    .m_ext_ctrl        (m_ext_ctrl),
    .jump_ctrl         (jump_ctrl),
    .branch_ctrl       (branch_ctrl),

    .mem_alu_result    (mem_alu_result),
    .wb_data           (wb_data),
    .forward_a         (forward_a),
    .forward_b         (forward_b),

    .final_result      (final_result),
    .branch_target     (branch_target),
    .jump_target       (jump_target),
    .branch_taken      (branch_taken),
    .m_unit_busy       (m_unit_busy),
    .fwd_rs2_out       (fwd_rs2_out),

    // Internal DUT signals
    .fwd_rs1           (fwd_rs1),
    .fwd_rs2           (fwd_rs2),
    .alu_in_a          (alu_in_a),
    .alu_in_b          (alu_in_b),
    .std_res           (std_res),
    .alu_zero          (alu_zero),
    .m_res             (m_res)
);


// ============================================================
// BIND COVER MODULE
// ============================================================

bind execute_stage execute_stage_cover
    u_execute_stage_cover (

    .clk              (clk),
    .rst_n             (rst_n),

    .ex_pc             (ex_pc),
    .rdata1            (rdata1),
    .rdata2            (rdata2),
    .imm               (imm),

    .funct3            (funct3),
    .funct7            (funct7),

    .alu_ctrl          (alu_ctrl),
    .op1_src           (op1_src),
    .alu_src_ctrl      (alu_src_ctrl),
    .m_ext_ctrl        (m_ext_ctrl),
    .jump_ctrl         (jump_ctrl),
    .branch_ctrl       (branch_ctrl),

    .mem_alu_result    (mem_alu_result),
    .wb_data           (wb_data),
    .forward_a         (forward_a),
    .forward_b         (forward_b),

    .final_result      (final_result),
    .branch_target     (branch_target),
    .jump_target       (jump_target),
    .branch_taken      (branch_taken),
    .m_unit_busy       (m_unit_busy),
    .fwd_rs2_out       (fwd_rs2_out),

    // Internal DUT signals
    .fwd_rs1           (fwd_rs1),
    .fwd_rs2           (fwd_rs2),
    .alu_in_a          (alu_in_a),
    .alu_in_b          (alu_in_b),
    .std_res           (std_res),
    .alu_zero          (alu_zero),
    .m_res             (m_res)
);
