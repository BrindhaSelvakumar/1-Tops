`timescale 1ns / 1ps

module risc_core_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] IHADDR,
    output wire [1:0]  IHTRANS,
    output wire        IHWRITE,
    output wire [2:0]  IHSIZE,
    input  wire [31:0] IHRDATA,
    input  wire        IHREADY,
    output wire [31:0] DHADDR,
    output wire [31:0] DHWDATA,
    output wire        DHWRITE,
    output wire [2:0]  DHSIZE,
    output wire [1:0]  DHTRANS,
    input  wire [31:0] DHRDATA,
    input  wire        DHREADY,
    input  wire        irq_i,
    input  wire [2:0]  irq_id_i,
    output wire        irq_ack_o,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_alu_result
);

    wire stall_mem;
wire ex_m_unit_busy;

wire hazard_pc_write;
wire hazard_if_id_write;
wire hazard_ctrl_mux;

wire ex_branch;
wire ex_jump;
wire ex_m_ext;

wire stall_front = stall_mem | ex_m_unit_busy | !IHREADY | !hazard_pc_write;

    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd_addr;
    wire        wb_reg_write_en;

   wire [31:0] if_pc, if_instr;
wire [31:0] ex_jump_target;
wire [31:0] ex_branch_target;
wire        ex_branch_taken;

wire flush;
assign flush = ex_branch_taken;

fetch_stage IF_INST (
    .clk(clk),
    .rst_n(rst_n),

    .branch_taken(ex_branch_taken),
    .branch_target(ex_branch_target),

    .pc_write(hazard_pc_write),
    .stall_all(stall_front),

    .IHADDR(IHADDR),
    .IHTRANS(IHTRANS),
    .IHWRITE(IHWRITE),
    .IHSIZE(IHSIZE),
    .IHREADY(IHREADY),
    .IHRDATA(IHRDATA),

    .pc_out(if_pc),
    .instr_out(if_instr)
);

    wire [31:0] id_pc, id_instr;
    if_id_reg PIPE_IF_ID (
        .clk(clk), .rst_n(rst_n),
        .flush(flush),
        .stall(stall_front | !hazard_if_id_write),
        .pc_in(if_pc), .instr_in(if_instr),
        .pc_out(id_pc), .instr_out(id_instr)
    );

    wire [31:0] id_rdata1, id_rdata2, id_imm;
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [2:0]  id_funct3;
    wire [6:0]  id_funct7;
    wire [1:0]  id_mem_to_reg, id_op1_src;
    wire [4:0]  id_alu_ctrl;
    wire        id_reg_write, id_mem_read, id_mem_write;
    wire        id_alu_src, id_branch, id_jump, id_m_ext;
    wire        ex_mem_read;
    wire [4:0]  ex_final_rd;

    decode_stage ID_INST (
        .clk(clk), .rst_n(rst_n),
        .instr(id_instr), .pc(id_pc),
        .wb_reg_write_en(wb_reg_write_en),
        .wb_rd_addr(wb_rd_addr), .wb_data(wb_write_data),
        .ex_mem_read(ex_mem_read), .ex_rd_addr(ex_final_rd),
        .m_unit_busy(ex_m_unit_busy),
        .rdata1(id_rdata1), .rdata2(id_rdata2), .imm(id_imm),
        .rs1_addr(id_rs1), .rs2_addr(id_rs2), .rd_addr(id_rd),
        .funct3(id_funct3), .funct7(id_funct7),
        .reg_write(id_reg_write), .mem_read(id_mem_read),
        .mem_write(id_mem_write), .mem_to_reg(id_mem_to_reg),
        .alu_src(id_alu_src), .op1_src(id_op1_src),
        .branch(id_branch), .jump(id_jump), .m_ext(id_m_ext),
        .alu_ctrl(id_alu_ctrl),
        .pc_write(hazard_pc_write),
        .if_id_write(hazard_if_id_write),
        .ctrl_mux_sel(hazard_ctrl_mux)
    );

    wire [31:0] ex_pc, ex_r1, ex_r2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_alu_ctrl;
    wire [2:0]  ex_f3;
    wire [6:0]  ex_f7;
    wire [1:0]  ex_op1_src, ex_mem_to_reg;
    wire        ex_reg_write, ex_mem_write, ex_alu_src;

    id_ex_reg PIPE_ID_EX (
        .clk(clk), .rst_n(rst_n),
        .flush(flush),
        .stall(stall_mem | ex_m_unit_busy | !IHREADY),
        .pc_in(id_pc), .pc_out(ex_pc),
        .read_data1_in(id_rdata1), .read_data1_out(ex_r1),
        .read_data2_in(id_rdata2), .read_data2_out(ex_r2),
        .imm_in(id_imm), .imm_out(ex_imm),
        .rs1_addr_in(id_rs1), .rs1_addr_out(ex_rs1),
        .rs2_addr_in(id_rs2), .rs2_addr_out(ex_rs2),
        .rd_addr_in(id_rd), .rd_addr_out(ex_final_rd),
        .funct3_in(id_funct3), .funct3_out(ex_f3),
        .funct7_in(id_funct7), .funct7_out(ex_f7),
        .alu_ctrl_in(id_alu_ctrl), .alu_ctrl_out(ex_alu_ctrl),
        .reg_write_in(id_reg_write), .reg_write_out(ex_reg_write),
        .mem_read_in(id_mem_read), .mem_read_out(ex_mem_read),
        .mem_write_in(id_mem_write), .mem_write_out(ex_mem_write),
        .mem_to_reg_in(id_mem_to_reg), .mem_to_reg_out(ex_mem_to_reg),
        .alu_src_in(id_alu_src), .alu_src_out(ex_alu_src),
        .op_src_in(id_op1_src), .op_src_out(ex_op1_src),
        .branch_in(id_branch), .branch_out(ex_branch),
        .jump_in(id_jump), .jump_out(ex_jump),
        .m_ext_in(id_m_ext), .m_ext_out(ex_m_ext)
    );

    wire [31:0] ex_alu_res, ex_fwd_rs2;
    wire [1:0]  forward_a, forward_b;
    wire [31:0] mem_alu_result;
    wire        mem_reg_write;
    wire [4:0]  mem_rd_addr;

    forwarding_unit FWD (
        .rs1_ex(ex_rs1), .rs2_ex(ex_rs2),
        .reg_write_mem(mem_reg_write), .rd_mem(mem_rd_addr),
        .reg_write_wb(wb_reg_write_en), .rd_wb(wb_rd_addr),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    execute_stage EX_INST (
    .clk(clk), .rst_n(rst_n),
    .ex_pc(ex_pc), .rdata1(ex_r1), .rdata2(ex_r2), .imm(ex_imm),
    .funct3(ex_f3), .funct7(ex_f7), .alu_ctrl(ex_alu_ctrl),
    .op1_src(ex_op1_src), .alu_src_ctrl(ex_alu_src),
    .m_ext_ctrl(ex_m_ext), .jump_ctrl(ex_jump), .branch_ctrl(ex_branch),
    .mem_alu_result(mem_alu_result), .wb_data(wb_write_data),
    .forward_a(forward_a), .forward_b(forward_b),
    .final_result(ex_alu_res),
.branch_target(ex_branch_target),
.branch_taken(ex_branch_taken),
    .m_unit_busy(ex_m_unit_busy),
    .fwd_rs2_out(ex_fwd_rs2)
);

    wire [31:0] mem_write_data, mem_pc4;
    wire [2:0]  mem_f3;
    wire [1:0]  mem_to_reg_ctrl;
    wire        mem_mem_read, mem_mem_write;

    ex_mem_reg PIPE_EX_MEM (
        .clk(clk), .rst_n(rst_n),
        .stall(stall_mem),
        .reg_write_in(ex_reg_write),    .reg_write_out(mem_reg_write),
        .mem_to_reg_in(ex_mem_to_reg),  .mem_to_reg_out(mem_to_reg_ctrl),
        .mem_read_in(ex_mem_read),      .mem_read_out(mem_mem_read),
        .mem_write_in(ex_mem_write),    .mem_write_out(mem_mem_write),
        .alu_result_in(ex_alu_res),     .alu_result_out(mem_alu_result),
        .mem_write_data_in(ex_fwd_rs2), .mem_write_data_out(mem_write_data),
        .rd_addr_in(ex_final_rd),       .rd_addr_out(mem_rd_addr),
        .funct3_in(ex_f3),              .funct3_out(mem_f3),
        .pc_plus4_in(ex_pc + 32'd4),    .pc_plus4_out(mem_pc4)
    );

    wire [31:0] mem_read_data;

    memory_stage MEM_INST (
        .clk(clk), .rst_n(rst_n),
        .addr(mem_alu_result), .write_data(mem_write_data),
        .funct3(mem_f3), .mem_read(mem_mem_read), .mem_write(mem_mem_write),
        .DHADDR(DHADDR), .DHWDATA(DHWDATA), .DHWRITE(DHWRITE),
        .DHSIZE(DHSIZE), .DHTRANS(DHTRANS),
        .DHREADY(DHREADY), .DHRDATA(DHRDATA),
        .read_data(mem_read_data), .stall_mem(stall_mem)
    );

    wire [31:0] wb_mem_data, wb_alu_res, wb_pc4;
    wire [1:0]  wb_to_reg_ctrl;

    mem_wb_reg PIPE_MEM_WB (
        .clk(clk), .rst_n(rst_n),
        .stall(stall_mem),
        .reg_write_in(mem_reg_write),     .reg_write_out(wb_reg_write_en),
        .mem_to_reg_in(mem_to_reg_ctrl),  .mem_to_reg_out(wb_to_reg_ctrl),
        .mem_read_data_in(mem_read_data), .mem_read_data_out(wb_mem_data),
        .alu_result_in(mem_alu_result),   .alu_result_out(wb_alu_res),
        .rd_addr_in(mem_rd_addr),         .rd_addr_out(wb_rd_addr),
        .pc_plus4_in(mem_pc4),            .pc_plus4_out(wb_pc4)
    );

 writeback_stage WB_INST (
    .mem_to_reg(wb_to_reg_ctrl),
    .alu_result(wb_alu_res),
    .mem_data(wb_mem_data),
    .pc_plus4(wb_pc4),
    .wb_write_data(wb_write_data)
);

    // ------------------------------------------------------------------------
    // IRQ interface placeholder (until trap/CSR path is integrated)
    // ------------------------------------------------------------------------
    // Lint-safe unused IRQ handling
wire unused_irq;
assign unused_irq = irq_i | (|irq_id_i);
    // Acknowledge if any IRQ comes (temporary behavior)
assign irq_ack_o = irq_i;

    assign debug_pc         = id_pc;
    assign debug_alu_result = ex_alu_res;

endmodule
