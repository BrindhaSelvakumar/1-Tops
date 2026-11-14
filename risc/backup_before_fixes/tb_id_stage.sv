
`timescale 1ns/1ps
`include "defines.v"

module tb_id_stage;

    logic        clk, rst_n;

    logic [31:0] if_id_pc    = 32'h1000;
    logic [31:0] if_id_pc4   = 32'h1004;
    logic [31:0] if_id_instr = `NOP_INSTR;

    logic        wb_reg_write = 0;
    logic [ 4:0] wb_rd        = 0;
    logic [31:0] wb_data      = 0;

    logic        stall_id = 0, flush_id = 0;
    logic        load_use_hazard;
    logic        ex_mem_read = 0;
    logic [ 4:0] ex_rd       = 0;

    logic        branch_taken;
    logic [31:0] branch_target;

    logic [31:0] id_ex_pc, id_ex_pc4, id_ex_rs1_data, id_ex_rs2_data;
    logic [ 4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
    logic [31:0] id_ex_imm;
    logic [ 3:0] id_ex_alu_op;
    logic [ 2:0] id_ex_mu_op;
    logic        id_ex_alu_src, id_ex_mem_read, id_ex_mem_write;
    logic [ 2:0] id_ex_mem_size;
    logic        id_ex_reg_write;
    logic [ 1:0] id_ex_wb_sel;
    logic        id_ex_is_muldiv, id_ex_auipc;

    id_stage dut (.*);

    initial clk = 0;
    always  #5 clk = ~clk;

    int pass_cnt = 0, fail_cnt = 0;

    task automatic ck32(input string name,
                        input logic [31:0] got, exp);
        if (got === exp) begin $display("  PASS  %s", name); pass_cnt++; end
        else begin $display("  FAIL  %s  got=%08h  exp=%08h", name, got, exp); fail_cnt++; end
    endtask

    task automatic ck1(input string name,
                       input logic got, exp);
        if (got === exp) begin $display("  PASS  %s", name); pass_cnt++; end
        else begin $display("  FAIL  %s  got=%0b  exp=%0b", name, got, exp); fail_cnt++; end
    endtask

    task tick(int n=1); repeat(n) @(posedge clk); #1; endtask

    // --- Write a register via WB port ---
    task wreg(input [4:0] r, input [31:0] v);
        wb_reg_write = 1; wb_rd = r; wb_data = v; tick(1); wb_reg_write = 0;
    endtask

    // --- Instruction encoders ---
    function automatic [31:0] enc_addi(input [4:0] rd, rs1, input [11:0] imm12);
        return {imm12, rs1, 3'b000, rd, 7'b001_0011};
    endfunction
    function automatic [31:0] enc_add(input [4:0] rd, rs1, rs2);
        return {7'h00, rs2, rs1, 3'b000, rd, 7'b011_0011};
    endfunction
    function automatic [31:0] enc_sub(input [4:0] rd, rs1, rs2);
        return {7'h20, rs2, rs1, 3'b000, rd, 7'b011_0011};
    endfunction
    function automatic [31:0] enc_lw(input [4:0] rd, rs1, input [11:0] imm12);
        return {imm12, rs1, 3'b010, rd, 7'b000_0011};
    endfunction
    function automatic [31:0] enc_sw(input [4:0] rs1, rs2, input [11:0] imm12);
        return {imm12[11:5], rs2, rs1, 3'b010, imm12[4:0], 7'b010_0011};
    endfunction
    function automatic [31:0] enc_lui(input [4:0] rd, input [31:12] u20);
        return {u20, rd, 7'b011_0111};
    endfunction
    function automatic [31:0] enc_auipc(input [4:0] rd, input [31:12] u20);
        return {u20, rd, 7'b001_0111};
    endfunction
    function automatic [31:0] enc_beq(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b000,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_bne(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b001,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_blt(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b100,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_bge(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b101,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_bltu(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b110,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_bgeu(input [4:0] rs1, rs2, input [12:1] off);
        return {off[12], off[10:5], rs2, rs1, 3'b111,
                off[4:1], off[11], 7'b110_0011};
    endfunction
    function automatic [31:0] enc_jal(input [4:0] rd, input [20:1] off);
        return {off[20], off[10:1], off[11], off[19:12], rd, 7'b110_1111};
    endfunction
    function automatic [31:0] enc_jalr(input [4:0] rd, rs1, input [11:0] imm12);
        return {imm12, rs1, 3'b000, rd, 7'b110_0111};
    endfunction
    function automatic [31:0] enc_mul(input [4:0] rd, rs1, rs2);
        return {7'b000_0001, rs2, rs1, 3'b000, rd, 7'b011_0011};
    endfunction
    function automatic [31:0] enc_div(input [4:0] rd, rs1, rs2);
        return {7'b000_0001, rs2, rs1, 3'b100, rd, 7'b011_0011};
    endfunction
    function automatic [31:0] enc_slli(input [4:0] rd, rs1, shamt);
        return {7'h00, shamt, rs1, 3'b001, rd, 7'b001_0011};
    endfunction
    function automatic [31:0] enc_srli(input [4:0] rd, rs1, shamt);
        return {7'h00, shamt, rs1, 3'b101, rd, 7'b001_0011};
    endfunction
    function automatic [31:0] enc_srai(input [4:0] rd, rs1, shamt);
        return {7'h20, shamt, rs1, 3'b101, rd, 7'b001_0011};
    endfunction

    initial begin
        $display("\n========== TB: id_stage ==========");
        rst_n = 0; tick(2); rst_n = 1;

        //-------------------------------------------------------------
        // TC1: Register file write and read-back
        //-------------------------------------------------------------
        $display("[TC1] Regfile write + read via ADDI");
        wreg(5'd1, 32'd55);
        wreg(5'd2, 32'd77);
        if_id_instr = enc_addi(5'd3, 5'd1, 12'd10);  // ADDI x3, x1, 10
        tick(1);
        ck32("rs1_data = x1 = 55", id_ex_rs1_data, 32'd55);
        ck32("imm I-type = 10",    id_ex_imm,       32'd10);
        ck1 ("reg_write = 1",      id_ex_reg_write, 1'b1);
        ck1 ("alu_src = 1",        id_ex_alu_src,   1'b1);

        //-------------------------------------------------------------
        // TC2: I-type negative immediate sign extension
        //-------------------------------------------------------------
        $display("[TC2] I-imm sign-ext (-4)");
        if_id_instr = enc_addi(5'd4, 5'd0, 12'hFFC);  // imm = -4
        tick(1);
        ck32("imm = -4 sign-ext", id_ex_imm, 32'hFFFF_FFFC);

        //-------------------------------------------------------------
        // TC3: S-type immediate
        //-------------------------------------------------------------
        $display("[TC3] S-type immediate");
        if_id_instr = enc_sw(5'd1, 5'd2, 12'd128);
        tick(1);
        ck32("S-imm = 128",   id_ex_imm,       32'd128);
        ck1 ("mem_write = 1", id_ex_mem_write, 1'b1);
        ck1 ("reg_write = 0", id_ex_reg_write, 1'b0);

        //-------------------------------------------------------------
        // TC4: B-type immediate
        //-------------------------------------------------------------
        $display("[TC4] B-type immediate (BEQ offset +20)");
        wreg(5'd5, 32'd10); wreg(5'd6, 32'd10);
        if_id_pc = 32'h2000;
        if_id_instr = enc_beq(5'd5, 5'd6, 12'd10);  // off = 20 bytes
        tick(1);
        ck32("B-imm = 20",          id_ex_imm,     32'd20);
        ck1 ("BEQ taken",           branch_taken,  1'b1);
        ck32("target = 0x2014",     branch_target, 32'h2014);

        //-------------------------------------------------------------
        // TC5: U-type (LUI)
        //-------------------------------------------------------------
        $display("[TC5] LUI U-type immediate");
        if_id_instr = enc_lui(5'd7, 20'hABCDE);
        tick(1);
        ck32("U-imm = 0xABCDE000", id_ex_imm, 32'hABCDE000);
        ck1 ("reg_write = 1",      id_ex_reg_write, 1'b1);

        //-------------------------------------------------------------
        // TC6: AUIPC flag
        //-------------------------------------------------------------
        $display("[TC6] AUIPC sets auipc flag");
        if_id_instr = enc_auipc(5'd8, 20'h10);
        tick(1);
        ck1 ("auipc flag = 1", id_ex_auipc, 1'b1);
        ck32("U-imm = 0x10000", id_ex_imm, 32'h10000);

        //-------------------------------------------------------------
        // TC7: J-type (JAL)
        //-------------------------------------------------------------
        $display("[TC7] JAL J-type immediate");
        if_id_pc = 32'h3000;
        if_id_instr = enc_jal(5'd1, 20'd100);  // offset = 200 bytes
        tick(1);
        ck1 ("JAL branch_taken",         branch_taken,  1'b1);
        ck32("target = 0x30C8 (3000+C8)", branch_target, 32'h30C8);
        ck1 ("wb_sel = PC4",             id_ex_wb_sel,  `WB_PC4);

        //-------------------------------------------------------------
        // TC8: JALR
        //-------------------------------------------------------------
        $display("[TC8] JALR");
        wreg(5'd10, 32'h5000);
        if_id_instr = enc_jalr(5'd1, 5'd10, 12'd8);  // target = 0x5008
        tick(1);
        ck1 ("JALR branch_taken",     branch_taken,  1'b1);
        ck32("target = 0x5008",       branch_target, 32'h5008);

        //-------------------------------------------------------------
        // TC9: BNE not taken
        //-------------------------------------------------------------
        $display("[TC9] BNE not taken (x5==x6)");
        wreg(5'd5, 32'd42); wreg(5'd6, 32'd42);
        if_id_instr = enc_bne(5'd5, 5'd6, 12'd8);
        tick(1);
        ck1("BNE not taken", branch_taken, 1'b0);

        //-------------------------------------------------------------
        // TC10: BLT taken
        //-------------------------------------------------------------
        $display("[TC10] BLT taken (signed)");
        wreg(5'd5, 32'hFFFF_FFFF);  // -1
        wreg(5'd6, 32'd1);           //  1
        if_id_pc = 32'h4000;
        if_id_instr = enc_blt(5'd5, 5'd6, 12'd4);  // offset=8
        tick(1);
        ck1 ("BLT taken (-1 < 1)",     branch_taken,  1'b1);
        ck32("target = 0x4008",         branch_target, 32'h4008);

        //-------------------------------------------------------------
        // TC11: BGE not taken
        //-------------------------------------------------------------
        $display("[TC11] BGE not taken (-1 < 1)");
        if_id_instr = enc_bge(5'd5, 5'd6, 12'd4);
        tick(1);
        ck1("BGE not taken", branch_taken, 1'b0);

        //-------------------------------------------------------------
        // TC12: BLTU taken  (unsigned: 0xFFFFFFFF > 1)
        //-------------------------------------------------------------
        $display("[TC12] BLTU not taken (0xFFFFFFFF > 1 unsigned)");
        if_id_instr = enc_bltu(5'd5, 5'd6, 12'd4);
        tick(1);
        ck1("BLTU not taken", branch_taken, 1'b0);   // 0xFFFF > 1 unsigned

        //-------------------------------------------------------------
        // TC13: BGEU taken
        //-------------------------------------------------------------
        $display("[TC13] BGEU taken (0xFFFFFFFF >= 1 unsigned)");
        if_id_pc = 32'h5000;
        if_id_instr = enc_bgeu(5'd5, 5'd6, 12'd6);  // offset=12
        tick(1);
        ck1 ("BGEU taken",      branch_taken,  1'b1);
        ck32("target = 0x500C", branch_target, 32'h500C);

        //-------------------------------------------------------------
        // TC14: Load-use hazard detection
        //-------------------------------------------------------------
        $display("[TC14] Load-use hazard");
        ex_mem_read = 1; ex_rd = 5'd3;
        if_id_instr = enc_add(5'd9, 5'd3, 5'd2);  // uses x3 (load result)
        tick(1);
        ck1("load_use_hazard = 1", load_use_hazard, 1'b1);
        ex_mem_read = 0; ex_rd = 0;

        //-------------------------------------------------------------
        // TC15: WB forwarding to rs1
        //-------------------------------------------------------------
        $display("[TC15] WB forwarding rs1");
        wb_reg_write = 1; wb_rd = 5'd1; wb_data = 32'd99;
        if_id_instr = enc_addi(5'd10, 5'd1, 12'd1);  // should see x1=99
        tick(1);
        ck32("forwarded x1=99", id_ex_rs1_data, 32'd99);
        wb_reg_write = 0;

        //-------------------------------------------------------------
        // TC16: SLLI decode
        //-------------------------------------------------------------
        $display("[TC16] SLLI decode");
        if_id_instr = enc_slli(5'd11, 5'd1, 5'd3);
        tick(1);
        ck32("SLLI alu_op = ALU_SLL", {28'h0, id_ex_alu_op}, {28'h0, `ALU_SLL});
        ck1 ("alu_src = 1 (imm)",     id_ex_alu_src, 1'b1);

        //-------------------------------------------------------------
        // TC17: SRAI decode
        //-------------------------------------------------------------
        $display("[TC17] SRAI decode");
        if_id_instr = enc_srai(5'd11, 5'd1, 5'd2);
        tick(1);
        ck32("SRAI alu_op = ALU_SRA", {28'h0, id_ex_alu_op}, {28'h0, `ALU_SRA});

        //-------------------------------------------------------------
        // TC18: MUL decode (RV32M)
        //-------------------------------------------------------------
        $display("[TC18] MUL decode");
        if_id_instr = enc_mul(5'd12, 5'd1, 5'd2);
        tick(1);
        ck1("is_muldiv = 1",        id_ex_is_muldiv, 1'b1);
        ck32("mu_op = MU_MUL",      {29'h0, id_ex_mu_op}, {29'h0, `MU_MUL});

        //-------------------------------------------------------------
        // TC19: DIV decode (RV32M)
        //-------------------------------------------------------------
        $display("[TC19] DIV decode");
        if_id_instr = enc_div(5'd13, 5'd1, 5'd2);
        tick(1);
        ck1("is_muldiv = 1",      id_ex_is_muldiv, 1'b1);
        ck32("mu_op = MU_DIV",    {29'h0, id_ex_mu_op}, {29'h0, `MU_DIV});

        //-------------------------------------------------------------
        // TC20: LW decode
        //-------------------------------------------------------------
        $display("[TC20] LW decode");
        if_id_instr = enc_lw(5'd14, 5'd2, 12'd16);
        tick(1);
        ck1("mem_read = 1",   id_ex_mem_read,  1'b1);
        ck1("wb_sel = MEM",   (id_ex_wb_sel == `WB_MEM), 1'b1);
        ck32("LW imm = 16",   id_ex_imm, 32'd16);

        //-------------------------------------------------------------
        $display("\n--- id_stage: %0d passed, %0d failed ---\n",
                 pass_cnt, fail_cnt);
        $finish;
    end

endmodule
