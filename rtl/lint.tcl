analyze -sv -f filelist.f
elaborate -top soc_top
set_engine_mode {Lint}
check_lint -all
run
report_lint -summary > lint_summary.rpt
report_lint -detail  > lint_detail.rpt
