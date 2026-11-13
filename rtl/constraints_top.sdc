# ============================================================
# Clock Definition
# ============================================================
create_clock -name clk -period 10 [get_ports clk]

set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]
set_propagated_clock [get_clocks clk]

# ============================================================
# Reset Constraint
# ============================================================
set_false_path -from [get_ports rst_n] -to [all_registers]

# ============================================================
# Input Delay
# ============================================================
set_input_delay 2 -clock clk \
[remove_from_collection [all_inputs] [get_ports {clk rst_n}]]

# ============================================================
# Output Delay
# ============================================================
set_output_delay 2 -clock clk [all_outputs]

# ============================================================
# Load and Drive
# ============================================================
set_drive 1 [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
set_load 0.1 [all_outputs]

# ============================================================
# Design Rule Constraints
# ============================================================
set_max_transition 0.5 [current_design]
set_max_fanout 10 [current_design]
set_max_capacitance 0.5 [current_design]
