
`timescale 1ns/1ps
`include "defines.v"

module tb_wb_stage;

    //=========================================================================
    // DUT port declarations
    //=========================================================================
    // All inputs are reg (driven by TB)
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_data;
    logic [31:0] mem_wb_pc4;
    logic [ 4:0] mem_wb_rd;
    logic        mem_wb_reg_write;
    logic [ 1:0] mem_wb_wb_sel;

    // Outputs (wire — combinational)
    wire  [31:0] wb_data;
    wire  [ 4:0] wb_rd;
    wire         wb_reg_write;

    //=========================================================================
    // DUT instantiation
    //=========================================================================
    wb_stage dut (.*);

    //=========================================================================
    // Scoreboard helpers
    //=========================================================================
    int pass_cnt = 0, fail_cnt = 0;

    task automatic ck32(
        input string   label,
        input logic [31:0] got,
        input logic [31:0] exp
    );
        if (got === exp) begin
            $display("    PASS  %-60s  got=%08h", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-60s  got=%08h  exp=%08h", label, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic ck5(
        input string  label,
        input logic [4:0] got,
        input logic [4:0] exp
    );
        if (got === exp) begin
            $display("    PASS  %-60s  got=%02d", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-60s  got=%02d  exp=%02d", label, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic ck1(
        input string label,
        input logic  got,
        input logic  exp
    );
        if (got === exp) begin
            $display("    PASS  %-60s  got=%0b", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-60s  got=%0b  exp=%0b", label, got, exp);
            fail_cnt++;
        end
    endtask

    // Propagation settle time (combinational design)
    task settle(); #1; endtask

    //=========================================================================
    // Helper: drive all three data sources at once, set wb_sel and rd
    //=========================================================================
    task drive(
        input [31:0] alu_r,
        input [31:0] load_d,
        input [31:0] pc4_v,
        input [ 4:0] rd_v,
        input        rw,
        input [ 1:0] sel
    );
        mem_wb_alu_result = alu_r;
        mem_wb_load_data  = load_d;
        mem_wb_pc4        = pc4_v;
        mem_wb_rd         = rd_v;
        mem_wb_reg_write  = rw;
        mem_wb_wb_sel     = sel;
        settle();
    endtask

    //=========================================================================
    // Test sequence
    //=========================================================================
    initial begin
        $display("\n");
        $display("╔═══════════════════════════════════════════════════════════╗");
        $display("║          TB: wb_stage   —  Standalone Testbench          ║");
        $display("╚═══════════════════════════════════════════════════════════╝");

        // Initialise inputs to safe defaults
        mem_wb_alu_result = 32'h0;
        mem_wb_load_data  = 32'h0;
        mem_wb_pc4        = 32'h4;
        mem_wb_rd         = 5'd0;
        mem_wb_reg_write  = 1'b0;
        mem_wb_wb_sel     = `WB_ALU;
        settle();

        // ==================================================================
        // GROUP A — wb_sel mux
        // ==================================================================
        $display("\n  ── GROUP A : wb_sel mux ──");

        // TC01: WB_ALU → wb_data = alu_result
        $display("  [TC01] wb_sel = WB_ALU  →  wb_data = alu_result");
        drive(32'hAAAA_1111,   // alu
              32'hBBBB_2222,   // load
              32'hCCCC_3333,   // pc4
              5'd1, 1'b1, `WB_ALU);
        ck32("WB_ALU selects alu_result", wb_data, 32'hAAAA_1111);

        // TC02: WB_MEM → wb_data = load_data
        $display("  [TC02] wb_sel = WB_MEM  →  wb_data = load_data");
        drive(32'hAAAA_1111, 32'hBBBB_2222, 32'hCCCC_3333,
              5'd2, 1'b1, `WB_MEM);
        ck32("WB_MEM selects load_data", wb_data, 32'hBBBB_2222);

        // TC03: WB_PC4 → wb_data = pc4
        $display("  [TC03] wb_sel = WB_PC4  →  wb_data = pc4");
        drive(32'hAAAA_1111, 32'hBBBB_2222, 32'hCCCC_3333,
              5'd3, 1'b1, `WB_PC4);
        ck32("WB_PC4 selects pc4", wb_data, 32'hCCCC_3333);

        // ==================================================================
        // GROUP B — rd and reg_write pass-through
        // ==================================================================
        $display("\n  ── GROUP B : rd and reg_write pass-through ──");

        // TC04: rd pass-through for every register index 0..31
        $display("  [TC04] wb_rd pass-through for x0 .. x31");
        for (int r = 0; r < 32; r++) begin
            drive(32'h0, 32'h0, 32'h0, 5'(r), 1'b1, `WB_ALU);
            ck5($sformatf("wb_rd = x%0d", r), wb_rd, 5'(r));
        end

        // TC05: reg_write=1 passes through
        $display("  [TC05] reg_write=1 passes through");
        drive(32'hDEAD_BEEF, 32'h0, 32'h0, 5'd7, 1'b1, `WB_ALU);
        ck1("wb_reg_write=1", wb_reg_write, 1'b1);

        // TC06: reg_write=0 passes through
        $display("  [TC06] reg_write=0 passes through");
        drive(32'hDEAD_BEEF, 32'h0, 32'h0, 5'd7, 1'b0, `WB_ALU);
        ck1("wb_reg_write=0", wb_reg_write, 1'b0);

        // ==================================================================
        // GROUP C — source independence
        // ==================================================================
        $display("\n  ── GROUP C : Source independence ──");

        // TC07: Changing alu_result must NOT affect WB_MEM output
        $display("  [TC07] Changing alu_result does not affect WB_MEM selection");
        drive(32'h1234_5678, 32'hABCD_EF01, 32'h0, 5'd5, 1'b1, `WB_MEM);
        ck32("WB_MEM unchanged when alu_result changes", wb_data, 32'hABCD_EF01);
        mem_wb_alu_result = 32'hFFFF_FFFF; settle();
        ck32("WB_MEM still selects load_data after alu change",
             wb_data, 32'hABCD_EF01);

        // TC08: Changing load_data does NOT affect WB_ALU output
        $display("  [TC08] Changing load_data does not affect WB_ALU selection");
        drive(32'h0102_0304, 32'hAAAA_BBBB, 32'h0, 5'd5, 1'b1, `WB_ALU);
        ck32("WB_ALU ignores load_data", wb_data, 32'h0102_0304);
        mem_wb_load_data = 32'hFFFF_FFFF; settle();
        ck32("WB_ALU still selects alu_result after load change",
             wb_data, 32'h0102_0304);

        // TC09: Changing pc4 does NOT affect WB_ALU output
        $display("  [TC09] Changing pc4 does not affect WB_ALU selection");
        drive(32'hCAFE_CAFE, 32'h0, 32'h1000, 5'd5, 1'b1, `WB_ALU);
        ck32("WB_ALU ignores pc4", wb_data, 32'hCAFE_CAFE);
        mem_wb_pc4 = 32'hDEAD_DEAD; settle();
        ck32("WB_ALU still selects alu_result after pc4 change",
             wb_data, 32'hCAFE_CAFE);

        // ==================================================================
        // GROUP D — boundary / corner values
        // ==================================================================
        $display("\n  ── GROUP D : Boundary and corner values ──");

        // TC10: All-zero ALU result
        $display("  [TC10] wb_data = 0x00000000  (all-zero, WB_ALU)");
        drive(32'h0000_0000, 32'h1234_5678, 32'h9ABC_DEF0,
              5'd1, 1'b1, `WB_ALU);
        ck32("wb_data = 0x0000_0000", wb_data, 32'h0000_0000);

        // TC11: All-ones ALU result
        $display("  [TC11] wb_data = 0xFFFFFFFF  (all-ones, WB_ALU)");
        drive(32'hFFFF_FFFF, 32'h0, 32'h0, 5'd1, 1'b1, `WB_ALU);
        ck32("wb_data = 0xFFFF_FFFF", wb_data, 32'hFFFF_FFFF);

        // TC12: MSB-only MEM data
        $display("  [TC12] wb_data = 0x80000000  (MSB set, WB_MEM)");
        drive(32'h0, 32'h8000_0000, 32'h0, 5'd2, 1'b1, `WB_MEM);
        ck32("wb_data = 0x8000_0000", wb_data, 32'h8000_0000);

        // TC13: Typical JAL link address (PC+4)
        $display("  [TC13] wb_data = 0x00000004  (typical PC+4, WB_PC4)");
        drive(32'h0, 32'h0, 32'h0000_0004, 5'd1, 1'b1, `WB_PC4);
        ck32("wb_data = 0x0000_0004", wb_data, 32'h0000_0004);

        // TC14: rd = x0
        $display("  [TC14] rd = x0  (reg_write still passes through)");
        drive(32'h42, 32'h0, 32'h0, 5'd0, 1'b1, `WB_ALU);
        ck5("wb_rd = 0", wb_rd, 5'd0);
        ck1("wb_reg_write = 1 (x0 guard is in ID, not WB)", wb_reg_write, 1'b1);

        // TC15: rd = x31
        $display("  [TC15] rd = x31  (maximum register index)");
        drive(32'h55AA_55AA, 32'h0, 32'h0, 5'd31, 1'b1, `WB_ALU);
        ck5("wb_rd = 31", wb_rd, 5'd31);
        ck32("wb_data for x31", wb_data, 32'h55AA_55AA);

        // ==================================================================
        // GROUP E — rapid wb_sel transitions
        // ==================================================================
        $display("\n  ── GROUP E : Rapid wb_sel transitions ──");

        // TC16: Cycle through all three sel values in consecutive delta steps
        $display("  [TC16] Rapid ALU→MEM→PC4→ALU transitions");
        drive(32'h0000_0001, 32'h0000_0002, 32'h0000_0004, 5'd10, 1'b1, `WB_ALU);
        ck32("sel=ALU → 0x1", wb_data, 32'h0000_0001);
        mem_wb_wb_sel = `WB_MEM; settle();
        ck32("sel=MEM → 0x2", wb_data, 32'h0000_0002);
        mem_wb_wb_sel = `WB_PC4; settle();
        ck32("sel=PC4 → 0x4", wb_data, 32'h0000_0004);
        mem_wb_wb_sel = `WB_ALU; settle();
        ck32("sel=ALU → 0x1 again", wb_data, 32'h0000_0001);

        // TC17: Two logical instructions back-to-back
        $display("  [TC17] Two back-to-back writes: ADD then LW");
        // Instruction 1: ADD x5 = 0xABCD_1234  (WB_ALU, rd=5)
        drive(32'hABCD_1234, 32'h0, 32'h0, 5'd5, 1'b1, `WB_ALU);
        ck32("instr1: ADD x5 wb_data",  wb_data,      32'hABCD_1234);
        ck5 ("instr1: wb_rd = 5",       wb_rd,         5'd5);
        ck1 ("instr1: reg_write = 1",   wb_reg_write,  1'b1);
        // Instruction 2: LW x9 = 0x0000_00FF  (WB_MEM, rd=9)
        drive(32'h0, 32'h0000_00FF, 32'h0, 5'd9, 1'b1, `WB_MEM);
        ck32("instr2: LW  x9 wb_data",  wb_data,      32'h0000_00FF);
        ck5 ("instr2: wb_rd = 9",       wb_rd,         5'd9);
        ck1 ("instr2: reg_write = 1",   wb_reg_write,  1'b1);

        // ==================================================================
        // Summary
        // ==================================================================
        $display("\n╔═══════════════════════════════════════════════════════════╗");
        $display("║  wb_stage TB  :  %3d passed    %3d failed                 ║",
                  pass_cnt, fail_cnt);
        $display("╚═══════════════════════════════════════════════════════════╝");
        if (fail_cnt == 0)
            $display("✅  ALL wb_stage TESTS PASSED\n");
        else
            $display("❌  FAILURES — see above\n");
        $finish;
    end

endmodule
