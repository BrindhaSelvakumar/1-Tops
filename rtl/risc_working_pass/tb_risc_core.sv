`timescale 1ns/1ps

module tb_risc_core;

    reg clk;
    reg rst_n;

    // AHB signals (simple memory model)
    wire [31:0] IHADDR;
    wire [31:0] IHRDATA;
    wire        IHREADY;

    wire [31:0] DHADDR;
    wire [31:0] DHWDATA;
    wire        DHWRITE;
    wire [31:0] DHRDATA;
    wire        DHREADY;

    wire [31:0] debug_pc;
    wire [31:0] debug_alu_result;

    // Instruction memory
    reg [31:0] instr_mem [0:255];

    // Load program.mem
    initial begin
        $readmemh("program.mem", instr_mem);
    end

    // Simple instruction memory behavior
    assign IHRDATA = instr_mem[IHADDR[9:2]];
    assign IHREADY = 1'b1;

    // Dummy data memory
    assign DHRDATA = 32'b0;
    assign DHREADY = 1'b1;

    // DUT
    risc_core_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .IHADDR(IHADDR),
        .IHTRANS(),
        .IHWRITE(),
        .IHSIZE(),
        .IHRDATA(IHRDATA),
        .IHREADY(IHREADY),

        .DHADDR(DHADDR),
        .DHWDATA(DHWDATA),
        .DHWRITE(DHWRITE),
        .DHSIZE(),
        .DHTRANS(),
        .DHRDATA(DHRDATA),
        .DHREADY(DHREADY),

        .irq_i(1'b0),
        .irq_id_i(3'b000),
        .irq_ack_o(),

        .debug_pc(debug_pc),
        .debug_alu_result(debug_alu_result)
    );

    // Clock
    always #5 clk = ~clk;

    // Reset
    initial begin
        clk = 0;
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Debug monitor
    always @(posedge clk) begin
        if (rst_n) begin
            $display("PC=%h | ALU=%h", debug_pc, debug_alu_result);
        end
    end

    // Finish
    initial begin
        #200;
        $finish;
    end

endmodule
