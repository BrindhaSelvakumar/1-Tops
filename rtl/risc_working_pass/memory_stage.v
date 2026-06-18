`timescale 1ns / 1ps

module memory_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [2:0]  funct3,
    input  wire        mem_read,
    input  wire        mem_write,

    output wire [31:0] DHADDR,
    output wire [31:0] DHWDATA,
    output wire        DHWRITE,
    output wire [2:0]  DHSIZE,
    output wire [1:0]  DHTRANS,

    input  wire        DHREADY,
    input  wire [31:0] DHRDATA,

    output reg  [31:0] read_data,
    output wire        stall_mem
);

    assign DHADDR  = addr;
    assign DHWDATA = write_data;
    assign DHWRITE = mem_write;

    assign DHTRANS = (mem_read || mem_write) ? 2'b10 : 2'b00;
    assign stall_mem = (mem_read || mem_write) && !DHREADY;

    assign DHSIZE =
        (funct3 == 3'b000) ? 3'b000 :
        (funct3 == 3'b001) ? 3'b001 :
                              3'b010;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_data <= 32'h0;
        else if (mem_read && DHREADY)
            read_data <= DHRDATA;
    end

endmodule
