@echo off
REM ==============================================================
REM Cadence Xcelium - RISC-V Core Compile & Simulate Script
REM Run from the rtl\risc\ directory
REM ==============================================================

xrun -compile ^
  prefix_adder_32.v ^
  add_32.v ^
  alu_32.v ^
  alu_ctrl_32.v ^
  imm_gen.v ^
  register_f.v ^
  main_ctrl.v ^
  hazard_unit.v ^
  forwarding_unit.v ^
  m_extension_unit.v ^
  fetch_stage.v ^
  if_id_reg.v ^
  decode_stage.v ^
  id_ex_reg.v ^
  execute_stage.v ^
  ex_mem_reg.v ^
  memory_stage.v ^
  mem_wb_reg.v ^
  writeback_stage.v ^
  risc_core_top.v ^
  tb_risc_core.sv ^
  -sv ^
  -access +rwc ^
  -timescale 1ns/1ps ^
  -top tb_risc_core ^
  -run ^
  -exit

echo.
echo =====================================================
echo  Simulation complete. Check output above for results.
echo =====================================================
