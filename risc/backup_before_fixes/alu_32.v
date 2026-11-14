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

    /*----------------------------------------------------------
     * SUB control
     *----------------------------------------------------------*/

    wire is_sub;

    assign is_sub = (alu_ctrl == 5'b00001);


    /*----------------------------------------------------------
     * Main 32-bit adder
     *----------------------------------------------------------*/

    wire [31:0] adder_res;
    wire        adder_carry;
    wire        adder_overflow;

    add_32 main_adder_unit (
        .a(a),
        .b(b),
        .sub_in(is_sub),
        .res(adder_res),
        .carry(adder_carry),
        .overflow(adder_overflow)
    );


    /*----------------------------------------------------------
     * ALU operation
     *
     * Explicit sensitivity list for Verilog-95
     *----------------------------------------------------------*/

    always @(a or b or alu_ctrl or adder_res)
    begin

        case (alu_ctrl)

            /* ADD */
            5'b00000:
                res = adder_res;

            /* SUB */
            5'b00001:
                res = adder_res;

            /* AND */
            5'b00010:
                res = a & b;

            /* OR */
            5'b00011:
                res = a | b;

            /* XOR */
            5'b00100:
                res = a ^ b;

            /* SLT - signed */
            5'b01000:
            begin
                if (a[31] != b[31])
                    res = a[31] ? 32'b1 : 32'b0;
                else if (a < b)
                    res = 32'b1;
                else
                    res = 32'b0;
            end

            /* SLTU - unsigned */
            5'b01001:
            begin
                if (a < b)
                    res = 32'b1;
                else
                    res = 32'b0;
            end

            /* SLL */
            5'b01101:
                res = a << b[4:0];

            /* SRL */
            5'b01110:
                res = a >> b[4:0];

            /* SRA */
            5'b01111:
            begin
                if (b[4:0] == 5'b00000)
                    res = a;
                else if (a[31] == 1'b0)
                    res = a >> b[4:0];
                else
                    res = (a >> b[4:0]) |
                          (~((32'b1 << (6'd32 - b[4:0])) - 1));
            end

            /* Default */
            default:
                res = 32'b0;

        endcase

    end


    /*----------------------------------------------------------
     * Status flags
     *----------------------------------------------------------*/

    assign zero = (res == 32'b0);

    assign neg = res[31];

    assign overflow = adder_overflow;

    assign cout = adder_carry;

endmodule
