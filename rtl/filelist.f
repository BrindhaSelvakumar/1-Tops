// ==============================================================
// 1-TOPS SoC RTL File List
// ==============================================================

// RISC Core
risc/prefix_adder_32.v
risc/add_32.v
risc/alu_32.v
risc/alu_ctrl_32.v
risc/imm_gen.v
risc/register_f.v
risc/main_ctrl.v
risc/hazard_unit.v
risc/forwarding_unit.v
risc/m_extension_unit.v
risc/fetch_stage.v
risc/if_id_reg.v
risc/decode_stage.v
risc/id_ex_reg.v
risc/execute_stage.v
risc/ex_mem_reg.v
risc/memory_stage.v
risc/mem_wb_reg.v
risc/writeback_stage.v
risc/risc_core_top.v

// AHB Memory Subsystem
ahbmemory/ahb_boot_rom.v
ahbmemory/ahb_ibus_decoder.v
ahbmemory/ahb_dbus_decoder.v
ahbmemory/ahb_isram_slave.v
ahbmemory/ahb_dsram_slave.v
ahbmemory/ahb_slave_imux.v
ahbmemory/ahb_slave_dmux.v

// AHB to APB Bridge
bridge/apb_decoder.v
bridge/ahb_apb_bridge.v

// APB Peripherals
peripherals/sync_fifo.v
peripherals/uart_tx.v
peripherals/uart_rx.v
peripherals/timer_core.v
peripherals/apb_uart.v
peripherals/apb_timer.v
peripherals/apb_spi_master.v
peripherals/apb_spi.v
peripherals/apb_plic.v
peripherals/apb_gpio.v
peripherals/apb_clic.v

// SoC Top-Level
soc_top.v

