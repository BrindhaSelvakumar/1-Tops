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
    assign DHWRITE = mem_write;

    // AHB byte-lane replication for SB/SH stores
    assign DHWDATA =
        (funct3[1:0] == 2'b00) ? {4{write_data[7:0]}}  :  // SB: replicate byte
        (funct3[1:0] == 2'b01) ? {2{write_data[15:0]}} :  // SH: replicate halfword
                                  write_data;               // SW: full word

    assign DHTRANS = (mem_read || mem_write) ? 2'b10 : 2'b00;
    assign stall_mem = (mem_read || mem_write) && !DHREADY;

    // DHSIZE must account for unsigned load variants (LBU=3'b100, LHU=3'b101)
    assign DHSIZE =
        (funct3[1:0] == 2'b00) ? 3'b000 :  // SB / LB / LBU
        (funct3[1:0] == 2'b01) ? 3'b001 :  // SH / LH / LHU
                                  3'b010;   // SW / LW

    always @(*) begin
        read_data = 32'h0;
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB — select byte lane based on addr[1:0]
                    case (addr[1:0])
                        2'b00: read_data = {{24{DHRDATA[7]}},  DHRDATA[7:0]};
                        2'b01: read_data = {{24{DHRDATA[15]}}, DHRDATA[15:8]};
                        2'b10: read_data = {{24{DHRDATA[23]}}, DHRDATA[23:16]};
                        2'b11: read_data = {{24{DHRDATA[31]}}, DHRDATA[31:24]};
                        default: read_data = 32'h0;
                    endcase
                end
                3'b001: begin // LH — select halfword lane based on addr[1]
                    case (addr[1])
                        1'b0: read_data = {{16{DHRDATA[15]}}, DHRDATA[15:0]};
                        1'b1: read_data = {{16{DHRDATA[31]}}, DHRDATA[31:16]};
                        default: read_data = 32'h0;
                    endcase
                end
                3'b010:  read_data = DHRDATA;                              // LW
                3'b100: begin // LBU — select byte lane, zero-extend
                    case (addr[1:0])
                        2'b00: read_data = {24'b0, DHRDATA[7:0]};
                        2'b01: read_data = {24'b0, DHRDATA[15:8]};
                        2'b10: read_data = {24'b0, DHRDATA[23:16]};
                        2'b11: read_data = {24'b0, DHRDATA[31:24]};
                        default: read_data = 32'h0;
                    endcase
                end
                3'b101: begin // LHU — select halfword lane, zero-extend
                    case (addr[1])
                        1'b0: read_data = {16'b0, DHRDATA[15:0]};
                        1'b1: read_data = {16'b0, DHRDATA[31:16]};
                        default: read_data = 32'h0;
                    endcase
                end
                default: read_data = DHRDATA;
            endcase
        end
    end

endmodule
