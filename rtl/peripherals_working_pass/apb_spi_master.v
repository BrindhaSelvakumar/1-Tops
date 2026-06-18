`timescale 1ns / 1ps

module apb_spi_master (
    // APB Bus Interface
    input  wire        PCLK,    
    input  wire        PRESETn, 
    input  wire        PSEL,    
    input  wire        PENABLE, 
    input  wire        PWRITE,  
    input  wire [11:0] PADDR,   
    input  wire [31:0] PWDATA,  
    output reg  [31:0] PRDATA,  
    output wire        PREADY,  
    output wire        PSLVERR, 

    // SPI Pins
    output reg         spi_sclk, 
    output reg         spi_mosi, 
    input  wire        spi_miso, 
    output reg         spi_ss_n
);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // -------------------------------
    // Internal Registers
    // -------------------------------
    reg [31:0] tx_data_reg;
    reg [31:0] rx_data_reg;
    reg [7:0]  ctrl_reg;
    reg [7:0]  clk_div_reg;

    reg [31:0] shift_reg;
    reg [5:0]  bit_count;
    reg [7:0]  clk_cnt;
    reg        busy;

    // -------------------------------
    // APB REGISTER BLOCK
    // -------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data_reg <= 32'h0;
            clk_div_reg <= 8'd4;
            ctrl_reg    <= 8'h0;
            PRDATA      <= 32'h0;
        end else begin
            // WRITE
            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[5:0])
                    6'h00: tx_data_reg <= PWDATA;
                    6'h08: ctrl_reg    <= PWDATA[7:0];
                    6'h0C: clk_div_reg <= PWDATA[7:0];
                    default: ;
                endcase
            end

            // READ
            if (PSEL && PENABLE && !PWRITE) begin
                case (PADDR[5:0])
                    6'h00: PRDATA <= tx_data_reg;
                    6'h04: PRDATA <= rx_data_reg;
                    6'h08: PRDATA <= {31'b0, busy};
                    6'h0C: PRDATA <= {24'b0, clk_div_reg};
                    default: PRDATA <= 32'h0;
                endcase
            end

            // AUTO CLEAR START BIT
            if (busy)
                ctrl_reg[0] <= 1'b0;
        end
    end

    // -------------------------------
    // SPI FSM
    // -------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            spi_sclk   <= 1'b0;
            spi_mosi   <= 1'b0;
            spi_ss_n   <= 1'b1;
            bit_count  <= 6'd0;
            clk_cnt    <= 8'd0;
            busy       <= 1'b0;
            rx_data_reg <= 32'h0;
            shift_reg  <= 32'h0;
        end else begin

            // START CONDITION
            if (!busy && ctrl_reg[0]) begin
                busy      <= 1'b1;
                spi_ss_n  <= 1'b0;
                shift_reg <= tx_data_reg;
                bit_count <= 6'd0;
                clk_cnt   <= 8'd0;
                spi_sclk  <= 1'b0;
            end 

            // ACTIVE TRANSFER
            else if (busy) begin

                if (clk_cnt >= clk_div_reg) begin
                    clk_cnt <= 8'd0;

                    if (spi_sclk == 1'b0) begin
                        // Rising edge
                        spi_sclk <= 1'b1;
                        spi_mosi <= shift_reg[31];
                    end 
                    else begin
                        // Falling edge
                        spi_sclk  <= 1'b0;
                        shift_reg <= {shift_reg[30:0], spi_miso};
                        bit_count <= bit_count + 1;

                        if (bit_count == 6'd31) begin
                            busy        <= 1'b0;
                            spi_ss_n    <= 1'b1;
                            rx_data_reg <= {shift_reg[30:0], spi_miso};
                        end
                    end

                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
        end
    end

endmodule
