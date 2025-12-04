@echo off
REM Batch wrapper for uninstall-nvd-api-key.ps1
REM Usage: .\scripts\uninstall-nvd-api-key.bat
REM        .\scripts\uninstall-nvd-api-key.bat -System

setlocal

REM Get the directory where this batch file is located
set "SCRIPTS_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPTS_DIR%uninstall-nvd-api-key.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo Error: PowerShell script not found at %PS_SCRIPT%
    exit /b 1
)

REM Run PowerShell script with bypass execution policy, passing all arguments
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal

