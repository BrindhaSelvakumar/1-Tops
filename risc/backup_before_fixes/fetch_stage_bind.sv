`timescale 1ns/1ps

bind fetch_stage fetch_stage_sva u_fetch_stage_sva (
    .clk              (clk),
    .rst_n            (rst_n),
    .branch_taken     (branch_taken),
    .jump             (jump),
    .branch_target    (branch_target),
    .jump_target      (jump_target),
    .stall_all        (stall_all),
    .IHADDR           (IHADDR),
    .IHTRANS          (IHTRANS),
    .IHWRITE          (IHWRITE),
    .IHSIZE           (IHSIZE),
    .IHREADY          (IHREADY),
    .IHRDATA          (IHRDATA),
    .pc_dbg               (pc),
    .kill_fetch_resp_dbg  (kill_fetch_resp),
    .pc_out           (pc_out),
    .instr_out        (instr_out)

);
