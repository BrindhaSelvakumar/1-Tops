`timescale 1ns/1ps

module decode_stage_assert (

    input logic        clk,
    input logic        rst_n,

    input logic [31:0] instr,

    input logic [4:0]  rs1_addr,
    input logic [4:0]  rs2_addr,
    input logic [4:0]  rd_addr,

    input logic [2:0]  funct3,
    input logic [6:0]  funct7,

    input logic        pc_write,
    input logic        if_id_write,
    input logic        ctrl_mux_sel,

    input logic        reg_write,
    input logic        mem_read,
    input logic        mem_write,
    input logic        branch,
    input logic        jump,

    input logic        ex_mem_read,
    input logic [4:0]  ex_rd_addr,
    input logic        m_unit_busy
);

////////////////////////////////////////////////////////
// Instruction field extraction
////////////////////////////////////////////////////////

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    rs1_addr == instr[19:15]
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    rs2_addr == instr[24:20]
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    rd_addr == instr[11:7]
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    funct3 == instr[14:12]
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    funct7 == instr[31:25]
);

////////////////////////////////////////////////////////
// M-extension stall
////////////////////////////////////////////////////////

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    m_unit_busy |->
    (!pc_write && !if_id_write && ctrl_mux_sel)
);

////////////////////////////////////////////////////////
// Load-use hazard stall
////////////////////////////////////////////////////////

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    (ex_mem_read &&
     (ex_rd_addr != 5'd0) &&
     ((ex_rd_addr == rs1_addr) ||
      (ex_rd_addr == rs2_addr)))
    |->
    (!pc_write && !if_id_write && ctrl_mux_sel)
);

////////////////////////////////////////////////////////
// Control flush checks
////////////////////////////////////////////////////////

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    ctrl_mux_sel |-> !reg_write
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    ctrl_mux_sel |-> !mem_read
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    ctrl_mux_sel |-> !mem_write
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    ctrl_mux_sel |-> !branch
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    ctrl_mux_sel |-> !jump
);

endmodule
