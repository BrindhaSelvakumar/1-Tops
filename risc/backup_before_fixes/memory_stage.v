module memory_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [2:0]  funct3,
    input  wire        mem_read,
    input  wire        mem_write,

    output reg  [31:0] DHADDR,
    output reg  [31:0] DHWDATA,
    output reg         DHWRITE,
    output reg  [2:0]  DHSIZE,
    output reg  [1:0]  DHTRANS,

    input  wire        DHREADY,
    input  wire [31:0] DHRDATA,

    output reg  [31:0] read_data,
    output wire        stall_mem
);

    // Stall logic (combinational)
    assign stall_mem = (mem_read || mem_write) && (!DHREADY);

    // AHB control signals (registered to avoid glitches)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            DHADDR  <= 32'd0;
            DHWDATA <= 32'd0;
            DHWRITE <= 1'b0;
            DHTRANS <= 2'b00;
            DHSIZE  <= 3'b010; // default word
        end else begin
            DHADDR  <= addr;
            DHWDATA <= write_data;
            DHWRITE <= mem_write;

            // Transfer type
            if (mem_read || mem_write)
                DHTRANS <= 2'b10; // NONSEQ
            else
                DHTRANS <= 2'b00; // IDLE

            case (funct3)
                3'b000: DHSIZE <= 3'b000; 
                3'b001: DHSIZE <= 3'b001; 
                3'b010: DHSIZE <= 3'b010; 
                default: DHSIZE <= 3'b010; 
            endcase
        end
    end

    // Read data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_data <= 32'd0;
        else if (mem_read && DHREADY)
            read_data <= DHRDATA;
        else
            read_data <= read_data; 
    end

endmodule
