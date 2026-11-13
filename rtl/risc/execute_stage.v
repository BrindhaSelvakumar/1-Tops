`timescale 1ns / 1ps

module execute_stage (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] ex_pc,
    input  wire [31:0] rdata1,
    input  wire [31:0] rdata2,
    input  wire [31:0] imm,

    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,

    input  wire [4:0]  alu_ctrl,
    input  wire [1:0]  op1_src,
    input  wire        alu_src_ctrl,
    input  wire        m_ext_ctrl,
    input  wire        jump_ctrl,
    input  wire        branch_ctrl,

    input  wire [31:0] mem_alu_result,
    input  wire [31:0] wb_data,
    input  wire [1:0]  forward_a,
    input  wire [1:0]  forward_b,

    output wire [31:0] final_result,
    output wire [31:0] branch_target,    // merged: branch / JAL / JALR target
    output wire        branch_taken,     // merged: branch-taken OR jump
    output wire        m_unit_busy,
    output wire [31:0] fwd_rs2_out
);

    // ================= FORWARDING =================
    reg [31:0] fwd_rs1, fwd_rs2;

    always @(*) begin
        case (forward_a)
            2'b10: fwd_rs1 = mem_alu_result;
            2'b01: fwd_rs1 = wb_data;
            default: fwd_rs1 = rdata1;
        endcase

        case (forward_b)
            2'b10: fwd_rs2 = mem_alu_result;
            2'b01: fwd_rs2 = wb_data;
            default: fwd_rs2 = rdata2;
        endcase
    end

    assign fwd_rs2_out = fwd_rs2;

    // ================= ALU INPUT =================
    reg [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    always @(*) begin
        case (op1_src)
            2'b01: alu_in_a = ex_pc;            // JAL / AUIPC
            2'b10: alu_in_a = 32'h00000000;     // LUI (zero + imm)
            default: alu_in_a = fwd_rs1;        // register operand
        endcase
    end

    assign alu_in_b = (alu_src_ctrl) ? imm : fwd_rs2;

    // ================= ALU =================
    wire [31:0] std_res;

    alu_32 main_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .res(std_res),
        .zero(),
        .neg(),
        .overflow(),
        .cout()
    );

    // ================= M EXTENSION =================
    wire [31:0] m_res;

    m_extension_unit m_ext_unit (
        .clk(clk),
        .rst_n(rst_n),
        .a(fwd_rs1),
        .b(fwd_rs2),
        .alu_ctrl(alu_ctrl),
        .ex_m_ext(m_ext_ctrl),
        .result(m_res),
        .busy(m_unit_busy)
    );

    // ================= FINAL RESULT =================
    assign final_result = (m_ext_ctrl) ? m_res : std_res;

    // ================= BRANCH COMPARISON =================
    // Direct comparison on forwarded values — supports all 6 B-type branches
    wire signed [31:0] fwd_rs1_s = $signed(fwd_rs1);
    wire signed [31:0] fwd_rs2_s = $signed(fwd_rs2);

    reg take_br;

    always @(*) begin
        take_br = 1'b0;

        if (branch_ctrl) begin
            case (funct3)
                3'b000: take_br = (fwd_rs1 == fwd_rs2);      // BEQ
                3'b001: take_br = (fwd_rs1 != fwd_rs2);      // BNE
                3'b100: take_br = (fwd_rs1_s <  fwd_rs2_s);  // BLT
                3'b101: take_br = (fwd_rs1_s >= fwd_rs2_s);  // BGE
                3'b110: take_br = (fwd_rs1   <  fwd_rs2);    // BLTU
                3'b111: take_br = (fwd_rs1   >= fwd_rs2);    // BGEU
                default: take_br = 1'b0;
            endcase
        end
    end

    // ================= TARGET COMPUTATION =================
    // JALR is distinguished from JAL by alu_src_ctrl (JALR has alu_src=1)
    wire is_jalr = jump_ctrl && alu_src_ctrl;

    wire [31:0] pc_plus_imm  = ex_pc + imm;
    wire [31:0] jalr_target  = (fwd_rs1 + imm) & 32'hFFFF_FFFE;

    // Unified redirect target: JALR uses rs1+imm, everything else uses pc+imm
    assign branch_target = is_jalr ? jalr_target : pc_plus_imm;

    // Unified redirect signal: fires on branch-taken OR any jump
    assign branch_taken = (branch_ctrl && take_br) || jump_ctrl;

endmodule
