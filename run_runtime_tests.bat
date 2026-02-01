@echo off
REM Runtime Validation Tests
REM Usage: run_runtime_tests.bat [godot_path]

SET GODOT_PATH=%1
IF "%GODOT_PATH%"=="" SET GODOT_PATH=godot

echo ========================================
echo   Running Runtime Validation Tests
echo ========================================
echo.

%GODOT_PATH% --headless --script tests/RuntimeTest.gd

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] All runtime tests passed!
) ELSE (
    echo.
    echo [FAILURE] Some runtime tests failed.
)

pause
