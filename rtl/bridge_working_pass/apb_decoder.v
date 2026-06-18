`timescale 1ns/1ps
module apb_decoder (
    input  wire [31:0] PADDR,
    output wire [7:0]  PSEL
);

    assign PSEL[0] = (PADDR[31:12] == 20'h40000); // SPI Master
    assign PSEL[1] = (PADDR[31:12] == 20'h40001); // UART0
    assign PSEL[2] = (PADDR[31:12] == 20'h40002); // UART1
    assign PSEL[3] = (PADDR[31:12] == 20'h40003); // GPIO
    assign PSEL[4] = (PADDR[31:12] == 20'h40004); // TIMER
    assign PSEL[5] = (PADDR[31:12] == 20'h40005); // CLIC
    assign PSEL[6] = (PADDR[31:12] == 20'h40006); // SPI Slave
    assign PSEL[7] = (PADDR[31:12] == 20'h40007); // PLIC

endmodule
