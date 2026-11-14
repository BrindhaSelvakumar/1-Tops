`timescale 1ns / 1ps

module execute_stage_tb;

    // ================= SIGNALS =================
    reg clk;
    reg rst_n;

    reg [31:0] ex_pc;
    reg [31:0] rdata1, rdata2;
    reg [31:0] imm;

    reg [2:0] funct3;
    reg [6:0] funct7;

    reg [4:0] alu_ctrl;
    reg [1:0] op1_src;
    reg       alu_src_ctrl;
    reg       m_ext_ctrl;
    reg       jump_ctrl;
    reg       branch_ctrl;

    reg [31:0] mem_alu_result;
    reg [31:0] wb_data;
    reg [1:0]  forward_a;
    reg [1:0]  forward_b;

    wire [31:0] final_result;
    wire [31:0] branch_target;
    wire        branch_taken;
    wire        m_unit_busy;
    wire [31:0] fwd_rs2_out;

    // ================= DUT =================
    execute_stage dut (
        .*   // connects all signals automatically
    );

    // ================= CLOCK =================
    always #5 clk = ~clk;

    // ================= RESET DEFAULTS =================
    task reset_inputs();
    begin
        ex_pc          = 32'h1000;
        rdata1         = 0;
        rdata2         = 0;
        imm            = 0;
        alu_ctrl       = 5'b00000;
        op1_src        = 2'b00;
        alu_src_ctrl   = 1'b0;
        m_ext_ctrl     = 1'b0;
        jump_ctrl      = 1'b0;
        branch_ctrl    = 1'b0;
        forward_a      = 2'b00;
        forward_b      = 2'b00;
        mem_alu_result = 32'd20;
        wb_data        = 32'd30;
        funct3         = 3'b000;
        funct7         = 7'b0000000;
    end
    endtask

    // ================= RESET DUT =================
    task reset_dut();
    begin
        rst_n = 0;
        reset_inputs();
        #20;
        rst_n = 1;
    end
    endtask

    // ================= INIT =================
    initial begin
        clk = 0;

        reset_dut();

        // Run tests
        #10 test_add();
        #10 test_sub();
        #10 test_forwarding();
        #10 test_branch_beq();
        #10 test_branch_bne();
        #10 test_branch_blt();
        #10 test_branch_bgeu();
        #10 test_jump_jal();
        #10 test_jump_jalr();
        #10 test_m_extension();

        #50;
        $display("ALL TESTS DONE");
        $finish;
    end

    // ================= TESTS =================

    // -------- ADD --------
    task test_add();
    begin
        $display("TEST: ADD");
        reset_inputs();

        rdata1 = 15;
        rdata2 = 5;
        alu_ctrl = 5'b00000; // ADD

        #10;

        if (final_result !== 20)
            $error("ADD FAILED: expected 20, got %0d", final_result);
        else
            $display("  PASS: ADD result = %0d", final_result);
    end
    endtask

    // -------- SUB --------
    task test_sub();
    begin
        $display("TEST: SUB");
        reset_inputs();

        rdata1 = 15;
        rdata2 = 5;
        alu_ctrl = 5'b00001; // SUB

        #10;

        if (final_result !== 10)
            $error("SUB FAILED: expected 10, got %0d", final_result);
        else
            $display("  PASS: SUB result = %0d", final_result);
    end
    endtask

    // -------- FORWARDING --------
    task test_forwarding();
    begin
        $display("TEST: FORWARDING");
        reset_inputs();

        rdata1 = 100;
        rdata2 = 200;
        mem_alu_result = 42;
        wb_data = 99;

        forward_a = 2'b10; // from MEM
        forward_b = 2'b01; // from WB

        #10;

        if (fwd_rs2_out !== 99)
            $error("Forwarding B FAILED: expected 99, got %0d", fwd_rs2_out);
        else
            $display("  PASS: fwd_rs2_out = %0d", fwd_rs2_out);

        // Check ALU uses forwarded values (ADD: 42 + 99 = 141)
        if (final_result !== 141)
            $error("Forwarding ALU FAILED: expected 141, got %0d", final_result);
        else
            $display("  PASS: forwarded ADD result = %0d", final_result);
    end
    endtask

    // -------- BEQ --------
    task test_branch_beq();
    begin
        $display("TEST: BEQ");
        reset_inputs();

        branch_ctrl = 1;
        funct3 = 3'b000;
        alu_ctrl = 5'b00001; // SUB

        rdata1 = 10;
        rdata2 = 10;

        #10;

        if (!branch_taken)
            $error("BEQ FAILED: branch not taken when rs1==rs2");
        else
            $display("  PASS: BEQ taken");
    end
    endtask

    // -------- BNE --------
    task test_branch_bne();
    begin
        $display("TEST: BNE");
        reset_inputs();

        branch_ctrl = 1;
        funct3 = 3'b001;
        alu_ctrl = 5'b00001; // SUB

        rdata1 = 10;
        rdata2 = 5;

        #10;

        if (!branch_taken)
            $error("BNE FAILED: branch not taken when rs1!=rs2");
        else
            $display("  PASS: BNE taken");
    end
    endtask

    // -------- BLT --------
    task test_branch_blt();
    begin
        $display("TEST: BLT");
        reset_inputs();

        branch_ctrl = 1;
        funct3 = 3'b100; // BLT
        alu_ctrl = 5'b00001;

        rdata1 = 32'hFFFF_FFFF; // -1 signed
        rdata2 = 32'h0000_0001; // +1 signed

        #10;

        if (!branch_taken)
            $error("BLT FAILED: branch not taken when -1 < 1");
        else
            $display("  PASS: BLT taken (-1 < 1)");
    end
    endtask

    // -------- BGEU --------
    task test_branch_bgeu();
    begin
        $display("TEST: BGEU");
        reset_inputs();

        branch_ctrl = 1;
        funct3 = 3'b111; // BGEU
        alu_ctrl = 5'b00001;

        rdata1 = 32'hFFFF_FFFF; // large unsigned
        rdata2 = 32'h0000_0001;

        #10;

        if (!branch_taken)
            $error("BGEU FAILED: branch not taken when 0xFFFFFFFF >= 1");
        else
            $display("  PASS: BGEU taken (0xFFFFFFFF >= 1)");
    end
    endtask

    // -------- JAL --------
    task test_jump_jal();
    begin
        $display("TEST: JAL");
        reset_inputs();

        jump_ctrl = 1;
        alu_src_ctrl = 0; // JAL: alu_src = 0
        ex_pc = 32'h0000_1000;
        imm = 32'd16;

        #10;

        if (!branch_taken)
            $error("JAL FAILED: branch_taken not asserted");
        else if (branch_target !== 32'h0000_1010) // 0x1000 + 16
            $error("JAL FAILED: expected target 0x1010, got %h", branch_target);
        else
            $display("  PASS: JAL target = %h", branch_target);
    end
    endtask

    // -------- JALR --------
    task test_jump_jalr();
    begin
        $display("TEST: JALR");
        reset_inputs();

        jump_ctrl = 1;
        alu_src_ctrl = 1; // JALR: alu_src = 1
        funct3 = 3'b000;

        rdata1 = 32'h0000_2001; // odd address
        imm = 32'd4;

        #10;

        // JALR target = (rs1 + imm) & ~1 = (0x2001 + 4) & 0xFFFFFFFE = 0x2004
        if (!branch_taken)
            $error("JALR FAILED: branch_taken not asserted");
        else if (branch_target !== 32'h0000_2004)
            $error("JALR FAILED: expected target 0x2004, got %h", branch_target);
        else
            $display("  PASS: JALR target = %h", branch_target);
    end
    endtask

    // -------- M EXT --------
    task test_m_extension();
    begin
        $display("TEST: M EXT (MUL)");
        reset_inputs();

        m_ext_ctrl = 1;
        alu_ctrl = 5'b10000; // MUL

        rdata1 = 6;
        rdata2 = 3;

        #20; // M unit may take time

        if (final_result !== 18)
            $error("MUL FAILED: expected 18, got %0d", final_result);
        else
            $display("  PASS: MUL result = %0d", final_result);
    end
    endtask

    // ================= ASSERTIONS =================

    // ALU input B check
    property alu_b_sel;
        @(posedge clk)
        disable iff (!rst_n)
        alu_src_ctrl |-> (dut.alu_in_b == imm);
    endproperty

    assert property (alu_b_sel)
        else $error("ALU B SEL FAILED");

    // Forwarding check
    property forward_check_a;
        @(posedge clk)
        disable iff (!rst_n)
        (forward_a == 2'b10) |-> (dut.fwd_rs1 == mem_alu_result);
    endproperty

    assert property (forward_check_a)
        else $error("FORWARD A FAILED");

endmodule
