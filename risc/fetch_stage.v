`timescale 1ns / 1ps

module fetch_stage (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        branch_taken,
    input  wire        jump,
    input  wire [31:0] branch_target,
    input  wire [31:0] jump_target,

    input  wire        stall_all,

    output wire [31:0] IHADDR,
    output wire [1:0]  IHTRANS,
    output wire        IHWRITE,
    output wire [2:0]  IHSIZE,
    input  wire        IHREADY,
    input  wire [31:0] IHRDATA,

    output wire [31:0] pc_out,
    output wire [31:0] instr_out,
    output wire [31:0] pc_dbg,
    output wire        kill_fetch_resp_dbg
);

    reg [31:0] pc;
    reg [31:0] pc_data_phase;
    reg        kill_fetch_resp;

    wire advance_pc = IHREADY && !stall_all;
    wire redirect   = jump || branch_taken;

    wire [31:0] redirect_target = jump ? jump_target : branch_target;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0001_0000;
        end else if (advance_pc) begin
            if (redirect)
                pc <= redirect_target;
            else
                pc <= pc + 32'd4;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_data_phase   <= 32'h0001_0000;
            kill_fetch_resp <= 1'b1;
        end else if (advance_pc) begin
            pc_data_phase <= pc;

            if (redirect)
                kill_fetch_resp <= 1'b1;
            else
                kill_fetch_resp <= 1'b0;
        end
    end

    assign IHADDR  = pc;
    assign IHWRITE = 1'b0;
    assign IHSIZE  = 3'b010;
    assign IHTRANS = (!rst_n || stall_all) ? 2'b00 : 2'b10;

    assign pc_out = pc_data_phase;

`ifdef SYNTHESIS
    assign instr_out = (!rst_n || !IHREADY || kill_fetch_resp)
                     ? 32'h0000_0013
                     : IHRDATA;
`else
    assign instr_out = (!rst_n || !IHREADY || kill_fetch_resp || (^IHRDATA === 1'bX))
                     ? 32'h0000_0013
                     : IHRDATA;
`endif
    assign pc_dbg              = pc;
    assign kill_fetch_resp_dbg = kill_fetch_resp;

endmodule
