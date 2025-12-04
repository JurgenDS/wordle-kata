@echo off
setlocal enabledelayedexpansion
REM Batch script to run Maven commands with .env file loaded
REM Usage: mvn-with-env.bat install
REM        mvn-with-env.bat clean verify
REM        mvn-with-env.bat dependency-check:check

REM Get the directory where this script is located
set "BACKEND_DIR=%~dp0"
set "ENV_FILE=%BACKEND_DIR%.env"

REM Load .env file if it exists
if exist "%ENV_FILE%" (
    echo Loading environment variables from .env...
    for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do (
        REM Skip comments and empty lines
        set "line=%%a"
        if not "!line:~0,1!"=="#" (
            if not "!line!"=="" (
                REM Set the environment variable
                set "%%a=%%b"
            )
        )
    )
    if defined NVD_API_KEY (
        echo NVD_API_KEY loaded (will speed up OWASP Dependency-Check)
    )
) else (
    echo Warning: .env file not found at %ENV_FILE%
    echo   Create it with: NVD_API_KEY=your-key-here
)

REM Run Maven with all provided arguments
echo Running: mvn %*
call mvn %*
endlocal

