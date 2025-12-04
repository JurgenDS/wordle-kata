@echo off
REM Batch wrapper for clear-dependency-check-cache.ps1
REM Usage: .\scripts\clear-dependency-check-cache.bat

setlocal

REM Get the directory where this batch file is located
set "SCRIPTS_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPTS_DIR%clear-dependency-check-cache.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo Error: PowerShell script not found at %PS_SCRIPT%
    exit /b 1
)

REM Run PowerShell script with bypass execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

endlocal

