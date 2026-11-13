`timescale 1ns / 1ps

module alu_ctrl_32 (
    input  wire [1:0] aluop,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire       m_ext,
    output reg  [4:0] alu_ctrl
);

always @(*) begin

    // -------------------------
    // DEFAULT SAFE STATE
    // -------------------------
    alu_ctrl = 5'b00000;

    case (aluop)

        // =========================
        // LOAD / STORE / ADDI BASE
        // =========================
        2'b00: begin
            alu_ctrl = 5'b00000; // ADD
        end

        // =========================
        // BRANCH (COMPARE LOGIC)
        // =========================
        2'b01: begin
            // SUB used for comparison
            // (zero flag or signed compare in ALU)
            alu_ctrl = 5'b00001;
        end

        // =========================
        // R-TYPE / M-EXTENSION
        // =========================
        2'b10: begin

            if (m_ext) begin
                case (funct3)
                    3'b000: alu_ctrl = 5'b10000; // MUL
                    3'b001: alu_ctrl = 5'b10001; // MULH
                    3'b010: alu_ctrl = 5'b10010; // MULHSU
                    3'b011: alu_ctrl = 5'b10011; // MULHU
                    3'b100: alu_ctrl = 5'b10100; // DIV
                    3'b101: alu_ctrl = 5'b10101; // DIVU
                    3'b110: alu_ctrl = 5'b10110; // REM
                    3'b111: alu_ctrl = 5'b10111; // REMU
                    default: alu_ctrl = 5'b00000; // SAFE FALLBACK
                endcase
            end

            else begin
                case (funct3)

                    3'b000: alu_ctrl = (funct7[5]) ? 5'b00001 : 5'b00000; // ADD/SUB
                    3'b111: alu_ctrl = 5'b00010; // AND
                    3'b110: alu_ctrl = 5'b00011; // OR
                    3'b100: alu_ctrl = 5'b00100; // XOR
                    3'b010: alu_ctrl = 5'b01000; // SLT
                    3'b011: alu_ctrl = 5'b01001; // SLTU
                    3'b001: alu_ctrl = 5'b01101; // SLL
                    3'b101: alu_ctrl = (funct7[5]) ? 5'b01111 : 5'b01110; // SRA/SRL

                    default: alu_ctrl = 5'b00000;
                endcase
            end
        end

        // =========================
        // I-TYPE ALU
        // =========================
        2'b11: begin
            case (funct3)
                3'b000: alu_ctrl = 5'b00000; // ADDI
                3'b010: alu_ctrl = 5'b01000; // SLTI
                3'b011: alu_ctrl = 5'b01001; // SLTIU
                3'b100: alu_ctrl = 5'b00100; // XORI
                3'b110: alu_ctrl = 5'b00011; // ORI
                3'b111: alu_ctrl = 5'b00010; // ANDI
                3'b001: alu_ctrl = 5'b01101; // SLLI
                3'b101: alu_ctrl = (funct7[5]) ? 5'b01111 : 5'b01110; // SRAI / SRLI
                default: alu_ctrl = 5'b00000;
            endcase
        end

        default: begin
            alu_ctrl = 5'b00000;
        end

    endcase
end

endmodule
