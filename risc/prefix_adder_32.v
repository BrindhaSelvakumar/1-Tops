`timescale 1ns / 1ps

module prefix_adder_32 #(
    parameter w = 32 
)(
    input  wire [w-1:0] a,
    input  wire [w-1:0] b, 
    input  wire         cin,
    output wire [w-1:0] sum,
    output wire         cout
);
    // This behavioral line guarantees correct carry and sum bits.
    // Synthesis tools will map this to optimized CLA/Kogge-Stone hardware.
    assign {cout, sum} = a + b + cin;

endmodule
