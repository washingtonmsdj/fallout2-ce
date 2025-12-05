@echo off
echo Running Fallout 2 CE Basic Tests...
echo.

REM Run the basic test suite
godot --headless --script "godot_project/tests/run_basic_tests.gd"

echo.
echo Test execution completed.
pause