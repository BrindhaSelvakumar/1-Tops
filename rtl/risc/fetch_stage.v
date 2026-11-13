`timescale 1ns / 1ps

module fetch_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Redirect interface (covers both branches and jumps)
    input  wire        branch_taken,
    input  wire [31:0] branch_target,

    // Stall control
    input  wire        stall_all,

    // AHB-Lite instruction interface
    output wire [31:0] IHADDR,
    output wire [1:0]  IHTRANS,
    output wire        IHWRITE,
    output wire [2:0]  IHSIZE,
    input  wire        IHREADY,
    input  wire [31:0] IHRDATA,

    // Outputs to IF/ID register
    output wire [31:0] pc_out,
    output wire [31:0] instr_out
);

    reg [31:0] pc;
    reg [31:0] pc_data_phase;
    reg        kill_fetch_resp;

    wire advance_pc = IHREADY && !stall_all;

    // -------------------------
    // PC register
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0001_0000;
        end else if (branch_taken) begin
            pc <= branch_target;          // redirect overrides stall
        end else if (advance_pc) begin
            pc <= pc + 32'd4;
        end
    end

    // -------------------------
    // Data-phase tracking
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_data_phase   <= 32'h0001_0000;
            kill_fetch_resp <= 1'b1;
        end else if (branch_taken) begin
            pc_data_phase   <= pc;
            kill_fetch_resp <= 1'b1;     // kill response after redirect
        end else if (advance_pc) begin
            pc_data_phase <= pc;
            kill_fetch_resp <= 1'b0;
        end
    end

    // -------------------------
    // AHB-Lite outputs
    // -------------------------
    assign IHADDR  = pc;
    assign IHWRITE = 1'b0;
    assign IHSIZE  = 3'b010;
    assign IHTRANS = (!rst_n || stall_all) ? 2'b00 : 2'b10;

    // -------------------------
    // Instruction output
    // -------------------------
    assign pc_out = pc_data_phase;

    assign instr_out = (!rst_n || !IHREADY || kill_fetch_resp)
                     ? 32'h0000_0013
                     : IHRDATA;

endmodule
