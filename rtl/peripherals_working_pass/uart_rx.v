`timescale 1ns / 1ps

module uart_rx#(
parameter BIT_RATE     = 9600,
parameter CLK_HZ       = 50_000_000,
parameter PAYLOAD_BITS = 8,
parameter STOP_BITS    = 1
)(
input  wire clk  , // Top level system clock input.
input  wire resetn  , // Asynchronous active low reset.
input  wire uart_rxd  , // UART receive pin.
input  wire uart_rx_en  , // Receive enable
output wire                    uart_rx_break, // Did we get a BREAK message?
output wire                    uart_rx_valid, // Valid data received and available.
output reg  [PAYLOAD_BITS-1:0] uart_rx_data   // The received data.
);

// ---------------------------------------------------------------------------
// Internal parameters.
//

//
// Number of clock cycles per UART bit.
localparam integer CYCLES_PER_BIT = CLK_HZ / BIT_RATE;

//
// Size of the registers which store bit durations.
localparam integer COUNT_REG_LEN = (CYCLES_PER_BIT <= 1) ?1 : $clog2(CYCLES_PER_BIT);

//
// Sample the start bit in the middle of the bit period.
localparam integer START_TICKS = (CYCLES_PER_BIT <= 1) ?0 : ((CYCLES_PER_BIT-1) / 2);

// ---------------------------------------------------------------------------
// Internal registers.
//

//
// Internally latched value of the uart_rxd line. Helps break long timing
// paths from input pins into the logic.
reg rxd_reg;
reg rxd_reg_0;

//
// Storage for the received serial data.
reg [PAYLOAD_BITS-1:0] received_data;

//
// Counter for the number of cycles over a packet bit.
reg [COUNT_REG_LEN-1:0] cycle_counter;

//
// Counter for the number of received bits of the packet.
reg [3:0] bit_counter;

//
// Current and next states of the internal FSM.
reg [1:0] fsm_state;
reg [1:0] n_fsm_state;

localparam FSM_IDLE  = 2'd0;
localparam FSM_START = 2'd1;
localparam FSM_RECV  = 2'd2;
localparam FSM_STOP  = 2'd3;

// ---------------------------------------------------------------------------
// Output assignment
//

wire start_sample     = (cycle_counter == START_TICKS);
wire next_bit         = (cycle_counter == CYCLES_PER_BIT-1);
wire last_payload_bit = (bit_counter == PAYLOAD_BITS-1);
wire last_stop_bit    = (bit_counter == STOP_BITS-1);
wire rx_done          = (fsm_state == FSM_STOP) && next_bit && last_stop_bit;

assign uart_rx_break = uart_rx_valid && ~|received_data;
assign uart_rx_valid = rx_done;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
uart_rx_data <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_STOP) begin
uart_rx_data <= received_data;
    end
end

// ---------------------------------------------------------------------------
// FSM next state selection.
//

//
// Handle picking the next state.
always @(*) begin :p_n_fsm_state
    case (fsm_state)
        FSM_IDLE: begin
            if (uart_rx_en && !rxd_reg) begin
n_fsm_state = FSM_START;
            end else begin
n_fsm_state = FSM_IDLE;
            end
        end

        FSM_START: begin
            if (start_sample) begin
n_fsm_state= !rxd_reg ? FSM_RECV : FSM_IDLE;
            end else begin
n_fsm_state = FSM_START;
            end
        end

        FSM_RECV :n_fsm_state = (next_bit && last_payload_bit) ? FSM_STOP : FSM_RECV;
        FSM_STOP :n_fsm_state = (next_bit && last_stop_bit)    ? FSM_IDLE : FSM_STOP;
default  :n_fsm_state = FSM_IDLE;
endcase
end

// ---------------------------------------------------------------------------
// Internal register setting and re-setting.
//

//
// Handle updates to the received data register.
integer i;
always @(posedge clk or negedge resetn) begin :p_received_data
    if (!resetn) begin
received_data <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_IDLE) begin
received_data <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_RECV && next_bit) begin
received_data[PAYLOAD_BITS-1] <= rxd_reg;
        for (i = PAYLOAD_BITS-2; i >= 0; i = i - 1) begin
received_data[i] <= received_data[i+1];
        end
    end
end

//
// Increments the bit counter when receiving.
always @(posedge clk or negedge resetn) begin :p_bit_counter
    if (!resetn) begin
bit_counter <= 4'd0;
    end else if (fsm_state == FSM_IDLE || fsm_state == FSM_START) begin
bit_counter <= 4'd0;
    end else if (fsm_state == FSM_RECV && next_bit) begin
        if (last_payload_bit) begin
bit_counter <= 4'd0;
        end else begin
bit_counter <= bit_counter + 1'b1;
        end
    end else if (fsm_state == FSM_STOP && next_bit) begin
        if (last_stop_bit) begin
bit_counter <= 4'd0;
        end else begin
bit_counter <= bit_counter + 1'b1;
        end
    end
end

//
// Increments the cycle counter when receiving.
always @(posedge clk or negedge resetn) begin :p_cycle_counter
    if (!resetn) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if (fsm_state == FSM_IDLE) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if (fsm_state == FSM_START && start_sample) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if ((fsm_state == FSM_RECV || fsm_state == FSM_STOP) && next_bit) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else begin
cycle_counter <= cycle_counter + 1'b1;
    end
end

//
// Progresses the next FSM state.
always @(posedge clk or negedge resetn) begin :p_fsm_state
    if (!resetn) begin
fsm_state <= FSM_IDLE;
    end else begin
fsm_state <= n_fsm_state;
    end
end

//
// Responsible for updating the internal value of the rxd_reg.
always @(posedge clk or negedge resetn) begin :p_rxd_reg
    if (!resetn) begin
rxd_reg   <= 1'b1;
        rxd_reg_0 <= 1'b1;
    end else if (uart_rx_en) begin
rxd_reg   <= rxd_reg_0;
        rxd_reg_0 <= uart_rxd;
    end
end

endmodule
