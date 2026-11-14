module add_32 #(parameter w = 32)(
    input  wire [w-1:0] a,
    input  wire [w-1:0] b,
    input  wire         sub_in,
    output wire [w-1:0] res,
    output wire         carry,
    output wire         overflow
);

    wire [w-1:0] b_bar;
    wire         cin;

    assign b_bar = sub_in ? ~b : b;
    assign cin   = sub_in;

    prefix_adder_32 u_prefix_adder (
        .a   (a),
        .b   (b_bar),
        .cin (cin),
        .sum (res),
        .cout(carry)
    );

    assign overflow =
        (a[w-1] == b_bar[w-1]) &&
        (res[w-1] != a[w-1]);

endmodule
