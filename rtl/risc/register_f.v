`timescale 1ns / 1ps

module register_f #(parameter width = 32) (
    input  wire clk,
    input  wire rst_n,
    input  wire write_en,
    input  wire [4:0] rd_addr,
    input  wire [width-1:0] write_data,
    input  wire [4:0] rs1_addr,
    input  wire [4:0] rs2_addr,
    output wire [width-1:0] rs1_data,
    output wire [width-1:0] rs2_data
);

    reg [width-1:0] registers [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= {width{1'b0}};
        end else if (write_en && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= write_data;
        end
    end

    assign rs1_data =
        (rs1_addr == 5'd0) ? {width{1'b0}} :
        (write_en && (rd_addr == rs1_addr) && (rd_addr != 5'd0)) ? write_data :
        registers[rs1_addr];

    assign rs2_data =
        (rs2_addr == 5'd0) ? {width{1'b0}} :
        (write_en && (rd_addr == rs2_addr) && (rd_addr != 5'd0)) ? write_data :
        registers[rs2_addr];

endmodule
