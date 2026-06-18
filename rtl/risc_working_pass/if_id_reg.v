`timescale 1ns / 1ps

module if_id_reg (
    input  wire clk,
    input  wire rst_n,
    input  wire flush,
    input  wire stall,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        instr_out <= 32'h00000013;
        pc_out    <= 32'h00000000;
    end
    else if (flush) begin
        instr_out <= 32'h00000013;
        pc_out    <= 32'h00000000;
    end
    else if (!stall) begin
        instr_out <= instr_in;
        pc_out    <= pc_in;
    end
    // else stall: hold previous value
end

endmodule
