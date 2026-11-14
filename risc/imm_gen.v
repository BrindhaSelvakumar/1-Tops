`timescale 1ns / 1ps

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);

    wire [6:0] opcode;
    assign opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // =========================
            // I-TYPE (LOAD / ALU IMM / JALR)
            // =========================
            7'b0000011,
            7'b0010011,
            7'b1100111: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // =========================
            // S-TYPE (STORE)
            // =========================
            7'b0100011: begin
                imm = {{20{instr[31]}},
                       instr[31:25],
                       instr[11:7]};
            end

            // =========================
            // B-TYPE (BRANCH)
            // imm[12|10:5|4:1|11|0]
            // =========================
            7'b1100011: begin
                imm = {{19{instr[31]}},
                       instr[31],        // imm[12]
                       instr[7],         // imm[11]
                       instr[30:25],     // imm[10:5]
                       instr[11:8],      // imm[4:1]
                       1'b0};            // imm[0]
            end

            // =========================
            // U-TYPE (LUI / AUIPC)
            // =========================
            7'b0110111,
            7'b0010111: begin
                imm = {instr[31:12], 12'b0};
            end

            // =========================
            // J-TYPE (JAL)
            // imm[20|10:1|11|19:12|0]
            // =========================
            7'b1101111: begin
                imm = {{12{instr[31]}},   // 12 bits sign extension
                       instr[19:12],
                       instr[20],
                       instr[30:21],
                       1'b0};            // imm[0]
            end

            // =========================
            // DEFAULT
            // =========================
            default: begin
                imm = 32'b0;
            end

        endcase
    end

endmodule
