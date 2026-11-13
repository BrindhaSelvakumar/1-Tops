set_db init_lib_search_path "/home/install/FOUNDRY/digital/90nm/dig/lib"
set_db library slow.lib

read_hdl {
    rtl/soc_top.v
    rtl/risc/risc_core_top.v
    rtl/risc/fetch_stage.v
    rtl/risc/decode_stage.v
    rtl/risc/execute_stage.v
    rtl/risc/memory_stage.v
    rtl/risc/writeback_stage.v
    rtl/risc/if_id_reg.v
    rtl/risc/forwarding_unit.v
    rtl/risc/alu_ctrl_32.v
    rtl/risc/alu_32.v
    rtl/risc/main_ctrl.v
    rtl/risc/m_extension_unit.v
    rtl/risc/id_ex_reg.v
    rtl/risc/ex_mem_reg.v
    rtl/risc/mem_wb_reg.v
    rtl/risc/imm_gen.v
    rtl/risc/register_f.v
    rtl/risc/hazard_unit.v
    rtl/risc/add_32.v
    rtl/risc/prefix_adder_32.v
    rtl/ahbmemory/ahb_boot_rom.v
    rtl/ahbmemory/ahb_dbus_decoder.v
    rtl/ahbmemory/ahb_ibus_decoder.v
    rtl/ahbmemory/ahb_isram_slave.v
    rtl/ahbmemory/ahb_dsram_slave.v
    rtl/ahbmemory/ahb_slave_imux.v
    rtl/ahbmemory/ahb_slave_dmux.v
    rtl/bridge/ahb_apb_bridge.v
    rtl/bridge/apb_decoder.v
    rtl/peripherals/sync_fifo.v
    rtl/peripherals/uart_tx.v
    rtl/peripherals/uart_rx.v
    rtl/peripherals/timer_core.v
    rtl/peripherals/apb_uart.v
    rtl/peripherals/apb_timer.v
    rtl/peripherals/apb_spi_master.v
    rtl/peripherals/apb_spi.v
    rtl/peripherals/apb_plic.v
    rtl/peripherals/apb_gpio.v
    rtl/peripherals/apb_clic.v
}

elaborate soc_top
current_design soc_top

read_sdc constraints_top.sdc

check_design
check_timing

syn_generic
syn_map
syn_opt

write_hdl > soc_top_netlist.v
write_sdc > soc_top_output.sdc

report_area   > area.rpt
report_timing > timing.rpt
report_power  > power.rpt
report_qor    > qor.rpt

check_design

