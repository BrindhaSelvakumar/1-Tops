module writeback_stage (
    input  wire [1:0]  mem_to_reg,
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_data,
    input  wire [31:0] pc_plus4,

    output reg  [31:0] wb_write_data
);

    always @(mem_to_reg or alu_result or mem_data or pc_plus4) begin
        case (mem_to_reg)
            2'b00: wb_write_data = alu_result;
            2'b01: wb_write_data = mem_data;
            2'b10: wb_write_data = pc_plus4;
            default: wb_write_data = 32'h0000_0000;
        endcase
    end

endmodule
