`timescale 1ns / 1ps
module alu_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  alu_ctrl,

    output reg  [31:0] res,
    output wire        zero,
    output wire        neg,
    output wire        overflow,
    output wire        cout
);

    wire is_sub = (alu_ctrl == 5'b00001);

    wire [31:0] adder_res;
    wire        adder_carry;
    wire        adder_overflow;

    add_32 #(.w(32)) main_adder_unit (
        .a(a),
        .b(b),
        .sub_in(is_sub),
        .res(adder_res),
        .carry(adder_carry),
        .overflow(adder_overflow)
    );

    // -------------------------
    // ALU MAIN LOGIC
    // -------------------------
    always @(*) begin
        case (alu_ctrl)

            5'b00000: res = adder_res;                         // ADD
            5'b00001: res = adder_res;                         // SUB

            5'b00010: res = a & b;                             // AND
            5'b00011: res = a | b;                             // OR
            5'b00100: res = a ^ b;                             // XOR

            5'b01000: res = ($signed(a) < $signed(b)) ? 1 : 0; // SLT
            5'b01001: res = (a < b) ? 1 : 0;                   // SLTU

            5'b01101: res = a << b[4:0];                       // SLL
            5'b01110: res = a >> b[4:0];                       // SRL
            5'b01111: res = $signed(a) >>> b[4:0];             // SRA

            default:  res = 32'b0;

        endcase
    end

    // -------------------------
    // FLAGS
    // -------------------------
    assign zero = (res == 32'b0);
    assign neg  = res[31];

    assign overflow = is_sub ? adder_overflow : 1'b0;
    assign cout     = is_sub ? adder_carry    : 1'b0;

endmodule
