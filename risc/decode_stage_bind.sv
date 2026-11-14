

`timescale 1ns/1ps

//////////////////////////////////////////////////////////////
// Bind Assertions
//////////////////////////////////////////////////////////////

bind decode_stage decode_stage_assert u_decode_stage_assert (

    .clk(clk),
    .rst_n(rst_n),

    .instr(instr),

    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_addr(rd_addr),

    .funct3(funct3),
    .funct7(funct7),

    .pc_write(pc_write),
    .if_id_write(if_id_write),
    .ctrl_mux_sel(ctrl_mux_sel),

    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),

    .ex_mem_read(ex_mem_read),
    .ex_rd_addr(ex_rd_addr),
    .m_unit_busy(m_unit_busy)
);

//////////////////////////////////////////////////////////////
// Bind Coverage
//////////////////////////////////////////////////////////////

bind decode_stage decode_stage_cover u_decode_stage_cover (

    .clk(clk),
    .rst_n(rst_n),

    .instr(instr),

    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),

    .pc_write(pc_write),
    .if_id_write(if_id_write),
    .ctrl_mux_sel(ctrl_mux_sel),

    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),

    .ex_mem_read(ex_mem_read),
    .ex_rd_addr(ex_rd_addr),
    .m_unit_busy(m_unit_busy)
);
