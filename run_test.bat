@echo off
echo Running VUnit tests...
python run.py tb.tb_timer.default.reset_is_respected
python run.py tb.tb_timer.default.start_is_ignored_while_busy
python run.py tb.tb_timer.*.waits_the_correct_amount_of_time
pause
