`timescale 1ns / 1ps

module mem_wb_reg (
input  wire clk,
input  wire rst_n,
input  wire stall,

input  wire reg_write_in,
input  wire [1:0]  mem_to_reg_in,
input  wire [31:0] mem_read_data_in,
input  wire [31:0] alu_result_in,
input  wire [4:0]  rd_addr_in,
input  wire [31:0] pc_plus4_in,

output reg         reg_write_out,
output reg  [1:0]  mem_to_reg_out,
output reg  [31:0] mem_read_data_out,
output reg  [31:0] alu_result_out,
output reg  [4:0]  rd_addr_out,
output reg  [31:0] pc_plus4_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_write_out     <= 0;
        mem_to_reg_out    <= 0;
        mem_read_data_out <= 0;
        alu_result_out    <= 0;
        rd_addr_out       <= 0;
        pc_plus4_out      <= 0;
    end

    // IMPORTANT: HOLD STATE WHEN STALL = 1
    else if (!stall) begin
        reg_write_out     <= reg_write_in;
        mem_to_reg_out    <= mem_to_reg_in;
        mem_read_data_out <= mem_read_data_in;
        alu_result_out    <= alu_result_in;
        rd_addr_out       <= rd_addr_in;
        pc_plus4_out      <= pc_plus4_in;
    end
end

endmodule
