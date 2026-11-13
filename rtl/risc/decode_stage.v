`timescale 1ns / 1ps

module decode_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr,
    input  wire [31:0] pc,
    input  wire        wb_reg_write_en,
    input  wire [4:0]  wb_rd_addr,
    input  wire [31:0] wb_data,
    input  wire        m_unit_busy,
    input  wire        ex_mem_read,
    input  wire [4:0]  ex_rd_addr,

    output wire [31:0] rdata1,
    output wire [31:0] rdata2,
    output wire [31:0] imm,
    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,
    output wire [4:0]  rd_addr,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,

    output wire        reg_write,
    output wire        mem_read,
    output wire        mem_write,
    output wire        alu_src,
    output wire        branch,
    output wire        jump,
    output wire        m_ext,
    output wire [1:0]  mem_to_reg,
    output wire [1:0]  op1_src,
    output wire [4:0]  alu_ctrl,

    output wire        pc_write,
    output wire        if_id_write,
    output wire        ctrl_mux_sel
);

    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign funct7   = instr[31:25];

    wire [6:0] opcode = instr[6:0];
    wire use_rs1 = (opcode != 7'b0110111) && // LUI
                   (opcode != 7'b0010111) && // AUIPC
                   (opcode != 7'b1101111);   // JAL

    wire use_rs2 = (opcode == 7'b0110011) || // R-type & M-ext
                   (opcode == 7'b0100011) || // Store
                   (opcode == 7'b1100011);   // Branch

    wire [4:0] haz_rs1 = use_rs1 ? rs1_addr : 5'd0;
    wire [4:0] haz_rs2 = use_rs2 ? rs2_addr : 5'd0;

    wire c_mem_read, c_mem_write, c_reg_write, c_alu_src;
    wire c_branch, c_jump, c_m_ext;
    wire [1:0] c_mem_to_reg, c_alu_op, c_op1_src;
    wire [4:0] c_alu_ctrl;

    imm_gen imm_gen_inst (.instr(instr), .imm(imm));

    register_f rf (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(wb_reg_write_en),
        .rd_addr(wb_rd_addr),
        .write_data(wb_data),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rdata1),
        .rs2_data(rdata2)
    );

    main_ctrl control_unit (
        .opcode(instr[6:0]),
        .funct7(funct7),
        .mem_read(c_mem_read),
        .mem_write(c_mem_write),
        .reg_write(c_reg_write),
        .mem_to_reg(c_mem_to_reg),
        .alu_src(c_alu_src),
        .branch(c_branch),
        .jump(c_jump),
        .m_ext(c_m_ext),
        .alu_op(c_alu_op),
        .op1_src(c_op1_src),
        .pc_src()
    );

    alu_ctrl_32 acu (
        .aluop(c_alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .m_ext(c_m_ext),
        .alu_ctrl(c_alu_ctrl)
    );

    hazard_unit hazard_detect (
        .id_ex_mem_read(ex_mem_read),
        .id_ex_rd(ex_rd_addr),
        .rs1_addr(haz_rs1),
        .rs2_addr(haz_rs2),
        .m_unit_busy(m_unit_busy),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_mux(ctrl_mux_sel)
    );

    assign reg_write  = ctrl_mux_sel ? 1'b0 : c_reg_write;
    assign mem_write  = ctrl_mux_sel ? 1'b0 : c_mem_write;
    assign mem_read   = ctrl_mux_sel ? 1'b0 : c_mem_read;
    assign alu_src    = ctrl_mux_sel ? 1'b0 : c_alu_src;
    assign branch     = ctrl_mux_sel ? 1'b0 : c_branch;
    assign jump       = ctrl_mux_sel ? 1'b0 : c_jump;
    assign m_ext      = ctrl_mux_sel ? 1'b0 : c_m_ext;
    assign mem_to_reg = ctrl_mux_sel ? 2'b00 : c_mem_to_reg;
    assign op1_src    = ctrl_mux_sel ? 2'b00 : c_op1_src;
    assign alu_ctrl   = ctrl_mux_sel ? 5'b00000 : c_alu_ctrl;


endmodule
