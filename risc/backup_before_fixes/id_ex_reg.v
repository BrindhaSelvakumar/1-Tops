module id_ex_reg (
    input  wire clk,
    input  wire rst_n,
    input  wire flush,
    input  wire stall,

    input  wire        reg_write_in,
    input  wire [1:0]  mem_to_reg_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        alu_src_in,
    input  wire [4:0]  alu_ctrl_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        m_ext_in,
    input  wire [1:0]  op_src_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,

    input  wire [31:0] pc_in,
    input  wire [31:0] read_data1_in,
    input  wire [31:0] read_data2_in,
    input  wire [31:0] imm_in,

    input  wire [4:0]  rd_addr_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,

    output reg         reg_write_out,
    output reg  [1:0]  mem_to_reg_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         alu_src_out,
    output reg  [4:0]  alu_ctrl_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg         m_ext_out,
    output reg  [1:0]  op_src_out,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  funct7_out,

    output reg  [31:0] pc_out,
    output reg  [31:0] read_data1_out,
    output reg  [31:0] read_data2_out,
    output reg  [31:0] imm_out,

    output reg  [4:0]  rd_addr_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_write_out  <= 0;
        mem_to_reg_out <= 0;
        mem_read_out   <= 0;
        mem_write_out  <= 0;
        alu_src_out    <= 0;
        alu_ctrl_out   <= 0;
        branch_out     <= 0;
        jump_out       <= 0;
        m_ext_out      <= 0;
        op_src_out     <= 0;

        funct3_out     <= 0;
        funct7_out     <= 0;

        pc_out         <= 0;
        read_data1_out <= 0;
        read_data2_out <= 0;
        imm_out        <= 0;

        rd_addr_out    <= 0;
        rs1_addr_out   <= 0;
        rs2_addr_out   <= 0;
    end
    else if (flush) begin
    reg_write_out  <= 1'b0;
    mem_to_reg_out <= 2'b00;
    mem_read_out   <= 1'b0;
    mem_write_out  <= 1'b0;
    alu_src_out    <= 1'b0;
    alu_ctrl_out   <= 5'b00000;
    branch_out     <= 1'b0;
    jump_out       <= 1'b0;
    m_ext_out      <= 1'b0;
    op_src_out     <= 2'b00;

    funct3_out     <= 3'b000;
    funct7_out     <= 7'b0000000;

    pc_out         <= 32'h0000_0000;
    read_data1_out <= 32'h0000_0000;
    read_data2_out <= 32'h0000_0000;
    imm_out        <= 32'h0000_0000;

    rd_addr_out    <= 5'd0;
    rs1_addr_out   <= 5'd0;
    rs2_addr_out   <= 5'd0;
    end
    else if (!stall) begin
        reg_write_out  <= reg_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        alu_src_out    <= alu_src_in;
        alu_ctrl_out   <= alu_ctrl_in;
        branch_out     <= branch_in;
        jump_out       <= jump_in;
        m_ext_out      <= m_ext_in;
        op_src_out     <= op_src_in;

        funct3_out     <= funct3_in;
        funct7_out     <= funct7_in;

        pc_out         <= pc_in;
        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        imm_out        <= imm_in;

        rd_addr_out    <= rd_addr_in;
        rs1_addr_out   <= rs1_addr_in;
        rs2_addr_out   <= rs2_addr_in;
    end

end

endmodule
