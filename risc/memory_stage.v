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

    output wire [31:0] read_data,
    output wire        stall_mem
);

    assign DHADDR  = addr;
    assign DHWRITE = mem_write;
    assign DHTRANS = (mem_read || mem_write) ? 2'b10 : 2'b00;
    assign stall_mem = (mem_read || mem_write) && !DHREADY;

    // Transfer size
    assign DHSIZE =
        (funct3[1:0] == 2'b00) ? 3'b000 : // Byte
        (funct3[1:0] == 2'b01) ? 3'b001 : // Halfword
                                 3'b010;  // Word

    // Store data byte replication for AHB sub-word writes
    assign DHWDATA = (DHSIZE == 3'b000) ? {4{write_data[7:0]}}  :
                     (DHSIZE == 3'b001) ? {2{write_data[15:0]}} :
                                          write_data;

    // Load data byte/halfword slicing and sign-extension
    wire [7:0] byte_sel = (addr[1:0] == 2'b00) ? DHRDATA[7:0]   :
                          (addr[1:0] == 2'b01) ? DHRDATA[15:8]  :
                          (addr[1:0] == 2'b10) ? DHRDATA[23:16] :
                                                 DHRDATA[31:24];

    wire [15:0] half_sel = (addr[1] == 1'b0) ? DHRDATA[15:0] : DHRDATA[31:16];

    assign read_data =
        (funct3 == 3'b000) ? {{24{byte_sel[7]}}, byte_sel}   : // LB  (signed byte)
        (funct3 == 3'b001) ? {{16{half_sel[15]}}, half_sel}  : // LH  (signed halfword)
        (funct3 == 3'b100) ? {24'b0, byte_sel}                : // LBU (unsigned byte)
        (funct3 == 3'b101) ? {16'b0, half_sel}                : // LHU (unsigned halfword)
                             DHRDATA;                          // LW  (word)

endmodule
