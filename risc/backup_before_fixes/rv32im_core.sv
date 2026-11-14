`timescale 1ns/1ps

module rv32im_core (
    input  wire clk,
    input  wire rst_n,

    //================ AHB Instruction =================
    output wire [31:0] IHADDR,
    output wire [1:0]  IHTRANS,
    output wire        IHWRITE,
    output wire [2:0]  IHSIZE,
    output wire [2:0]  IHBURST,
    output wire [3:0]  IHPROT,
    input  wire [31:0] IHRDATA,
    input  wire        IHREADY,
    input  wire        IHRESP,

    //================ AHB Data =================
    output wire [31:0] DHADDR,
    output wire [1:0]  DHTRANS,
    output wire        DHWRITE,
    output wire [2:0]  DHSIZE,
    output wire [2:0]  DHBURST,
    output wire [3:0]  DHPROT,
    output wire [31:0] DHWDATA,
    input  wire [31:0] DHRDATA,
    input  wire        DHREADY,
    input  wire        DHRESP
);

    //================ WIRES =================

    // IF/ID
    wire [31:0] if_id_pc, if_id_pc4, if_id_instr;

    // Branch
    wire branch_taken;
    wire [31:0] branch_target;

    // ID/EX
    wire [31:0] id_ex_pc, id_ex_pc4;
    wire [31:0] id_ex_rs1_data, id_ex_rs2_data;
    wire [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    wire [31:0] id_ex_imm;
    wire [3:0]  id_ex_alu_op;
    wire [2:0]  id_ex_mu_op;
    wire        id_ex_alu_src;
    wire        id_ex_mem_read, id_ex_mem_write;
    wire [2:0]  id_ex_mem_size;
    wire        id_ex_reg_write;
    wire [1:0]  id_ex_wb_sel;
    wire        id_ex_is_muldiv, id_ex_auipc;

    // EX/MEM
    wire [31:0] ex_mem_alu_result, ex_mem_rs2_data, ex_mem_pc4;
    wire [4:0]  ex_mem_rd;
    wire [2:0]  ex_mem_mem_size;
    wire        ex_mem_mem_read, ex_mem_mem_write;
    wire        ex_mem_reg_write;
    wire [1:0]  ex_mem_wb_sel;

    // MEM/WB
    wire [31:0] mem_wb_alu_result, mem_wb_load_data, mem_wb_pc4;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_write;
    wire [1:0]  mem_wb_wb_sel;

    // WB
    wire [31:0] wb_data;
    wire [4:0]  wb_rd;
    wire        wb_reg_write;

    assign wb_rd        = mem_wb_rd;
    assign wb_reg_write = mem_wb_reg_write;

    // Hazard
    wire load_use_hazard;
    wire div_stall, mem_stall;
    wire stall_if, stall_id, stall_ex;
    wire flush_if, flush_id, flush_ex, flush_mem;

    //================ STAGE 1: IF =================
    if_stage u_if (
        .clk(clk),
        .rst_n(rst_n),
        .stall_if(stall_if),
        .flush_if(flush_if),
        .branch_target(branch_target),

        .IHADDR(IHADDR),
        .IHTRANS(IHTRANS),
        .IHWRITE(IHWRITE),
        .IHSIZE(IHSIZE),
        .IHBURST(IHBURST),
        .IHPROT(IHPROT),
        .IHRDATA(IHRDATA),
        .IHREADY(IHREADY),
        .IHRESP(IHRESP),

        .if_id_pc(if_id_pc),
        .if_id_pc4(if_id_pc4),
        .if_id_instr(if_id_instr)
    );

    //================ STAGE 2: ID =================
    id_stage u_id (
        .clk(clk),
        .rst_n(rst_n),

        .if_id_pc(if_id_pc),
        .if_id_pc4(if_id_pc4),
        .if_id_instr(if_id_instr),

        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data),

        .stall_id(stall_id),
        .flush_id(flush_id),
        .load_use_hazard(load_use_hazard),

        .ex_mem_read(id_ex_mem_read),
        .ex_rd(id_ex_rd),

        .branch_taken(branch_taken),
        .branch_target(branch_target),

        .id_ex_pc(id_ex_pc),
        .id_ex_pc4(id_ex_pc4),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_imm(id_ex_imm),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_mu_op(id_ex_mu_op),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_wb_sel(id_ex_wb_sel),
        .id_ex_is_muldiv(id_ex_is_muldiv),
        .id_ex_auipc(id_ex_auipc)
    );

    //================ STAGE 3: EX =================
    ex_stage u_ex (
        .clk(clk),
        .rst_n(rst_n),
        .flush_ex(flush_ex),

        .id_ex_pc(id_ex_pc),
        .id_ex_pc4(id_ex_pc4),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_imm(id_ex_imm),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_mu_op(id_ex_mu_op),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_size(id_ex_mem_size),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_wb_sel(id_ex_wb_sel),
        .id_ex_is_muldiv(id_ex_is_muldiv),
        .id_ex_auipc(id_ex_auipc),

        .fwd_mem_result(ex_mem_alu_result),
        .fwd_wb_data(wb_data),

        .div_stall(div_stall),

        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_pc4(ex_mem_pc4),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_size(ex_mem_mem_size),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_wb_sel(ex_mem_wb_sel)
    );
    //================ STAGE 4: MEM =================
    mem_stage u_mem (
        .clk(clk),
        .rst_n(rst_n),
        .flush_mem(flush_mem),

        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_pc4(ex_mem_pc4),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_size(ex_mem_mem_size),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_mem_write(ex_mem_mem_write),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_wb_sel(ex_mem_wb_sel),

        .DHADDR(DHADDR),
        .DHTRANS(DHTRANS),
        .DHWRITE(DHWRITE),
        .DHSIZE(DHSIZE),
        .DHBURST(DHBURST),
        .DHPROT(DHPROT),
        .DHWDATA(DHWDATA),
        .DHRDATA(DHRDATA),
        .DHREADY(DHREADY),
        .DHRESP(DHRESP),

        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_load_data(mem_wb_load_data),
        .mem_wb_pc4(mem_wb_pc4),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_wb_sel(mem_wb_wb_sel),
        .mem_stall(mem_stall)
    );

    //================ STAGE 5: WB =================
   wb_stage u_wb (
    .mem_wb_alu_result(mem_wb_alu_result),
    .mem_wb_load_data(mem_wb_load_data),
    .mem_wb_pc4(mem_wb_pc4),
    .mem_wb_wb_sel(mem_wb_wb_sel),
    .wb_data(wb_data)
);
    //================ HAZARD =================
    hazard_unit u_haz (
        .load_use_hazard(load_use_hazard),
        .branch_taken(branch_taken),
        .div_stall(div_stall),
        .mem_stall(mem_stall),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .stall_ex(stall_ex),
        .flush_if(flush_if),
        .flush_id(flush_id),
        .flush_ex(flush_ex),
        .flush_mem(flush_mem)
    );

endmodule
