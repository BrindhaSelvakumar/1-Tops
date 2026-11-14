
`timescale 1ns/1ps
`include "defines.v"

module tb_ex_stage;

    //--- DUT ports ---
    logic        clk, rst_n, flush_ex = 0;

    logic [31:0] id_ex_pc       = 32'h1000;
    logic [31:0] id_ex_pc4      = 32'h1004;
    logic [31:0] id_ex_rs1_data = 32'h0;
    logic [31:0] id_ex_rs2_data = 32'h0;
    logic [ 4:0] id_ex_rs1      = 5'd1;
    logic [ 4:0] id_ex_rs2      = 5'd2;
    logic [ 4:0] id_ex_rd       = 5'd3;
    logic [31:0] id_ex_imm      = 32'h0;
    logic [ 3:0] id_ex_alu_op   = `ALU_ADD;
    logic [ 2:0] id_ex_mu_op    = `MU_MUL;
    logic        id_ex_alu_src   = 0;
    logic        id_ex_mem_read  = 0;
    logic        id_ex_mem_write = 0;
    logic [ 2:0] id_ex_mem_size  = 3'b010;
    logic        id_ex_reg_write = 1;
    logic [ 1:0] id_ex_wb_sel   = `WB_ALU;
    logic        id_ex_is_muldiv = 0;
    logic        id_ex_auipc     = 0;

    logic [ 4:0] fwd_mem_rd        = 0;
    logic        fwd_mem_reg_write  = 0;
    logic [31:0] fwd_mem_result     = 0;
    logic [ 4:0] fwd_wb_rd         = 0;
    logic        fwd_wb_reg_write   = 0;
    logic [31:0] fwd_wb_data        = 0;

    logic        div_stall;
    logic [31:0] ex_mem_alu_result, ex_mem_rs2_data, ex_mem_pc4;
    logic [ 4:0] ex_mem_rd;
    logic [ 2:0] ex_mem_mem_size;
    logic        ex_mem_mem_read, ex_mem_mem_write, ex_mem_reg_write;
    logic [ 1:0] ex_mem_wb_sel;

    ex_stage dut (.*);

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
        else begin $display("  FAIL  %s  got=%b  exp=%b", name, got, exp); fail_cnt++; end
    endtask

    task tick(int n=1); repeat(n) @(posedge clk); #1; endtask

    
    task apply_alu(
        input [3:0]  op,
        input [31:0] a, b,
        input        use_imm = 0,
        input [31:0] imm_val = 0
    );
        id_ex_alu_op    = op;
        id_ex_rs1_data  = a;
        id_ex_rs2_data  = b;
        id_ex_alu_src   = use_imm;
        id_ex_imm       = imm_val;
        id_ex_is_muldiv = 0;
        id_ex_auipc     = 0;
        tick(1);
    endtask

    initial begin
        $display("\n========== TB: ex_stage ==========");
        rst_n = 0; tick(2); rst_n = 1;

        
        $display("[TC1]  ADD  5+7=12");
        apply_alu(`ALU_ADD, 32'd5, 32'd7);
        ck32("ADD 5+7=12", ex_mem_alu_result, 32'd12);

        $display("[TC2]  SUB  100-37=63");
        apply_alu(`ALU_SUB, 32'd100, 32'd37);
        ck32("SUB 100-37=63", ex_mem_alu_result, 32'd63);

        $display("[TC3]  AND  0xFF0F & 0x0FF0 = 0x0F00");
        apply_alu(`ALU_AND, 32'hFF0F, 32'h0FF0);
        ck32("AND", ex_mem_alu_result, 32'h0F00);

        $display("[TC4]  OR   0xFF00 | 0x00FF = 0xFFFF");
        apply_alu(`ALU_OR,  32'hFF00, 32'h00FF);
        ck32("OR",  ex_mem_alu_result, 32'hFFFF);

        $display("[TC5]  XOR  0xAAAA ^ 0x5555 = 0xFFFF");
        apply_alu(`ALU_XOR, 32'hAAAA, 32'h5555);
        ck32("XOR", ex_mem_alu_result, 32'hFFFF);

        $display("[TC6]  SLL  1 << 4 = 16");
        apply_alu(`ALU_SLL, 32'h1, 32'd4);
        ck32("SLL 1<<4=16", ex_mem_alu_result, 32'd16);

        $display("[TC7]  SRL  0x80000000 >> 1 = 0x40000000");
        apply_alu(`ALU_SRL, 32'h8000_0000, 32'd1);
        ck32("SRL logical", ex_mem_alu_result, 32'h4000_0000);

        $display("[TC8]  SRA  0x80000000 >> 1 = 0xC0000000 (arithmetic)");
        apply_alu(`ALU_SRA, 32'h8000_0000, 32'd1);
        ck32("SRA arithmetic", ex_mem_alu_result, 32'hC000_0000);

        $display("[TC9]  SLT  -1 < 1 (signed) = 1");
        apply_alu(`ALU_SLT, 32'hFFFF_FFFF, 32'd1);
        ck32("SLT -1<1=1", ex_mem_alu_result, 32'd1);

        $display("[TC10] SLT  1 < -1 (signed) = 0");
        apply_alu(`ALU_SLT, 32'd1, 32'hFFFF_FFFF);
        ck32("SLT 1<-1=0", ex_mem_alu_result, 32'd0);

        $display("[TC11] SLTU 1 < 0xFFFFFFFF (unsigned) = 1");
        apply_alu(`ALU_SLTU, 32'd1, 32'hFFFF_FFFF);
        ck32("SLTU 1<0xFFFFFFFF=1", ex_mem_alu_result, 32'd1);

        $display("[TC12] LUI  passthrough 0xDEADB000");
        id_ex_alu_op  = `ALU_LUI;
        id_ex_imm     = 32'hDEADB000;
        id_ex_alu_src = 1;
        id_ex_is_muldiv = 0; id_ex_auipc = 0;
        tick(1);
        ck32("LUI 0xDEADB000", ex_mem_alu_result, 32'hDEADB000);

        $display("[TC13] AUIPC  PC(0x1000) + 0x2000_0000 = 0x2000_1000");
        id_ex_auipc   = 1;
        id_ex_pc      = 32'h1000;
        id_ex_alu_op  = `ALU_AUIPC;
        id_ex_imm     = 32'h2000_0000;
        id_ex_alu_src = 1;
        id_ex_is_muldiv = 0;
        tick(1);
        ck32("AUIPC", ex_mem_alu_result, 32'h2000_1000);
        id_ex_auipc = 0;

        $display("[TC14] ADDI with immediate  100 + (-20) = 80");
        apply_alu(`ALU_ADD, 32'd100, 32'h0, 1, 32'hFFFF_FFEC);  
        ck32("ADDI 100-20=80", ex_mem_alu_result, 32'd80);

       
        $display("[TC15] EX/MEM forwarding (fwd_a path)");
        fwd_mem_reg_write = 1; fwd_mem_rd = 5'd1; fwd_mem_result = 32'd55;
        id_ex_rs1 = 5'd1; id_ex_rs1_data = 32'd0; 
        apply_alu(`ALU_ADD, 32'd0, 32'd7);         
        ck32("fwd_a: 55+7=62", ex_mem_alu_result, 32'd62);
        fwd_mem_reg_write = 0; id_ex_rs1 = 5'd1;

        $display("[TC16] MEM/WB forwarding (fwd_b path)");
        fwd_wb_reg_write = 1; fwd_wb_rd = 5'd2; fwd_wb_data = 32'd9;
        id_ex_rs2 = 5'd2; id_ex_rs2_data = 32'd0;  
        id_ex_rs1_data = 32'd3;
        apply_alu(`ALU_ADD, 32'd3, 32'd0);           
        ck32("fwd_b: 3+9=12", ex_mem_alu_result, 32'd12);
        fwd_wb_reg_write = 0;

        
        $display("[TC17] MUL  12 × 13 = 156");
        id_ex_is_muldiv = 1; id_ex_mu_op = `MU_MUL;
        id_ex_rs1_data = 32'd12; id_ex_rs2_data = 32'd13;
        id_ex_alu_src = 0; id_ex_auipc = 0;
        tick(1);
        ck32("MUL 12*13=156", ex_mem_alu_result, 32'd156);

        $display("[TC18] MULH  -1 × 1  upper = 0xFFFFFFFF");
        id_ex_mu_op = `MU_MULH;
        id_ex_rs1_data = 32'hFFFF_FFFF; id_ex_rs2_data = 32'd1;
        tick(1);
        ck32("MULH -1*1 upper = -1", ex_mem_alu_result, 32'hFFFF_FFFF);

        $display("[TC19] MULHU 0xFFFFFFFF × 2 upper");
        id_ex_mu_op = `MU_MULHU;
        id_ex_rs1_data = 32'hFFFF_FFFF; id_ex_rs2_data = 32'd2;
        tick(1);
        ck32("MULHU upper", ex_mem_alu_result, 32'd1);

        $display("[TC20] MULHSU  0xFFFFFFFF(-1) × 2 upper (signed×unsigned)");
        id_ex_mu_op = `MU_MULHSU;
        id_ex_rs1_data = 32'hFFFF_FFFF; id_ex_rs2_data = 32'd2;
        tick(1);
        ck32("MULHSU upper = -1", ex_mem_alu_result, 32'hFFFF_FFFF);

        
        $display("[TC21] DIV  100 / 7 = 14  (div_stall expected)");
        id_ex_is_muldiv = 1; id_ex_mu_op = `MU_DIV;
        id_ex_rs1_data = 32'd100; id_ex_rs2_data = 32'd7;
        tick(1);
        ck1("div_stall asserted", div_stall, 1'b1);
        wait(!div_stall);
        tick(1);
        ck32("DIV 100/7=14", ex_mem_alu_result, 32'd14);

        $display("[TC22] DIVU 100 / 7 = 14");
        id_ex_mu_op = `MU_DIVU;
        id_ex_rs1_data = 32'd100; id_ex_rs2_data = 32'd7;
        tick(1);
        wait(!div_stall); tick(1);
        ck32("DIVU 100/7=14", ex_mem_alu_result, 32'd14);

        $display("[TC23] REM  100 mod 7 = 2");
        id_ex_mu_op = `MU_REM;
        id_ex_rs1_data = 32'd100; id_ex_rs2_data = 32'd7;
        tick(1);
        wait(!div_stall); tick(1);
        ck32("REM 100%7=2", ex_mem_alu_result, 32'd2);

        $display("[TC24] REMU 100 mod 7 = 2");
        id_ex_mu_op = `MU_REMU;
        id_ex_rs1_data = 32'd100; id_ex_rs2_data = 32'd7;
        tick(1);
        wait(!div_stall); tick(1);
        ck32("REMU 100%7=2", ex_mem_alu_result, 32'd2);

        $display("[TC25] DIV by zero → 0xFFFFFFFF");
        id_ex_mu_op = `MU_DIV;
        id_ex_rs1_data = 32'd5; id_ex_rs2_data = 32'd0;
        tick(1);
        wait(!div_stall); tick(1);
        ck32("DIV/0 = 0xFFFFFFFF", ex_mem_alu_result, 32'hFFFF_FFFF);

        $display("[TC26] REM by zero → dividend");
        id_ex_mu_op = `MU_REM;
        id_ex_rs1_data = 32'd5; id_ex_rs2_data = 32'd0;
        tick(1);
        wait(!div_stall); tick(1);
        ck32("REM/0 = 5 (dividend)", ex_mem_alu_result, 32'd5);

        id_ex_is_muldiv = 0;

        $display("\n--- ex_stage: %0d passed, %0d failed ---\n",
                 pass_cnt, fail_cnt);
        $finish;
    end

    initial begin #500000; $display("TIMEOUT"); $finish; end

endmodule
