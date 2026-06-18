set_db init_lib_search_path "/home/install/FOUNDRY/digital/90nm/dig/lib"
set_db library slow.lib

read_hdl {
    soc_top.v
    risc_core_top.v
    fetch_stage.v
    decode_stage.v
    execute_stage.v
    memory_stage.v
    writeback_stage.v
    if_id_reg.v
    forwarding_unit.v
    alu_ctrl_32.v
    alu_32.v
    main_ctrl.v
    m_extension_unit.v
    id_ex_reg.v
    ex_mem_reg.v
    mem_wb_reg.v
    sign_gen.v
    register_f.v
    hazard_unit.v
    add_32.v
    prefix_adder_32.v
    ahb_decoder.v
    ahb_sram_slave.v
    ahb_boot_rom.v
    ahb_dbus_decoder.v
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
