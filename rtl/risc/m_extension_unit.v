`timescale 1ns / 1ps

module m_extension_unit (
    input  wire        clk, rst_n,
    input  wire [31:0] a, b,
    input  wire [4:0]  alu_ctrl,
    input  wire        ex_m_ext,

    output reg  [31:0] result,
    output reg         busy
);

    // -----------------------------
    // Multiplication
    // -----------------------------
    wire signed [63:0] mul_ss = $signed(a) * $signed(b);
    wire        [63:0] mul_uu = a * b;
    wire signed [63:0] mul_su = $signed(a) * $signed({1'b0, b});

    // -----------------------------
    // Division prep
    // -----------------------------
    wire a_neg = a[31];
    wire b_neg = b[31];

    wire [31:0] a_abs = a_neg ? -a : a;
    wire [31:0] b_abs = b_neg ? -b : b;

    // -----------------------------
    // Special case: overflow
    // -----------------------------
    wire div_overflow = (a == 32'h80000000) && (b == 32'hFFFFFFFF);

    // -----------------------------
    // Unsigned division core
    // -----------------------------
    wire [31:0] safe_b_abs = (b_abs == 0) ? 32'd1 : b_abs;
    wire [31:0] udiv = (b_abs == 0) ? 32'hFFFFFFFF : (a_abs / safe_b_abs);
    wire [31:0] urem = (b_abs == 0) ? a_abs        : (a_abs % safe_b_abs);

    // -----------------------------
    // Signed division
    // -----------------------------
    wire quot_neg = a_neg ^ b_neg;

    wire [31:0] div_signed =
        (b == 0)          ? 32'hFFFFFFFF :
        (div_overflow)    ? 32'h80000000 :
        (quot_neg)        ? -udiv :
                            udiv;

    wire [31:0] rem_signed =
        (b == 0)          ? a :
        (div_overflow)    ? 32'd0 :
        (a_neg)           ? -urem :
                            urem;

    // -----------------------------
    // Unsigned division
    // -----------------------------
    wire [31:0] safe_b = (b == 0) ? 32'd1 : b;
    wire [31:0] div_unsigned = (b == 0) ? 32'hFFFFFFFF : (a / safe_b);
    wire [31:0] rem_unsigned = (b == 0) ? a            : (a % safe_b);

    // -----------------------------
    // Output logic
    // -----------------------------
    always @(*) begin
        busy   = 1'b0;   // combinational unit
        result = 32'b0;

        if (ex_m_ext) begin
            case (alu_ctrl)
                5'b10000: result = mul_ss[31:0];   // MUL
                5'b10001: result = mul_ss[63:32];  // MULH
                5'b10010: result = mul_su[63:32];  // MULHSU
                5'b10011: result = mul_uu[63:32];  // MULHU
                5'b10100: result = div_signed;     // DIV
                5'b10101: result = div_unsigned;   // DIVU
                5'b10110: result = rem_signed;     // REM
                5'b10111: result = rem_unsigned;   // REMU
                default:  result = 32'b0;
            endcase
        end
    end

endmodule
