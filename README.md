# 1-TOPS

RTL design project for a RISC-based SoC top-level system.

## Project Structure

- `rtl/` - SoC RTL, testbenches, constraints, reports, and supporting modules.
- `rtl/risc/` - RISC core pipeline modules and testbenches.
- `rtl/ahbmemory/` - AHB memory and decoder modules.
- `rtl/bridge/` - AHB to APB bridge logic.
- `rtl/peripherals/` - APB peripherals including UART, SPI, timer, GPIO, PLIC, and CLIC.
- `rtl/constraints_top.sdc` - Top-level timing constraints.
- `rtl/run.tcl` - Tool run script.
- `rtl/run.lec` - LEC run script.

## Main RTL Files

- `rtl/soc_top.v` - SoC top module.
- `rtl/soc_top_tb.sv` - SoC testbench.
- `rtl/risc/risc_core_top.v` - RISC core top module.
- `rtl/filelist.f` - RTL file list for simulation/tool runs.

## Notes

Generated simulation, formal, waveform, and tool database outputs are ignored by Git to keep the repository lightweight and compatible with GitHub file size limits.
