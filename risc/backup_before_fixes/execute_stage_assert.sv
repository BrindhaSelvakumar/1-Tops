
// execute_stage_assert.sv
// Functional assertion file for execute_stage
// Assumes this module is instantiated with DUT signals connected.
// Hierarchical references (dut.*) are used for internal signals.

module execute_stage_assert(
    input logic clk,
    input logic rst_n,

    input logic [31:0] ex_pc,
    input logic [31:0] rdata1,
    input logic [31:0] rdata2,
    input logic [31:0] imm,
    input logic [2:0] funct3,
    input logic [4:0] alu_ctrl,
    input logic [1:0] op1_src,
    input logic alu_src_ctrl,
    input logic m_ext_ctrl,
    input logic jump_ctrl,
    input logic branch_ctrl,
    input logic [31:0] mem_alu_result,
    input logic [31:0] wb_data,
    input logic [1:0] forward_a,
    input logic [1:0] forward_b,
    input logic [31:0] final_result,
    input logic [31:0] branch_target,
    input logic [31:0] jump_target,
    input logic branch_taken,
    input logic m_unit_busy,
    input logic [31:0] fwd_rs2_out
);

// 1
property p_forwardA_mem; @(posedge clk) disable iff(!rst_n)
forward_a==2'b10 |-> dut.fwd_rs1==mem_alu_result; endproperty
assert property(p_forwardA_mem);

//2
property p_forwardA_wb; @(posedge clk) disable iff(!rst_n)
forward_a==2'b01 |-> dut.fwd_rs1==wb_data; endproperty
assert property(p_forwardA_wb);

//3
property p_forwardA_reg; @(posedge clk) disable iff(!rst_n)
forward_a==2'b00 |-> dut.fwd_rs1==rdata1; endproperty
assert property(p_forwardA_reg);

//4
property p_forwardB_mem; @(posedge clk) disable iff(!rst_n)
forward_b==2'b10 |-> dut.fwd_rs2==mem_alu_result; endproperty
assert property(p_forwardB_mem);

//5
property p_forwardB_wb; @(posedge clk) disable iff(!rst_n)
forward_b==2'b01 |-> dut.fwd_rs2==wb_data; endproperty
assert property(p_forwardB_wb);

//6
property p_forwardB_reg; @(posedge clk) disable iff(!rst_n)
forward_b==2'b00 |-> dut.fwd_rs2==rdata2; endproperty
assert property(p_forwardB_reg);

//7
property p_rs2_out; @(posedge clk) disable iff(!rst_n)
fwd_rs2_out==dut.fwd_rs2; endproperty
assert property(p_rs2_out);

//8
property p_opA_pc; @(posedge clk) disable iff(!rst_n)
op1_src==2'b01 |-> dut.alu_in_a==ex_pc; endproperty
assert property(p_opA_pc);

//9
property p_opA_zero; @(posedge clk) disable iff(!rst_n)
op1_src==2'b10 |-> dut.alu_in_a==32'h0; endproperty
assert property(p_opA_zero);

//10
property p_opA_rs1; @(posedge clk) disable iff(!rst_n)
op1_src==2'b00 |-> dut.alu_in_a==dut.fwd_rs1; endproperty
assert property(p_opA_rs1);

//11
property p_opB_imm; @(posedge clk) disable iff(!rst_n)
alu_src_ctrl |-> dut.alu_in_b==imm; endproperty
assert property(p_opB_imm);

//12
property p_opB_rs2; @(posedge clk) disable iff(!rst_n)
!alu_src_ctrl |-> dut.alu_in_b==dut.fwd_rs2; endproperty
assert property(p_opB_rs2);

//13
property p_std_result; @(posedge clk) disable iff(!rst_n)
!m_ext_ctrl |-> final_result==dut.std_res; endproperty
assert property(p_std_result);

//14
property p_mext_result; @(posedge clk) disable iff(!rst_n)
m_ext_ctrl |-> final_result==dut.m_res; endproperty
assert property(p_mext_result);

//15
property p_branch_target; @(posedge clk) disable iff(!rst_n)
branch_target==(ex_pc+imm); endproperty
assert property(p_branch_target);

//16
property p_jump_target_jal; @(posedge clk) disable iff(!rst_n)
jump_ctrl && !(funct3==3'b000) |-> jump_target==(ex_pc+imm); endproperty
assert property(p_jump_target_jal);

//17
property p_jump_target_jalr_align; @(posedge clk) disable iff(!rst_n)
jump_ctrl && funct3==3'b000 |-> jump_target[0]==1'b0; endproperty
assert property(p_jump_target_jalr_align);

//18
property p_beq; @(posedge clk) disable iff(!rst_n)
branch_ctrl && funct3==3'b000 && dut.alu_zero |-> branch_taken; endproperty
assert property(p_beq);

//19
property p_bne; @(posedge clk) disable iff(!rst_n)
branch_ctrl && funct3==3'b001 && !dut.alu_zero |-> branch_taken; endproperty
assert property(p_bne);

//20
property p_busy_only_mext; @(posedge clk) disable iff(!rst_n)
m_unit_busy |-> m_ext_ctrl; endproperty
assert property(p_busy_only_mext);

//21
property p_no_x_result; @(posedge clk) disable iff(!rst_n)
!$isunknown(final_result); endproperty
assert property(p_no_x_result);

//22
property p_no_x_branch; @(posedge clk) disable iff(!rst_n)
!$isunknown(branch_target); endproperty
assert property(p_no_x_branch);

//23
property p_no_x_jump; @(posedge clk) disable iff(!rst_n)
!$isunknown(jump_target); endproperty
assert property(p_no_x_jump);

//24
cover property(@(posedge clk) forward_a==2'b10);
cover property(@(posedge clk) forward_b==2'b10);
cover property(@(posedge clk) branch_ctrl);
cover property(@(posedge clk) jump_ctrl);
cover property(@(posedge clk) m_ext_ctrl);

//25
cover property(@(posedge clk) funct3==3'b000);
cover property(@(posedge clk) funct3==3'b001);

endmodule
