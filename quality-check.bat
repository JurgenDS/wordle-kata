@echo off
REM Comprehensive Quality Check Script - Windows Batch Wrapper
REM Runs the PowerShell quality check script with proper execution policy

setlocal

REM Get script directory
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell or use WSL with the quality-check.sh script.
    exit /b 1
)

REM Check for help flag
if "%1"=="-h" goto :showhelp
if "%1"=="--help" goto :showhelp
if "%1"=="/?" goto :showhelp

REM Build PowerShell arguments
set "PS_ARGS="
if "%1"=="--mutation" set "PS_ARGS=-Mutation"
if "%1"=="-Mutation" set "PS_ARGS=-Mutation"

REM Run PowerShell script with bypass execution policy for this session only
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%quality-check.ps1" %PS_ARGS%

exit /b %ERRORLEVEL%

:showhelp
echo Usage: quality-check.bat [OPTIONS]
echo.
echo Options:
echo   --mutation    Run mutation testing (slow, high effort)
echo   --help, -h    Show this help message
echo.
exit /b 0
