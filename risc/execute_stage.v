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
    output wire [31:0] branch_target,
    output wire [31:0] jump_target,
    output wire        branch_taken,
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
            2'b01: alu_in_a = ex_pc; 
            2'b10: alu_in_a = 32'h00000000;    // for AUIPC / JAL
            default: alu_in_a = fwd_rs1;
        endcase
    end

    assign alu_in_b = (alu_src_ctrl) ? imm : fwd_rs2;

    // ================= ALU =================
    wire [31:0] std_res;
    wire alu_zero;

    alu_32 main_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .res(std_res),
        .zero(alu_zero),
        .neg(),
        .overflow(),
        .cout()
    );

    // ================= M EXT =================
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

    // ================= BRANCH LOGIC =================
    reg take_br;

    always @(*) begin
        take_br = 1'b0;

        if (branch_ctrl) begin
            case (funct3)
                3'b000: take_br = alu_zero;                                 // BEQ
                3'b001: take_br = ~alu_zero;                                // BNE
                3'b100: take_br = ($signed(fwd_rs1) < $signed(fwd_rs2));    // BLT
                3'b101: take_br = ($signed(fwd_rs1) >= $signed(fwd_rs2));   // BGE
                3'b110: take_br = (fwd_rs1 < fwd_rs2);                      // BLTU
                3'b111: take_br = (fwd_rs1 >= fwd_rs2);                     // BGEU
                default: take_br = 1'b0;
            endcase
        end
    end

    // ================= TARGET COMPUTATION =================
    // JAL has op1_src == 2'b01 (PC), while JALR has op1_src == 2'b00 (rs1).
    // Note: Checking funct3 == 3'b000 is incorrect for JAL because bits [14:12] in J-type are immediate bits.
    wire is_jalr = (jump_ctrl && (op1_src == 2'b00));

    wire [31:0] jal_target   = ex_pc + imm;
    wire [31:0] branch_tgt   = ex_pc + imm;
    wire [31:0] jalr_target  = (fwd_rs1 + imm) & 32'hFFFF_FFFE;

    assign branch_target = branch_tgt;
    assign jump_target   = is_jalr ? jalr_target : jal_target;

    assign branch_taken = (branch_ctrl && take_br);

endmodule
