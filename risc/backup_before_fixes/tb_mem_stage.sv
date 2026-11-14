
`timescale 1ns/1ps
`include "defines.v"

module tb_mem_stage;

    //=========================================================================
    // DUT port declarations
    //=========================================================================
    logic        clk, rst_n;
    logic        flush_mem = 1'b0;

    // EX/MEM register driven by TB
    logic [31:0] ex_mem_alu_result  = 32'h0;
    logic [31:0] ex_mem_rs2_data    = 32'h0;
    logic [31:0] ex_mem_pc4         = 32'h1004;
    logic [ 4:0] ex_mem_rd          = 5'd5;
    logic [ 2:0] ex_mem_mem_size    = 3'b010;   // LW default
    logic        ex_mem_mem_read    = 1'b0;
    logic        ex_mem_mem_write   = 1'b0;
    logic        ex_mem_reg_write   = 1'b1;
    logic [ 1:0] ex_mem_wb_sel      = `WB_MEM;

    // AHB-Lite data port (driven by slave model)
    logic [31:0] DHADDR;
    logic [ 1:0] DHTRANS;
    logic        DHWRITE;
    logic [ 2:0] DHSIZE, DHBURST;
    logic [ 3:0] DHPROT;
    logic [31:0] DHWDATA;
    logic [31:0] DHRDATA  = 32'h0;
    logic        DHREADY  = 1'b1;
    logic        DHRESP   = 1'b0;

    // MEM/WB outputs
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_data;
    logic [31:0] mem_wb_pc4;
    logic [ 4:0] mem_wb_rd;
    logic        mem_wb_reg_write;
    logic [ 1:0] mem_wb_wb_sel;
    logic [ 2:0] mem_wb_mem_size;
    logic        mem_stall;

    //=========================================================================
    // DUT instantiation
    //=========================================================================
    mem_stage dut (.*);

    //=========================================================================
    // Clock — 100 MHz
    //=========================================================================
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    //=========================================================================
    // 4 KB byte-addressed data SRAM slave model
    //=========================================================================
    logic [7:0]  sram [0:4095];
    logic [31:0] ahb_addr_lat;      // latched address (AHB data phase)

    // Initialise to known pattern: sram[i] = i[7:0]
    initial begin
        for (int i = 0; i < 4096; i++)
            sram[i] = 8'(i);
    end

    // Latch address on rising edge (AHB address phase → data phase)
    always @(posedge clk)
        ahb_addr_lat <= DHADDR;

    // Read data: presented on DHRDATA for data phase
    assign DHRDATA = { sram[ahb_addr_lat + 3],
                       sram[ahb_addr_lat + 2],
                       sram[ahb_addr_lat + 1],
                       sram[ahb_addr_lat    ] };

    // Write: commit on data phase when HWRITE=1, HTRANS=NONSEQ, HREADY=1
    always @(posedge clk) begin
        if (DHWRITE && DHTRANS == 2'b10 && DHREADY) begin
            case (DHSIZE)
                3'b000: sram[ahb_addr_lat] <= DHWDATA[7:0];
                3'b001: begin
                    sram[ahb_addr_lat    ] <= DHWDATA[ 7: 0];
                    sram[ahb_addr_lat + 1] <= DHWDATA[15: 8];
                end
                3'b010: begin
                    sram[ahb_addr_lat    ] <= DHWDATA[ 7: 0];
                    sram[ahb_addr_lat + 1] <= DHWDATA[15: 8];
                    sram[ahb_addr_lat + 2] <= DHWDATA[23:16];
                    sram[ahb_addr_lat + 3] <= DHWDATA[31:24];
                end
                default: ;
            endcase
        end
    end

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
            $display("    PASS  %-55s  got=%08h", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-55s  got=%08h  exp=%08h", label, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic ck1(
        input string label,
        input logic  got,
        input logic  exp
    );
        if (got === exp) begin
            $display("    PASS  %-55s  got=%0b", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-55s  got=%0b  exp=%0b", label, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic ck2(
        input string label,
        input logic [1:0] got,
        input logic [1:0] exp
    );
        if (got === exp) begin
            $display("    PASS  %-55s  got=%02b", label, got);
            pass_cnt++;
        end else begin
            $display("    FAIL  %-55s  got=%02b  exp=%02b", label, got, exp);
            fail_cnt++;
        end
    endtask

    // Advance clock
    task tick(input int n = 1);
        repeat(n) @(posedge clk); #1;
    endtask

    // Issue a LOAD: drive EX/MEM inputs, wait addr + data phases
    task do_load(
        input [31:0] addr,
        input [ 2:0] sz       // funct3 encoding
    );
        ex_mem_alu_result = addr;
        ex_mem_mem_size   = sz;
        ex_mem_mem_read   = 1'b1;
        ex_mem_mem_write  = 1'b0;
        ex_mem_wb_sel     = `WB_MEM;
        tick(1);                // address phase registered
        tick(1);                // data phase captured into MEM/WB
        ex_mem_mem_read   = 1'b0;
    endtask

    // Issue a STORE, then a NOP tick so the write drains to SRAM
    task do_store(
        input [31:0] addr,
        input [31:0] data,
        input [ 2:0] sz
    );
        ex_mem_alu_result = addr;
        ex_mem_rs2_data   = data;
        ex_mem_mem_size   = sz;
        ex_mem_mem_write  = 1'b1;
        ex_mem_mem_read   = 1'b0;
        tick(1);                // address phase
        tick(1);                // data phase / write commits to SRAM
        ex_mem_mem_write  = 1'b0;
    endtask

    //=========================================================================
    // Test sequence
    //=========================================================================
    initial begin
        $display("\n");
        $display("╔═══════════════════════════════════════════════════════════╗");
        $display("║          TB: mem_stage  —  Standalone Testbench          ║");
        $display("╚═══════════════════════════════════════════════════════════╝");

        // Reset
        rst_n = 1'b0; tick(3); rst_n = 1'b1;

        // ------------------------------------------------------------------
        // GROUP A  —  LOAD sign / zero extension
        // ------------------------------------------------------------------
        $display("\n  ── GROUP A : LOAD sign/zero extension ──");

        // SRAM[0x10..0x13] = {0x13, 0x12, 0x11, 0x10}  (init pattern)
        // SRAM[0x20]       = 0x7F  (positive byte)
        // SRAM[0x21]       = 0x80  (negative byte / negative half MSB)
        // SRAM[0x22..0x23] = 0x00, 0x80  (big-endian half = 0x8000)
        sram['h20] = 8'h7F;
        sram['h21] = 8'h80;
        sram['h22] = 8'h00;
        sram['h23] = 8'h80;
        sram['h24] = 8'h34;
        sram['h25] = 8'h12;

        // TC01: LW — word, no extension
        $display("  [TC01] LW  MEM[0x10] = 0x13121110");
        do_load(32'h10, 3'b010);
        ck32("LW  mem_wb_load_data = 0x1312_1110",
             mem_wb_load_data, 32'h1312_1110);

        // TC02: LH positive (0x127F from 0x20/0x21 swapped? No — little-endian)
        // bytes[0x20]=0x7F bytes[0x21]=0x80  → half = 0x807F
        // sign-ext(0x807F) = 0xFFFF807F
        $display("  [TC02] LH  MEM[0x20] sign-ext positive half 0x807F");
        do_load(32'h20, 3'b001);
        ck32("LH  sign-ext 0x807F → 0xFFFF807F",
             mem_wb_load_data, 32'hFFFF_807F);

        // TC03: LH negative (bytes[0x22]=0x00, bytes[0x23]=0x80 → half=0x8000)
        $display("  [TC03] LH  MEM[0x22] = 0x8000 → sign-ext 0xFFFF8000");
        do_load(32'h22, 3'b001);
        ck32("LH  sign-ext 0x8000 → 0xFFFF_8000",
             mem_wb_load_data, 32'hFFFF_8000);

        // TC04: LHU same address → zero-extend
        $display("  [TC04] LHU MEM[0x22] = 0x8000 → zero-ext 0x00008000");
        do_load(32'h22, 3'b101);
        ck32("LHU zero-ext 0x8000 → 0x0000_8000",
             mem_wb_load_data, 32'h0000_8000);

        // TC05: LB positive byte (0x7F)
        $display("  [TC05] LB  MEM[0x20] = 0x7F → sign-ext 0x0000007F");
        do_load(32'h20, 3'b000);
        ck32("LB  sign-ext 0x7F → 0x0000_007F",
             mem_wb_load_data, 32'h0000_007F);

        // TC06: LB negative byte (0x80 at addr 0x21)
        $display("  [TC06] LB  MEM[0x21] = 0x80 → sign-ext 0xFFFFFF80");
        do_load(32'h21, 3'b000);
        ck32("LB  sign-ext 0x80 → 0xFFFF_FF80",
             mem_wb_load_data, 32'hFFFF_FF80);

        // TC07: LBU same address → zero-extend
        $display("  [TC07] LBU MEM[0x21] = 0x80 → zero-ext 0x00000080");
        do_load(32'h21, 3'b100);
        ck32("LBU zero-ext 0x80 → 0x0000_0080",
             mem_wb_load_data, 32'h0000_0080);

        // ------------------------------------------------------------------
        // GROUP B  —  STORE write then read back
        // ------------------------------------------------------------------
        $display("\n  ── GROUP B : STORE write-back + read-back ──");

        // TC08: SW
        $display("  [TC08] SW  MEM[0x100] = 0xDEAD_BEEF  then LW");
        do_store(32'h100, 32'hDEAD_BEEF, 3'b010);
        do_load (32'h100, 3'b010);
        ck32("SW+LW  0xDEAD_BEEF round-trip",
             mem_wb_load_data, 32'hDEAD_BEEF);

        // TC09: SH
        $display("  [TC09] SH  MEM[0x200] = 0x1234  then LHU");
        do_store(32'h200, 32'h1234, 3'b001);
        do_load (32'h200, 3'b101);
        ck32("SH+LHU  0x1234 round-trip",
             mem_wb_load_data, 32'h0000_1234);

        // TC10: SB
        $display("  [TC10] SB  MEM[0x300] = 0xAB      then LBU");
        do_store(32'h300, 32'hAB, 3'b000);
        do_load (32'h300, 3'b100);
        ck32("SB+LBU  0xAB round-trip",
             mem_wb_load_data, 32'h0000_00AB);

        // ------------------------------------------------------------------
        // GROUP C  —  Non-aligned byte lane extraction
        // ------------------------------------------------------------------
        $display("\n  ── GROUP C : Byte-lane extraction (sub-word addresses) ──");

        // Pre-fill: sram[0x400..0x403] = {0xAA, 0xBB, 0xCC, 0xDD}
        sram['h400] = 8'hAA;
        sram['h401] = 8'hBB;
        sram['h402] = 8'hCC;
        sram['h403] = 8'hDD;

        // TC11: LB offset 0 → 0xAA → sign-ext 0xFFFFFFAA
        $display("  [TC11] LB  MEM[0x400+0] = 0xAA  sign-ext 0xFFFFFFAA");
        do_load(32'h400, 3'b000);
        ck32("LB byte[0] 0xAA → 0xFFFF_FFAA",
             mem_wb_load_data, 32'hFFFF_FFAA);

        // TC12: LBU offset 1 → 0xBB → 0x000000BB
        $display("  [TC12] LBU MEM[0x401]   = 0xBB  zero-ext 0x000000BB");
        do_load(32'h401, 3'b100);
        ck32("LBU byte[1] 0xBB → 0x0000_00BB",
             mem_wb_load_data, 32'h0000_00BB);

        // TC13: LBU offset 2 → 0xCC
        $display("  [TC13] LBU MEM[0x402]   = 0xCC  zero-ext 0x000000CC");
        do_load(32'h402, 3'b100);
        ck32("LBU byte[2] 0xCC → 0x0000_00CC",
             mem_wb_load_data, 32'h0000_00CC);

        // TC14: LBU offset 3 → 0xDD
        $display("  [TC14] LBU MEM[0x403]   = 0xDD  zero-ext 0x000000DD");
        do_load(32'h403, 3'b100);
        ck32("LBU byte[3] 0xDD → 0x0000_00DD",
             mem_wb_load_data, 32'h0000_00DD);

        // TC14b: LHU upper half (offset 2) → {0xDD,0xCC} = 0xDDCC
        $display("  [TC14b] LHU MEM[0x402]  upper half = 0xDDCC");
        do_load(32'h402, 3'b101);
        ck32("LHU half[2] 0xDDCC → 0x0000_DDCC",
             mem_wb_load_data, 32'h0000_DDCC);

        // ------------------------------------------------------------------
        // GROUP D  —  AHB protocol / pipeline register behaviour
        // ------------------------------------------------------------------
        $display("\n  ── GROUP D : AHB protocol & pipeline register ──");

        // TC15: DHREADY=0 asserts mem_stall
        $display("  [TC15] DHREADY=0  →  mem_stall=1");
        ex_mem_alu_result = 32'h10;
        ex_mem_mem_read   = 1'b1;
        ex_mem_mem_size   = 3'b010;
        DHREADY = 1'b0;
        tick(1);
        ck1("mem_stall asserted when DHREADY=0", mem_stall, 1'b1);
        // MEM/WB register must hold (not update)
        logic [31:0] saved_load = mem_wb_load_data;
        tick(2);                        // still stalled
        ck32("MEM/WB load_data unchanged during stall",
             mem_wb_load_data, saved_load);

        // TC16: Restore DHREADY → stall clears, register updates
        $display("  [TC16] DHREADY restored  →  mem_stall=0, register updates");
        DHREADY = 1'b1;
        tick(2);
        ck1 ("mem_stall deasserted", mem_stall, 1'b0);
        ck32("MEM/WB updates after stall clears",
             mem_wb_load_data, 32'h1312_1110);  // word at 0x10
        ex_mem_mem_read = 1'b0;

        // TC17: flush_mem clears MEM/WB
        $display("  [TC17] flush_mem=1  →  MEM/WB cleared to zero");
        ex_mem_alu_result = 32'hCAFE_BABE;
        ex_mem_mem_read   = 1'b0;
        ex_mem_mem_write  = 1'b0;
        ex_mem_reg_write  = 1'b1;
        flush_mem = 1'b1;
        tick(1); flush_mem = 1'b0;
        ck1 ("reg_write=0 after flush", mem_wb_reg_write, 1'b0);
        ck32("alu_result=0 after flush", mem_wb_alu_result, 32'h0);

        // TC18: No memory op → DHTRANS=IDLE, ALU result passes through
        $display("  [TC18] Non-memory op  →  DHTRANS=IDLE, ALU passthrough");
        ex_mem_mem_read  = 1'b0;
        ex_mem_mem_write = 1'b0;
        ex_mem_wb_sel    = `WB_ALU;
        ex_mem_alu_result = 32'hCAFE_BABE;
        tick(1);
        ck2("DHTRANS=IDLE for non-mem op", DHTRANS, 2'b00);
        tick(1);
        ck32("ALU result passes through to MEM/WB",
             mem_wb_alu_result, 32'hCAFE_BABE);

        // TC19: DHTRANS=NONSEQ for read operation
        $display("  [TC19] Memory read  →  DHTRANS=NONSEQ");
        ex_mem_mem_read  = 1'b1;
        ex_mem_mem_size  = 3'b010;
        ex_mem_alu_result = 32'h10;
        tick(1);
        ck2("DHTRANS=NONSEQ for load", DHTRANS, 2'b10);
        ex_mem_mem_read = 1'b0; tick(1);

        // TC20: Back-to-back SW (no gap)
        $display("  [TC20] Back-to-back SW  MEM[0x500]=0x11, MEM[0x504]=0x22");
        do_store(32'h500, 32'h11, 3'b010);
        do_store(32'h504, 32'h22, 3'b010);
        do_load (32'h500, 3'b010);
        ck32("Back-to-back SW[0x500]=0x11", mem_wb_load_data, 32'h11);
        do_load(32'h504, 3'b010);
        ck32("Back-to-back SW[0x504]=0x22", mem_wb_load_data, 32'h22);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("\n╔═══════════════════════════════════════════════════════════╗");
        $display("║  mem_stage TB :  %3d passed    %3d failed                 ║",
                  pass_cnt, fail_cnt);
        $display("╚═══════════════════════════════════════════════════════════╝");
        if (fail_cnt == 0)
            $display("✅  ALL mem_stage TESTS PASSED\n");
        else
            $display("❌  FAILURES — see above\n");
        $finish;
    end

    // Watchdog
    initial begin #500_000; $display("WATCHDOG TIMEOUT"); $finish; end

endmodule
