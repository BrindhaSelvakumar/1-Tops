`timescale 1ns / 1ps

module main_ctrl(
    input  wire [6:0] opcode,
    input  wire [6:0] funct7,

    output reg       mem_read,
    output reg       mem_write,
    output reg       reg_write,
    output reg [1:0] mem_to_reg,
    output reg       alu_src,
    output reg       branch,
    output reg       jump,
    output reg       m_ext,
    output reg [1:0] alu_op,
    output reg [1:0] op1_src,
    output reg [1:0] pc_src
);

always @(*) begin
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    reg_write  = 1'b0;
    mem_to_reg = 2'b00;
    alu_src    = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    m_ext      = 1'b0;
    alu_op     = 2'b00;
    op1_src    = 2'b00;
    pc_src     = 2'b00;

    case (opcode)

        // I-TYPE ALU
        7'b0010011: begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
            alu_op    = 2'b11;
        end

        // R-TYPE
        7'b0110011: begin
            reg_write = 1'b1;
            alu_op    = 2'b10;
            m_ext     = (funct7 == 7'b0000001);
        end

        // LOAD
        7'b0000011: begin
            reg_write  = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 2'b01;
            alu_src    = 1'b1;
            alu_op     = 2'b00;
        end

        // STORE
        7'b0100011: begin
            mem_write = 1'b1;
            alu_src   = 1'b1;
            alu_op    = 2'b00;
        end

        // BRANCH
        7'b1100011: begin
            branch = 1'b1;
            alu_op = 2'b01;
            pc_src = 2'b01;
        end

        // JAL
        7'b1101111: begin
            reg_write  = 1'b1;
            jump       = 1'b1;
            mem_to_reg = 2'b10;
            op1_src    = 2'b01;
            pc_src     = 2'b10;
        end

        // JALR
        7'b1100111: begin
            reg_write  = 1'b1;
            jump       = 1'b1;
            alu_src    = 1'b1;
            mem_to_reg = 2'b10;
            op1_src    = 2'b00;
            pc_src     = 2'b11;
        end

        // LUI: rd = imm
        7'b0110111: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            alu_op     = 2'b00;
            mem_to_reg = 2'b00;
            op1_src    = 2'b10; // zero + imm
        end

        // AUIPC: rd = pc + imm
        7'b0010111: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            alu_op     = 2'b00;
            mem_to_reg = 2'b00;
            op1_src    = 2'b01; // pc + imm
        end

        default: begin
            // safe NOP
        end

    endcase
end

endmodule
