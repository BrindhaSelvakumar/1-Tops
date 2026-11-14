`timescale 1ns / 1ps
`ifndef DEFINES_V
`define DEFINES_V

// ============================================================
// RISC-V RV32IM CONTROL & OPERATION DEFINES
// ============================================================

// ALU Operations (4-bit)
`define ALU_ADD     4'd0
`define ALU_SUB     4'd1
`define ALU_AND     4'd2
`define ALU_OR      4'd3
`define ALU_XOR     4'd4
`define ALU_SLL     4'd5
`define ALU_SRL     4'd6
`define ALU_SRA     4'd7
`define ALU_SLT     4'd8
`define ALU_SLTU    4'd9
`define ALU_LUI     4'd10
`define ALU_AUIPC   4'd11

// M-Extension Operations (3-bit)
`define MU_MUL      3'd0
`define MU_MULH     3'd1
`define MU_MULHSU   3'd2
`define MU_MULHU    3'd3
`define MU_DIV      3'd4
`define MU_DIVU     3'd5
`define MU_REM      3'd6
`define MU_REMU     3'd7

// Writeback Multiplexer Select (2-bit)
`define WB_ALU      2'b00
`define WB_MEM      2'b01
`define WB_PC4      2'b10

// Standard NOP Instruction (ADDI x0, x0, 0)
`define NOP_INSTR   32'h0000_0013

`endif // DEFINES_V

