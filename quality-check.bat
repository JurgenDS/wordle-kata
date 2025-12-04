@echo off
REM Quality Check Script for Windows
REM This is a wrapper that launches the PowerShell script
REM
REM Usage: quality-check.bat [--mutation]
REM   --mutation    Run mutation testing (takes longer)

setlocal

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is not available
    echo Please install PowerShell or run from PowerShell directly
    exit /b 1
)

REM Run the PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%quality-check.ps1" %*

exit /b %ERRORLEVEL%
