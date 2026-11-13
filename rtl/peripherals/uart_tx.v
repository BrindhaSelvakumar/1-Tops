`timescale 1ns / 1ps

module uart_tx#(
parameter BIT_RATE     = 9600,
parameter CLK_HZ       = 50_000_000,
parameter PAYLOAD_BITS = 8,
parameter STOP_BITS    = 1
)(
input  wire clk  , // Top level system clock input.
input  wire resetn  , // Asynchronous active low reset.
output wire                    uart_txd  , // UART transmit pin.
output wire                    uart_tx_busy, // Module busy sending previous item.
input  wire uart_tx_en  , // Send the data on uart_tx_data
input  wire [PAYLOAD_BITS-1:0] uart_tx_data  // The data to be sent
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

// ---------------------------------------------------------------------------
// Internal registers.
//

//
// Internally latched value of the uart_txd line. Helps break long timing
// paths from the logic to the output pins.
reg txd_reg;

//
// Storage for the serial data to be sent.
reg [PAYLOAD_BITS-1:0] data_to_send;

//
// Counter for the number of cycles over a packet bit.
reg [COUNT_REG_LEN-1:0] cycle_counter;

//
// Counter for the number of sent bits of the packet.
reg [3:0] bit_counter;

//
// Current and next states of the internal FSM.
reg [1:0] fsm_state;
reg [1:0] n_fsm_state;

localparam FSM_IDLE  = 2'd0;
localparam FSM_START = 2'd1;
localparam FSM_SEND  = 2'd2;
localparam FSM_STOP  = 2'd3;

// ---------------------------------------------------------------------------
// FSM next state selection.
//

assign uart_tx_busy = (fsm_state != FSM_IDLE) || uart_tx_en;
assign uart_txd     = txd_reg;

wire next_bit         = (cycle_counter == CYCLES_PER_BIT-1);
wire last_payload_bit = (bit_counter == PAYLOAD_BITS-1);
wire last_stop_bit    = (bit_counter == STOP_BITS-1);

//
// Handle picking the next state.
always @(*) begin :p_n_fsm_state
    case (fsm_state)
        FSM_IDLE :n_fsm_state = uart_tx_en  ? FSM_START : FSM_IDLE;
        FSM_START: n_fsm_state = next_bit  ? FSM_SEND  : FSM_START;
        FSM_SEND :n_fsm_state = (next_bit && last_payload_bit) ? FSM_STOP  : FSM_SEND;
        FSM_STOP :n_fsm_state = (next_bit && last_stop_bit)    ? FSM_IDLE  : FSM_STOP;
default  :n_fsm_state = FSM_IDLE;
endcase
end

// ---------------------------------------------------------------------------
// Internal register setting and re-setting.
//

//
// Handle updates to the sent data register.
always @(posedge clk or negedge resetn) begin :p_data_to_send
    if (!resetn) begin
data_to_send <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_IDLE && uart_tx_en) begin
data_to_send <= uart_tx_data;
    end else if (fsm_state == FSM_SEND && next_bit) begin
data_to_send <= data_to_send >> 1;
    end
end

//
// Increments the bit counter each time a new bit frame is sent.
always @(posedge clk or negedge resetn) begin :p_bit_counter
    if (!resetn) begin
bit_counter <= 4'd0;
    end else if (fsm_state == FSM_IDLE || fsm_state == FSM_START) begin
bit_counter <= 4'd0;
    end else if (fsm_state == FSM_SEND && next_bit) begin
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
// Increments the cycle counter when sending.
always @(posedge clk or negedge resetn) begin :p_cycle_counter
    if (!resetn) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if (fsm_state == FSM_IDLE) begin
cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if (next_bit) begin
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
// Responsible for updating the internal value of the txd_reg.
always @(posedge clk or negedge resetn) begin :p_txd_reg
    if (!resetn) begin
txd_reg <= 1'b1;
    end else if (fsm_state == FSM_IDLE) begin
txd_reg <= 1'b1;
    end else if (fsm_state == FSM_START) begin
txd_reg <= 1'b0;
    end else if (fsm_state == FSM_SEND) begin
txd_reg <= data_to_send[0];
    end else begin
txd_reg <= 1'b1;
    end
end

endmodule
