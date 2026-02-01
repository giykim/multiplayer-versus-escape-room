@echo off
REM Comprehensive Path Tests
REM Usage: run_path_tests.bat [godot_path]

SET GODOT_PATH=%1
IF "%GODOT_PATH%"=="" SET GODOT_PATH=godot

echo ========================================
echo   Running Comprehensive Path Tests
echo ========================================
echo.

%GODOT_PATH% --headless --script tests/PathTest.gd

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] All path tests passed!
) ELSE (
    echo.
    echo [FAILURE] Some path tests failed.
)

pause
