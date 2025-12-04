@echo off
REM Switch to JDK 21 - Windows Batch Wrapper
REM Usage: switch-to-java21.bat [options]

setlocal EnableDelayedExpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"

REM Check for help
if "%1"=="-h" goto :showhelp
if "%1"=="--help" goto :showhelp
if "%1"=="/?" goto :showhelp

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is not available on this system.
    exit /b 1
)

REM Build arguments
set "PS_ARGS="
:parse_args
if "%1"=="" goto :run
if /i "%1"=="--persist" set "PS_ARGS=!PS_ARGS! -Persist"
if /i "%1"=="-persist" set "PS_ARGS=!PS_ARGS! -Persist"
if /i "%1"=="--user" set "PS_ARGS=!PS_ARGS! -User"
if /i "%1"=="-user" set "PS_ARGS=!PS_ARGS! -User"
if /i "%1"=="--list" set "PS_ARGS=!PS_ARGS! -List"
if /i "%1"=="-list" set "PS_ARGS=!PS_ARGS! -List"
shift
goto :parse_args

:run
REM Run PowerShell script
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%switch-to-java21.ps1" %PS_ARGS%

REM If successful and not persisted, we need to set env vars in this cmd session too
if %ERRORLEVEL% EQU 0 (
    REM Re-run to get JAVA_HOME and update current session
    for /f "tokens=*" %%i in ('powershell -ExecutionPolicy Bypass -NoProfile -Command "$p = @('C:\Program Files\Eclipse Adoptium\jdk-21*','C:\Program Files\Java\jdk-21*','C:\Program Files\Microsoft\jdk-21*','%USERPROFILE%\scoop\apps\temurin21-jdk\current'); foreach($pattern in $p){$f=Get-ChildItem $pattern -Directory -EA SilentlyContinue|Select -First 1;if($f -and (Test-Path \"$($f.FullName)\bin\java.exe\")){Write-Output $f.FullName;break}}"') do (
        set "JAVA_HOME=%%i"
        set "PATH=%%i\bin;%PATH%"
    )
    if defined JAVA_HOME (
        echo.
        echo Current CMD session updated:
        echo   JAVA_HOME = %JAVA_HOME%
    )
)

exit /b %ERRORLEVEL%

:showhelp
echo Switch to JDK 21 on Windows
echo.
echo Usage: switch-to-java21.bat [OPTIONS]
echo.
echo Options:
echo   --list       List all detected Java installations
echo   --persist    Save changes permanently (requires Admin for system-wide)
echo   --user       With --persist, save to user environment only (no Admin)
echo   --help, -h   Show this help message
echo.
echo Examples:
echo   switch-to-java21.bat                  Switch for current session only
echo   switch-to-java21.bat --list           List all Java installations
echo   switch-to-java21.bat --persist --user Save permanently (user level)
echo   switch-to-java21.bat --persist        Save permanently (system, needs Admin)
echo.
exit /b 0
