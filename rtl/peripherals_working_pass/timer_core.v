`timescale 1ns / 1ps
module timer_core#(
    parameter APB_ADDR_WIDTH = 12
) (
input  wire HCLK,      // System Clock
input  wire HRESETn,   // Active Low Reset

    // APB Interface
input  wire [APB_ADDR_WIDTH-1:0] PADDR,
input  wire [31:0] PWDATA,
input  wire        PWRITE,
input  wire        PSEL,
input  wire        PENABLE,
    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    // Interrupt Outputs
    output reg  [1:0]  irq_o // [0]: Overflow, [1]: Match
);

    // --- 1. Internal Registers ---
    reg [63:0] reg_timer;
    reg [63:0] reg_cmp;
    reg [31:0] reg_ctrl;     // [0]: Enable, [5:3]: Prescaler
    reg [31:0] reg_irq_stat; // [0]: Overflow, [1]: Match (W1C)
    reg [31:0] prescale_cnt;
    reg        timer_match_prev;

    // --- 2. Timer Enable ---
    wire clk_en = reg_ctrl[0];

    // --- 3. Timer & Prescaler Logic (Clock-Enable Style) ---
    wire [2:0] prescale_val = reg_ctrl[5:3];
    wire tick = (prescale_cnt >= ((1 << prescale_val) - 1));

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
reg_timer    <= 64'b0;
prescale_cnt <= 32'b0;
        end else begin
            if (clk_en) begin
                if (tick) begin
prescale_cnt <= 32'b0;
reg_timer    <= reg_timer + 1;
                end else begin
prescale_cnt <= prescale_cnt + 1;
                end
            end else begin
                prescale_cnt <= 32'b0;
            end
        end
    end

    // --- 4. Interrupt Logic (Main Clock for Stability) ---
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
irq_o <= 2'b0;
reg_irq_stat <= 32'b0;
timer_match_prev <= 1'b0;
        end else begin
            // Pulse detection for Match IRQ
timer_match_prev <= (reg_timer == reg_cmp);

            // Set Match Interrupt (Trigger on transition to match)
            if (clk_en && (reg_timer == reg_cmp) && !timer_match_prev) begin
reg_irq_stat[1] <= 1'b1;
            end

            // Set Overflow Interrupt
            if (clk_en && (&reg_timer)) begin
reg_irq_stat[0] <= 1'b1;
            end

            // Write 1 to Clear (W1C) logic
            if (PSEL && PENABLE && PWRITE && (PADDR[5:0] == 6'h14)) begin
                if (PWDATA[0]) reg_irq_stat[0] <= 1'b0;
                if (PWDATA[1]) reg_irq_stat[1] <= 1'b0;
            end

irq_o <= reg_irq_stat[1:0];
        end
    end

    // --- 5. APB Interface Logic ---
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // Register Write Logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
reg_cmp  <= 64'h0000_0000_0000_0000;
reg_ctrl <= 32'b0;
        end else if (PSEL && PWRITE && PENABLE) begin
            case (PADDR[5:0])
                6'h08: reg_ctrl       <= PWDATA;
                6'h0C: reg_cmp[31:0]  <= PWDATA;
                6'h10: reg_cmp[63:32] <= PWDATA;
                // 0x14 is W1C (Handled in Interrupt block)
endcase
        end
    end

    // Register Read Logic
    assign PRDATA = (PADDR[5:0] == 6'h00) ?reg_timer[31:0] :
                    (PADDR[5:0] == 6'h04) ?reg_timer[63:32] :
                    (PADDR[5:0] == 6'h08) ?reg_ctrl :
                    (PADDR[5:0] == 6'h0C) ?reg_cmp[31:0] :
                    (PADDR[5:0] == 6'h10) ?reg_cmp[63:32] :
                    (PADDR[5:0] == 6'h14) ? {30'h0, reg_irq_stat[1:0]} : 32'h0;

endmodule
