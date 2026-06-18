#----------------------------------------
# JasperGold Version Info
# tool      : JasperGold 2019.09
# platform  : Linux 3.10.0-1160.el7.x86_64
# version   : 2019.09p002 64 bits
# build date: 2019.11.26 18:17:27 PST
#----------------------------------------
# started Thu May 14 21:51:06 IST 2026
# hostname  : mctsvlsi15.drmcet.ac.in
# pid       : 21986
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:42717' '-nowindow' '-style' 'windows' '-exitonerror' '-data' 'AQAAADx/////AAAAAAAAA3oBAAAAEABMAE0AUgBFAE0ATwBWAEU=' '-proj' '/home/student/Desktop/1tops/rtl/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/student/Desktop/1tops/rtl/jgproject/.tmp/.initCmds.tcl' 'lint.tcl' '-hidden' '/home/student/Desktop/1tops/rtl/jgproject/.tmp/.postCmds.tcl'
analyze -sv -f filelist.f
elaborate -top soc_top
set_engine_mode {Lint}
