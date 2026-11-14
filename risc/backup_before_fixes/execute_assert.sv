`timescale 1ns/1ps
module execute_stage_assertions (
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

    // Internal execute-stage signals
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
    // 01. FORWARD A FROM MEM
    // ============================================================

    property p01_forward_a_mem;
        (forward_a == 2'b10) |-> (fwd_rs1 == mem_alu_result);
    endproperty

    a01_forward_a_mem:
        assert property (p01_forward_a_mem)
        else $error("ASSERT 01 FAILED: Forward A from MEM");


    // ============================================================
    // 02. FORWARD A FROM WB
    // ============================================================

    property p02_forward_a_wb;
        (forward_a == 2'b01) |-> (fwd_rs1 == wb_data);
    endproperty

    a02_forward_a_wb:
        assert property (p02_forward_a_wb)
        else $error("ASSERT 02 FAILED: Forward A from WB");


    // ============================================================
    // 03. FORWARD A FROM REGISTER FILE
    // ============================================================

    property p03_forward_a_reg;
        (forward_a == 2'b00) |-> (fwd_rs1 == rdata1);
    endproperty

    a03_forward_a_reg:
        assert property (p03_forward_a_reg)
        else $error("ASSERT 03 FAILED: Forward A register source");


    // ============================================================
    // 04. FORWARD B FROM MEM
    // ============================================================

    property p04_forward_b_mem;
        (forward_b == 2'b10) |-> (fwd_rs2 == mem_alu_result);
    endproperty

    a04_forward_b_mem:
        assert property (p04_forward_b_mem)
        else $error("ASSERT 04 FAILED: Forward B from MEM");


    // ============================================================
    // 05. FORWARD B FROM WB
    // ============================================================

    property p05_forward_b_wb;
        (forward_b == 2'b01) |-> (fwd_rs2 == wb_data);
    endproperty

    a05_forward_b_wb:
        assert property (p05_forward_b_wb)
        else $error("ASSERT 05 FAILED: Forward B from WB");


    // ============================================================
    // 06. FORWARD B FROM REGISTER FILE
    // ============================================================

    property p06_forward_b_reg;
        (forward_b == 2'b00) |-> (fwd_rs2 == rdata2);
    endproperty

    a06_forward_b_reg:
        assert property (p06_forward_b_reg)
        else $error("ASSERT 06 FAILED: Forward B register source");


    // ============================================================
    // 07. FORWARDED RS2 OUTPUT
    // ============================================================

    property p07_fwd_rs2_output;
        fwd_rs2_out == fwd_rs2;
    endproperty

    a07_fwd_rs2_output:
        assert property (p07_fwd_rs2_output)
        else $error("ASSERT 07 FAILED: fwd_rs2_out mismatch");


    // ============================================================
    // 08. ALU INPUT A = RS1
    // ============================================================

    property p08_alu_a_rs1;
        (op1_src == 2'b00) |-> (alu_in_a == fwd_rs1);
    endproperty

    a08_alu_a_rs1:
        assert property (p08_alu_a_rs1)
        else $error("ASSERT 08 FAILED: ALU input A RS1 selection");


    // ============================================================
    // 09. ALU INPUT A = PC
    // ============================================================

    property p09_alu_a_pc;
        (op1_src == 2'b01) |-> (alu_in_a == ex_pc);
    endproperty

    a09_alu_a_pc:
        assert property (p09_alu_a_pc)
        else $error("ASSERT 09 FAILED: ALU input A PC selection");


    // ============================================================
    // 10. ALU INPUT A = ZERO
    // ============================================================

    property p10_alu_a_zero;
        (op1_src == 2'b10) |-> (alu_in_a == 32'b0);
    endproperty

    a10_alu_a_zero:
        assert property (p10_alu_a_zero)
        else $error("ASSERT 10 FAILED: ALU input A zero selection");


    // ============================================================
    // 11. ALU INPUT B = IMMEDIATE
    // ============================================================

    property p11_alu_b_imm;
        alu_src_ctrl |-> (alu_in_b == imm);
    endproperty

    a11_alu_b_imm:
        assert property (p11_alu_b_imm)
        else $error("ASSERT 11 FAILED: ALU input B immediate selection");


    // ============================================================
    // 12. ALU INPUT B = RS2
    // ============================================================

    property p12_alu_b_rs2;
        !alu_src_ctrl |-> (alu_in_b == fwd_rs2);
    endproperty

    a12_alu_b_rs2:
        assert property (p12_alu_b_rs2)
        else $error("ASSERT 12 FAILED: ALU input B RS2 selection");


    // ============================================================
    // 13. ADD OPERATION
    // ============================================================

    property p13_alu_add;
        (!m_ext_ctrl && alu_ctrl == 5'b00000)
        |-> (std_res == (alu_in_a + alu_in_b));
    endproperty

    a13_alu_add:
        assert property (p13_alu_add)
        else $error("ASSERT 13 FAILED: ADD result");


    // ============================================================
    // 14. SUB OPERATION
    // ============================================================

    property p14_alu_sub;
        (!m_ext_ctrl && alu_ctrl == 5'b00001)
        |-> (std_res == (alu_in_a - alu_in_b));
    endproperty

    a14_alu_sub:
        assert property (p14_alu_sub)
        else $error("ASSERT 14 FAILED: SUB result");


    // ============================================================
    // 15. AND OPERATION
    // ============================================================

    property p15_alu_and;
        (!m_ext_ctrl && alu_ctrl == 5'b00010)
        |-> (std_res == (alu_in_a & alu_in_b));
    endproperty

    a15_alu_and:
        assert property (p15_alu_and)
        else $error("ASSERT 15 FAILED: AND result");


    // ============================================================
    // 16. OR OPERATION
    // ============================================================

    property p16_alu_or;
        (!m_ext_ctrl && alu_ctrl == 5'b00011)
        |-> (std_res == (alu_in_a | alu_in_b));
    endproperty

    a16_alu_or:
        assert property (p16_alu_or)
        else $error("ASSERT 16 FAILED: OR result");


    // ============================================================
    // 17. XOR OPERATION
    // ============================================================

    property p17_alu_xor;
        (!m_ext_ctrl && alu_ctrl == 5'b00100)
        |-> (std_res == (alu_in_a ^ alu_in_b));
    endproperty

    a17_alu_xor:
        assert property (p17_alu_xor)
        else $error("ASSERT 17 FAILED: XOR result");


    // ============================================================
    // 18. SIGNED SLT
    // ============================================================

    property p18_alu_slt;
        (!m_ext_ctrl && alu_ctrl == 5'b01000)
        |-> (std_res ==
            (($signed(alu_in_a) < $signed(alu_in_b))
             ? 32'd1 : 32'd0));
    endproperty

    a18_alu_slt:
        assert property (p18_alu_slt)
        else $error("ASSERT 18 FAILED: SLT result");


    // ============================================================
    // 19. UNSIGNED SLTU
    // ============================================================

    property p19_alu_sltu;
        (!m_ext_ctrl && alu_ctrl == 5'b01001)
        |-> (std_res ==
            ((alu_in_a < alu_in_b)
             ? 32'd1 : 32'd0));
    endproperty

    a19_alu_sltu:
        assert property (p19_alu_sltu)
        else $error("ASSERT 19 FAILED: SLTU result");


    // ============================================================
    // 20. SHIFT LEFT LOGICAL
    // ============================================================

    property p20_alu_sll;
        (!m_ext_ctrl && alu_ctrl == 5'b01101)
        |-> (std_res == (alu_in_a << alu_in_b[4:0]));
    endproperty

    a20_alu_sll:
        assert property (p20_alu_sll)
        else $error("ASSERT 20 FAILED: SLL result");


    // ============================================================
    // 21. SHIFT RIGHT LOGICAL
    // ============================================================

    property p21_alu_srl;
        (!m_ext_ctrl && alu_ctrl == 5'b01110)
        |-> (std_res == (alu_in_a >> alu_in_b[4:0]));
    endproperty

    a21_alu_srl:
        assert property (p21_alu_srl)
        else $error("ASSERT 21 FAILED: SRL result");


    // ============================================================
    // 22. SHIFT RIGHT ARITHMETIC
    // ============================================================

    property p22_alu_sra;
        (!m_ext_ctrl && alu_ctrl == 5'b01111)
        |-> (std_res ==
            ($signed(alu_in_a) >>> alu_in_b[4:0]));
    endproperty

    a22_alu_sra:
        assert property (p22_alu_sra)
        else $error("ASSERT 22 FAILED: SRA result");


    // ============================================================
    // 23. ZERO FLAG
    // ============================================================

    property p23_zero_flag;
        alu_zero == (std_res == 32'b0);
    endproperty

    a23_zero_flag:
        assert property (p23_zero_flag)
        else $error("ASSERT 23 FAILED: ALU zero flag");


    // ============================================================
    // 24. BEQ BRANCH
    // ============================================================

    property p24_beq;
        (branch_ctrl && funct3 == 3'b000)
        |-> (branch_taken == (std_res == 32'b0));
    endproperty

    a24_beq:
        assert property (p24_beq)
        else $error("ASSERT 24 FAILED: BEQ decision");


    // ============================================================
    // 25. BNE BRANCH
    // ============================================================

    property p25_bne;
        (branch_ctrl && funct3 == 3'b001)
        |-> (branch_taken == (std_res != 32'b0));
    endproperty

    a25_bne:
        assert property (p25_bne)
        else $error("ASSERT 25 FAILED: BNE decision");


    // ============================================================
    // 26. INVALID BRANCH FUNCT3
    // ============================================================

    property p26_invalid_branch;
        branch_ctrl &&
        (funct3 != 3'b000) &&
        (funct3 != 3'b001)
        |-> !branch_taken;
    endproperty

    a26_invalid_branch:
        assert property (p26_invalid_branch)
        else $error("ASSERT 26 FAILED: Invalid branch generated taken");


    // ============================================================
    // 27. BRANCH TARGET
    // ============================================================

    property p27_branch_target;
        branch_target == (ex_pc + imm);
    endproperty

    a27_branch_target:
        assert property (p27_branch_target)
        else $error("ASSERT 27 FAILED: Branch target");


    // ============================================================
    // 28. JAL TARGET
    // ============================================================

    property p28_jal_target;
        jump_ctrl && (funct3 != 3'b000)
        |-> (jump_target == (ex_pc + imm));
    endproperty

    a28_jal_target:
        assert property (p28_jal_target)
        else $error("ASSERT 28 FAILED: JAL target");


    // ============================================================
    // 29. JALR TARGET
    // ============================================================

    property p29_jalr_target;
        jump_ctrl && (funct3 == 3'b000)
        |-> (jump_target ==
            ((fwd_rs1 + imm) & 32'hFFFFFFFE));
    endproperty

    a29_jalr_target:
        assert property (p29_jalr_target)
        else $error("ASSERT 29 FAILED: JALR target");


    // ============================================================
    // 30. MUL
    // ============================================================

    property p30_mul;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10000)
        |-> (final_result ==
            ($signed(fwd_rs1) * $signed(fwd_rs2)));
    endproperty

    a30_mul:
        assert property (p30_mul)
        else $error("ASSERT 30 FAILED: MUL result");


    // ============================================================
    // 31. MULH
    // ============================================================

    property p31_mulh;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10001)
        |-> (final_result ==
            (($signed(fwd_rs1) * $signed(fwd_rs2)) >>> 32));
    endproperty

    a31_mulh:
        assert property (p31_mulh)
        else $error("ASSERT 31 FAILED: MULH result");


    // ============================================================
    // 32. MULHSU
    // ============================================================

    property p32_mulhsu;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10010)
        |-> (final_result ==
            (($signed(fwd_rs1) *
              $signed({1'b0, fwd_rs2})) >>> 32));
    endproperty

    a32_mulhsu:
        assert property (p32_mulhsu)
        else $error("ASSERT 32 FAILED: MULHSU result");


    // ============================================================
    // 33. MULHU
    // ============================================================

    property p33_mulhu;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10011)
        |-> (final_result ==
            ((fwd_rs1 * fwd_rs2) >> 32));
    endproperty

    a33_mulhu:
        assert property (p33_mulhu)
        else $error("ASSERT 33 FAILED: MULHU result");


    // ============================================================
    // 34. DIVISION BY ZERO
    // ============================================================

    property p34_div_zero;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10100 &&
         fwd_rs2 == 32'b0)
        |-> (final_result == 32'hFFFFFFFF);
    endproperty

    a34_div_zero:
        assert property (p34_div_zero)
        else $error("ASSERT 34 FAILED: DIV by zero");


    // ============================================================
    // 35. DIVU / REM / REMU DIVISION BY ZERO
    // ============================================================

    property p35_divu_zero;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         alu_ctrl == 5'b10101 &&
         fwd_rs2 == 32'b0)
        |-> (final_result == 32'hFFFFFFFF);
    endproperty

    a35_divu_zero:
        assert property (p35_divu_zero)
        else $error("ASSERT 35 FAILED: DIVU by zero");


    // ============================================================
    // 36. REM / REMU BY ZERO
    // ============================================================

    property p36_rem_zero;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         (alu_ctrl == 5'b10110 || alu_ctrl == 5'b10111) &&
         fwd_rs2 == 32'b0)
        |-> (final_result == fwd_rs1);
    endproperty

    a36_rem_zero:
        assert property (p36_rem_zero)
        else $error("ASSERT 36 FAILED: REM/REMU by zero");


    // ============================================================
    // 37. SIGNED DIVISION / REMAINDER SPECIAL CASE
    // INT_MIN / -1 = INT_MIN
    // INT_MIN % -1 = 0
    // ============================================================

    property p37_div_rem_overflow;
        (m_ext_ctrl &&
         funct7 == 7'b0000001 &&
         fwd_rs1 == 32'h80000000 &&
         fwd_rs2 == 32'hFFFFFFFF &&
         (alu_ctrl == 5'b10100 || alu_ctrl == 5'b10110))
        |->
        ((alu_ctrl == 5'b10100 && final_result == 32'h80000000) ||
         (alu_ctrl == 5'b10110 && final_result == 32'b0));
    endproperty

    a37_div_rem_overflow:
        assert property (p37_div_rem_overflow)
        else $error("ASSERT 37 FAILED: Signed DIV/REM overflow case");


    // ============================================================
    // 38. FINAL RESULT / M-UNIT / X-Z SAFETY
    // ============================================================

    property p38_result_and_safety;
    @(posedge clk)
    (
        (!m_ext_ctrl) |-> (final_result == std_res)
    )
    and
    (
        (m_ext_ctrl && (funct7 == 7'b0000001))
        |-> (final_result == m_res)
    )
    and
    (
        (m_unit_busy == 1'b0)
    )
    and
    (
        !$isunknown({
            final_result,
            branch_target,
            jump_target,
            branch_taken,
            m_unit_busy
        })
    );
endproperty

a38_result_and_safety:
    assert property (p38_result_and_safety)
    else $error("ASSERT 38 FAILED: Result selection / M-unit / X-Z");


endmodule



