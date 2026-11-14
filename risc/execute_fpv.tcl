clear -all

analyze -v2k prefix_adder_32.v
analyze -v2k add_32.v
analyze -v2k alu_32.v
analyze -v2k m_extension_unit.v
analyze -v2k execute_stage.v

analyze -sv execute_assert.sv
analyze -sv execute_cover.sv
analyze -sv execute_bind.sv

elaborate -top execute_stage

clock clk
reset ~rst_n

prove -all
