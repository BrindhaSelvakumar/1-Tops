`timescale 1ns / 1ps

module add_32 #(parameter w = 32)(
    input  wire [w-1:0] a,
    input  wire [w-1:0] b,
    input  wire         sub_in,
    output wire [w-1:0] res,
    output wire         carry,
    output wire         overflow
);
    wire [w-1:0] b_bar = sub_in ? ~b : b; 
    wire         cin   = sub_in; 

    // Instantiate the hardware adder
    prefix_adder_32 #(.w(w)) adder_inst (
        .a   (a), 
        .b   (b_bar), 
        .cin (cin), 
        .sum (res), 
        .cout(carry)
    );

    // Correct Overflow Logic: 
    // If signs of inputs are same but result sign is different
    assign overflow = (a[w-1] == b_bar[w-1]) && (res[w-1] != a[w-1]);

endmodule
