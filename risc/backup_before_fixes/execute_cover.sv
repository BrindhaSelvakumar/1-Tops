`timescale 1ns/1ps

// ============================================================
// RISC-V EXECUTE STAGE - COVER PROPERTIES
// ============================================================
// Verification only.
// Do NOT add this file to synthesis sources.
// ============================================================

module execute_stage_cover (

    input wire        clk,
    input wire        rst_n,

    input wire [31:0] ex_pc,
    input wire [31:0] rdata1,
    input wire [31:0] rdata2,
    input wire [31:0] imm,

    input wire [2:0]  funct3,
    input wire [6:0]  funct7,

    input wire [4:0]  alu_ctrl,
    input wire [1:0]  op1_src,
    input wire        alu_src_ctrl,
    input wire        m_ext_ctrl,
    input wire        jump_ctrl,
    input wire        branch_ctrl,

    input wire [31:0] mem_alu_result,
    input wire [31:0] wb_data,
    input wire [1:0]  forward_a,
    input wire [1:0]  forward_b,

    input wire [31:0] final_result,
    input wire [31:0] branch_target,
    input wire [31:0] jump_target,
    input wire        branch_taken,
    input wire        m_unit_busy,
    input wire [31:0] fwd_rs2_out,

    // Internal signals
    input wire [31:0] fwd_rs1,
    input wire [31:0] fwd_rs2,
    input wire [31:0] alu_in_a,
    input wire [31:0] alu_in_b,
    input wire [31:0] std_res,
    input wire        alu_zero,
    input wire [31:0] m_res
);

    default clocking cb @(posedge clk);
    endclocking


    // ============================================================
    // 1. BASIC EXECUTE ACTIVITY
    // ============================================================

    cp01_execute_active:
        cover property (
            rst_n &&
            !$isunknown({
                alu_ctrl,
                alu_in_a,
                alu_in_b,
                final_result
            })
        );


    // ============================================================
    // 2. ADD
    // ============================================================

    cp02_add:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00000
        );


    // ============================================================
    // 3. SUB
    // ============================================================

    cp03_sub:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00001
        );


    // ============================================================
    // 4. AND
    // ============================================================

    cp04_and:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00010
        );


    // ============================================================
    // 5. OR
    // ============================================================

    cp05_or:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00011
        );


    // ============================================================
    // 6. XOR
    // ============================================================

    cp06_xor:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00100
        );


    // ============================================================
    // 7. SLT
    // ============================================================

    cp07_slt:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b01000 &&
            $signed(alu_in_a) < $signed(alu_in_b)
        );


    // ============================================================
    // 8. SLTU
    // ============================================================

    cp08_sltu:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b01001 &&
            alu_in_a < alu_in_b
        );


    // ============================================================
    // 9. SLL
    // ============================================================

    cp09_sll:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b01101 &&
            alu_in_b[4:0] != 5'b0
        );


    // ============================================================
    // 10. SRL
    // ============================================================

    cp10_srl:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b01110 &&
            alu_in_b[4:0] != 5'b0
        );


    // ============================================================
    // 11. SRA
    // ============================================================

    cp11_sra:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b01111 &&
            alu_in_a[31] &&
            alu_in_b[4:0] != 5'b0
        );


    // ============================================================
    // 12. FORWARDING FROM MEM
    // ============================================================

    cp12_forward_mem_a:
        cover property (
            rst_n &&
            forward_a == 2'b10 &&
            fwd_rs1 == mem_alu_result
        );


    cp13_forward_mem_b:
        cover property (
            rst_n &&
            forward_b == 2'b10 &&
            fwd_rs2 == mem_alu_result
        );


    // ============================================================
    // 13. FORWARDING FROM WB
    // ============================================================

    cp14_forward_wb_a:
        cover property (
            rst_n &&
            forward_a == 2'b01 &&
            fwd_rs1 == wb_data
        );


    cp15_forward_wb_b:
        cover property (
            rst_n &&
            forward_b == 2'b01 &&
            fwd_rs2 == wb_data
        );


    // ============================================================
    // 14. IMMEDIATE OPERAND
    // ============================================================

    cp16_immediate_operand:
        cover property (
            rst_n &&
            alu_src_ctrl &&
            alu_in_b == imm
        );


    // ============================================================
    // 15. PC AS ALU INPUT
    // ============================================================

    cp17_pc_operand:
        cover property (
            rst_n &&
            op1_src == 2'b01 &&
            alu_in_a == ex_pc
        );


    // ============================================================
    // 16. ZERO ALU INPUT
    // ============================================================

    cp18_zero_operand:
        cover property (
            rst_n &&
            op1_src == 2'b10 &&
            alu_in_a == 32'b0
        );


    // ============================================================
    // 17. BEQ TAKEN
    // ============================================================

    cp19_beq_taken:
        cover property (
            rst_n &&
            branch_ctrl &&
            funct3 == 3'b000 &&
            branch_taken
        );


    // ============================================================
    // 18. BEQ NOT TAKEN
    // ============================================================

    cp20_beq_not_taken:
        cover property (
            rst_n &&
            branch_ctrl &&
            funct3 == 3'b000 &&
            !branch_taken
        );


    // ============================================================
    // 19. BNE TAKEN
    // ============================================================

    cp21_bne_taken:
        cover property (
            rst_n &&
            branch_ctrl &&
            funct3 == 3'b001 &&
            branch_taken
        );


    // ============================================================
    // 20. BNE NOT TAKEN
    // ============================================================

    cp22_bne_not_taken:
        cover property (
            rst_n &&
            branch_ctrl &&
            funct3 == 3'b001 &&
            !branch_taken
        );


    // ============================================================
    // 21. JAL
    // ============================================================

    cp23_jal:
        cover property (
            rst_n &&
            jump_ctrl &&
            funct3 != 3'b000 &&
            jump_target == ex_pc + imm
        );


    // ============================================================
    // 22. JALR
    // ============================================================

    cp24_jalr:
        cover property (
            rst_n &&
            jump_ctrl &&
            funct3 == 3'b000 &&
            jump_target ==
            ((fwd_rs1 + imm) & 32'hFFFFFFFE)
        );


    // ============================================================
    // 23. MUL
    // ============================================================

    cp25_mul:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10000
        );


    // ============================================================
    // 24. MULH
    // ============================================================

    cp26_mulh:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10001
        );


    // ============================================================
    // 25. MULHSU
    // ============================================================

    cp27_mulhsu:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10010
        );


    // ============================================================
    // 26. MULHU
    // ============================================================

    cp28_mulhu:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10011
        );


    // ============================================================
    // 27. DIV
    // ============================================================

    cp29_div:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10100 &&
            fwd_rs2 != 32'b0
        );


    // ============================================================
    // 28. DIVU
    // ============================================================

    cp30_divu:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10101 &&
            fwd_rs2 != 32'b0
        );


    // ============================================================
    // 29. REM
    // ============================================================

    cp31_rem:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10110 &&
            fwd_rs2 != 32'b0
        );


    // ============================================================
    // 30. REMU
    // ============================================================

    cp32_remu:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10111 &&
            fwd_rs2 != 32'b0
        );


    // ============================================================
    // 31. DIVISION BY ZERO
    // ============================================================

    cp33_div_zero:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10100 &&
            fwd_rs2 == 32'b0
        );


    // ============================================================
    // 32. REMAINDER BY ZERO
    // ============================================================

    cp34_rem_zero:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            (alu_ctrl == 5'b10110 ||
             alu_ctrl == 5'b10111) &&
            fwd_rs2 == 32'b0
        );


    // ============================================================
    // 33. SIGNED DIVISION OVERFLOW
    // INT_MIN / -1
    // ============================================================

    cp35_div_overflow:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10100 &&
            fwd_rs1 == 32'h80000000 &&
            fwd_rs2 == 32'hFFFFFFFF
        );


    // ============================================================
    // 34. SIGNED REMAINDER OVERFLOW CASE
    // INT_MIN % -1
    // ============================================================

    cp36_rem_overflow:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            alu_ctrl == 5'b10110 &&
            fwd_rs1 == 32'h80000000 &&
            fwd_rs2 == 32'hFFFFFFFF
        );


    // ============================================================
    // 35. ZERO RESULT
    // ============================================================

    cp37_zero_result:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            std_res == 32'b0 &&
            alu_zero
        );


    // ============================================================
    // 36. NEGATIVE RESULT
    // ============================================================

    cp38_negative_result:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            std_res[31]
        );


    // ============================================================
    // 37. M EXTENSION RESULT SELECTION
    // ============================================================

    cp39_m_result_selected:
        cover property (
            rst_n &&
            m_ext_ctrl &&
            funct7 == 7'b0000001 &&
            final_result == m_res
        );


    // ============================================================
    // 38. NORMAL ALU RESULT SELECTION
    // ============================================================

    cp40_standard_result_selected:
        cover property (
            rst_n &&
            !m_ext_ctrl &&
            final_result == std_res
        );


    // ============================================================
    // 39. COMBINED FORWARDING + ALU OPERATION
    // ============================================================

    cp41_forward_then_add:
        cover property (
            rst_n &&
            forward_a == 2'b10 &&
            forward_b == 2'b01 &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00000
        );


    // ============================================================
    // 40. BRANCH WITH FORWARDED OPERANDS
    // ============================================================

    cp42_branch_with_forwarding:
        cover property (
            rst_n &&
            branch_ctrl &&
            (funct3 == 3'b000 || funct3 == 3'b001) &&
            (forward_a != 2'b00 || forward_b != 2'b00)
        );


    // ============================================================
    // 41. IMMEDIATE ALU OPERATION
    // ============================================================

    cp43_immediate_alu:
        cover property (
            rst_n &&
            alu_src_ctrl &&
            !m_ext_ctrl &&
            alu_ctrl == 5'b00000
        );


    // ============================================================
    // 42. JUMP + FORWARDED RS1 (JALR)
    // ============================================================

    cp44_jalr_forwarding:
        cover property (
            rst_n &&
            jump_ctrl &&
            funct3 == 3'b000 &&
            forward_a != 2'b00
        );


endmodule

