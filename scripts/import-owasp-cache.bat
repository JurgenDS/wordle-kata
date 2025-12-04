@echo off
REM Import OWASP Dependency-Check database cache (Windows)
REM This batch file wraps the PowerShell script for easy execution

setlocal

REM Get script directory
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell or run the import-owasp-cache.ps1 script manually.
    exit /b 1
)

REM Check for force flag
set "PS_ARGS="
if "%1"=="-Force" set "PS_ARGS=-Force"
if "%1"=="--force" set "PS_ARGS=-Force"
if "%1"=="-f" set "PS_ARGS=-Force"

REM Run PowerShell script with bypass execution policy for this session only
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%import-owasp-cache.ps1" %PS_ARGS%

exit /b %ERRORLEVEL%
