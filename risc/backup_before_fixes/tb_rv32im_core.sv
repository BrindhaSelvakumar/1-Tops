`timescale 1ns/1ps

module tb_rv32im_core;

    // =========================================================
    // CLOCK / RESET
    // =========================================================
    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz
    end

    // =========================================================
    // BUS SIGNALS
    // =========================================================
    wire [31:0] IHADDR;
    wire [1:0]  IHTRANS;
    wire        IHWRITE;
    wire [2:0]  IHSIZE;
    wire [2:0]  IHBURST;
    wire [3:0]  IHPROT;
    reg  [31:0] IHRDATA;
    reg         IHREADY;
    reg         IHRESP;

    wire [31:0] DHADDR;
    wire [1:0]  DHTRANS;
    wire        DHWRITE;
    wire [2:0]  DHSIZE;
    wire [2:0]  DHBURST;
    wire [3:0]  DHPROT;
    wire [31:0] DHWDATA;
    reg  [31:0] DHRDATA;
    reg         DHREADY;
    reg         DHRESP;

    // =========================================================
    // SIMPLE MEMORIES
    // =========================================================
    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];

    integer i;

    // =========================================================
    // DUT
    // =========================================================
    rv32im_core dut (
        .clk(clk),
        .rst_n(rst_n),

        .IHADDR(IHADDR),
        .IHTRANS(IHTRANS),
        .IHWRITE(IHWRITE),
        .IHSIZE(IHSIZE),
        .IHBURST(IHBURST),
        .IHPROT(IHPROT),
        .IHRDATA(IHRDATA),
        .IHREADY(IHREADY),
        .IHRESP(IHRESP),

        .DHADDR(DHADDR),
        .DHTRANS(DHTRANS),
        .DHWRITE(DHWRITE),
        .DHSIZE(DHSIZE),
        .DHBURST(DHBURST),
        .DHPROT(DHPROT),
        .DHWDATA(DHWDATA),
        .DHRDATA(DHRDATA),
        .DHREADY(DHREADY),
        .DHRESP(DHRESP)
    );

    // =========================================================
    // MEMORY MODELS
    // =========================================================
    always @(*) begin
        IHRDATA = imem[IHADDR[9:2]];
    end

    always @(*) begin
        DHRDATA = dmem[DHADDR[9:2]];
    end

    always @(posedge clk) begin
        if (DHWRITE)
            dmem[DHADDR[9:2]] <= DHWDATA;
    end

    // =========================================================
    // TASKS
    // =========================================================
    task tick;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
            #1;
        end
    endtask

    // =========================================================
    // RISC-V ENCODERS
    // =========================================================
    function [31:0] ADDI;
        input [4:0] rd, rs1;
        input [11:0] imm;
        begin
            ADDI = {imm, rs1, 3'b000, rd, 7'b0010011};
        end
    endfunction

    function [31:0] ADD;
        input [4:0] rd, rs1, rs2;
        begin
            ADD = {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
        end
    endfunction

    function [31:0] SW;
        input [4:0] rs2, rs1;
        input [11:0] imm;
        begin
            SW = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
        end
    endfunction

    function [31:0] LW;
        input [4:0] rd, rs1;
        input [11:0] imm;
        begin
            LW = {imm, rs1, 3'b010, rd, 7'b0000011};
        end
    endfunction

    // =========================================================
    // TEST SEQUENCE
    // =========================================================
    initial begin
        IHREADY = 1'b1;
        IHRESP  = 1'b0;
        DHREADY = 1'b1;
        DHRESP  = 1'b0;

        for (i = 0; i < 256; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP
            dmem[i] = 32'h0;
        end

        // Program:
        // x1 = 10
        // x2 = 20
        // x3 = x1 + x2
        // MEM[0] = x3
        // x4 = MEM[0]
        imem[0] = ADDI(5'd1, 5'd0, 12'd10);
        imem[1] = ADDI(5'd2, 5'd0, 12'd20);
        imem[2] = ADD(5'd3, 5'd1, 5'd2);
        imem[3] = SW(5'd3, 5'd0, 12'd0);
        imem[4] = LW(5'd4, 5'd0, 12'd0);
        imem[5] = 32'h00000013; // NOP

        rst_n = 0;
        tick(5);
        rst_n = 1;

        tick(20);

        $display("=====================================");
        $display("DMEM[0] = %0d", dmem[0]);
        $display("Expected = 30");
        $display("=====================================");

        if (dmem[0] == 30)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $finish;
    end

endmodule
