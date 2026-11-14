`timescale 1ns/1ps

module fetch_stage_sva (

    input wire        clk,
    input wire        rst_n,

    input wire        branch_taken,
    input wire        jump,
    input wire [31:0] branch_target,
    input wire [31:0] jump_target,

    input wire        stall_all,

    input wire [31:0] IHADDR,
    input wire [1:0]  IHTRANS,
    input wire        IHWRITE,
    input wire [2:0]  IHSIZE,
    input wire        IHREADY,
    input wire [31:0] IHRDATA,

    input wire [31:0] pc_dbg,
    input wire        kill_fetch_resp_dbg,

    input wire [31:0] pc_out,
    input wire [31:0] instr_out
);

//////////////////////////////////////////////////////////
// P1 : PC reset value
//////////////////////////////////////////////////////////

property p_pc_reset;
    @(posedge clk)
    !rst_n |=> (pc_dbg == 32'h0001_0000);
endproperty

A_PC_RESET:
assert property(p_pc_reset);

//////////////////////////////////////////////////////////
// P2 : Address equals PC
//////////////////////////////////////////////////////////

property p_addr_matches_pc;
    @(posedge clk)
    IHADDR == pc_dbg;
endproperty

A_ADDR_MATCHES_PC:
assert property(p_addr_matches_pc);

//////////////////////////////////////////////////////////
// P3 : Instruction bus is read-only
//////////////////////////////////////////////////////////

property p_ihwrite_zero;
    @(posedge clk)
    IHWRITE == 1'b0;
endproperty

A_IHWRITE_ZERO:
assert property(p_ihwrite_zero);

//////////////////////////////////////////////////////////
// P4 : Instruction size always word
//////////////////////////////////////////////////////////

property p_word_access;
    @(posedge clk)
    IHSIZE == 3'b010;
endproperty

A_WORD_ACCESS:
assert property(p_word_access);

//////////////////////////////////////////////////////////
// P5 : IHTRANS idle during reset or stall
//////////////////////////////////////////////////////////

property p_idle_transfer;
    @(posedge clk)
    (!rst_n || stall_all) |-> (IHTRANS == 2'b00);
endproperty

A_IDLE_TRANSFER:
assert property(p_idle_transfer);

//////////////////////////////////////////////////////////
// P6 : IHTRANS non-idle otherwise
//////////////////////////////////////////////////////////

property p_active_transfer;
    @(posedge clk)
    (rst_n && !stall_all) |-> (IHTRANS == 2'b10);
endproperty

A_ACTIVE_TRANSFER:
assert property(p_active_transfer);

//////////////////////////////////////////////////////////
// P7 : Redirect flush
//////////////////////////////////////////////////////////

property p_redirect_flush;
    @(posedge clk)
    disable iff(!rst_n)
    (IHREADY && !stall_all && (jump || branch_taken))
    |=> kill_fetch_resp_dbg;
endproperty

A_REDIRECT_FLUSH:
assert property(p_redirect_flush);

//////////////////////////////////////////////////////////
// P8 : Kill response outputs NOP
//////////////////////////////////////////////////////////

property p_kill_nop;
    @(posedge clk)
    disable iff(!rst_n)
    kill_fetch_resp_dbg |-> (instr_out == 32'h0000_0013);
endproperty

A_KILL_NOP:
assert property(p_kill_nop);

//////////////////////////////////////////////////////////
// P9 : Not ready outputs NOP
//////////////////////////////////////////////////////////

property p_wait_nop;
    @(posedge clk)
    disable iff(!rst_n)
    !IHREADY |-> (instr_out == 32'h0000_0013);
endproperty

A_WAIT_NOP:
assert property(p_wait_nop);

//////////////////////////////////////////////////////////
// COVER PROPERTIES
//////////////////////////////////////////////////////////

// C1 : Reset occurs
cover property (
    @(posedge clk)
    !rst_n
);

// C2 : Normal instruction fetch
cover property (
    @(posedge clk)
    rst_n && IHREADY && !stall_all &&
    !jump && !branch_taken
);

// C3 : Jump instruction fetch
cover property (
    @(posedge clk)
    rst_n && IHREADY && jump
);

// C4 : Branch instruction fetch
cover property (
    @(posedge clk)
    rst_n && IHREADY && branch_taken
);

// C5 : Pipeline stall
cover property (
    @(posedge clk)
    rst_n && stall_all
);

// C6 : Wait state
cover property (
    @(posedge clk)
    rst_n && !IHREADY
);

// C7 : Redirect flush generated
cover property (
    @(posedge clk)
    rst_n &&
    IHREADY &&
    !stall_all &&
    (jump || branch_taken)
    ##1 kill_fetch_resp_dbg
);

// C8 : NOP generated after kill
cover property (
    @(posedge clk)
    rst_n &&
    kill_fetch_resp_dbg &&
    instr_out == 32'h0000_0013
);


endmodule
