`timescale 1ns / 1ps

module m_extension_unit (
input  wire clk, rst_n,
input  wire [31:0] a, b,
input  wire [4:0]  alu_ctrl,
input  wire ex_m_ext,
    output reg  [31:0] result,
    output reg         busy
);
    wire signed [63:0] mul_ss = $signed(a) * $signed(b);
    wire        [63:0] mul_uu = {32'h0, a} * {32'h0, b};
    wire signed [63:0] mul_su = $signed({{1'b0}, a}) * $signed({1'b0, b});

    wire        a_neg = a[31];
    wire        b_neg = b[31];
    wire [31:0] a_abs = a_neg ? (32'd0 - a) : a;
    wire [31:0] b_abs = b_neg ? (32'd0 - b) : b;

    wire [31:0] udiv = (b_abs == 32'd0) ? 32'hFFFFFFFF : (a_abs / b_abs);
    wire [31:0] urem = (b_abs == 32'd0) ?a_abs  : (a_abs % b_abs);

    wire        quot_neg   = a_neg ^ b_neg;
    wire [31:0] div_signed = (b == 32'd0) ? 32'hFFFFFFFF :
quot_neg  ? (32'd0 - udiv) :udiv;
    wire [31:0] rem_signed = (b == 32'd0) ?a :
a_neg  ? (32'd0 - urem) :urem;

    wire [31:0] div_unsigned = (b == 32'd0) ? 32'hFFFFFFFF : (a / b);
    wire [31:0] rem_unsigned = (b == 32'd0) ? a            : (a % b);

    always @(*) begin
        busy   = 1'b0;
        result = 32'b0;
        if (ex_m_ext) begin
            case (alu_ctrl)
                5'b10000: result = mul_ss[31:0];
                5'b10001: result = mul_ss[63:32];
                5'b10010: result = mul_su[63:32];
                5'b10011: result = mul_uu[63:32];
                5'b10100: result = div_signed;
                5'b10101: result = div_unsigned;
                5'b10110: result = rem_signed;
                5'b10111: result = rem_unsigned;
                default:  result = 32'b0;
endcase
        end
    end
endmodule
