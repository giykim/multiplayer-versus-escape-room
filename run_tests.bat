@echo off
REM E2E Test Runner for Multiplayer Puzzle Game
REM Usage: run_tests.bat [godot_path]

SET GODOT_PATH=%1
IF "%GODOT_PATH%"=="" SET GODOT_PATH=godot

echo ========================================
echo   Running E2E Tests
echo ========================================
echo.

%GODOT_PATH% --headless --script tests/TestRunner.gd

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] All tests passed!
) ELSE (
    echo.
    echo [FAILURE] Some tests failed. Check output above.
)

pause
