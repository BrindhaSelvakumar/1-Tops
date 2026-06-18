# Cadence Genus(TM) Synthesis Solution, Version 20.11-s111_1, built Apr 26 2021 14:57:38

# Date: Thu May 14 21:52:31 2026
# Host: mctsvlsi15.drmcet.ac.in (x86_64 w/Linux 3.10.0-1160.el7.x86_64) (6cores*12cpus*1physical cpu*12th Gen Intel(R) Core(TM) i5-12500 18432KB)
# OS:   CentOS Linux release 7.9.2009 (Core)

read_hdl -sv -f filelist.f
elaborate soc_top
check_design
