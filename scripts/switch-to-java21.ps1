#Requires -Version 5.1
<#
.SYNOPSIS
    Switch to JDK 21 on Windows

.DESCRIPTION
    This script finds an installed JDK 21 and configures JAVA_HOME and PATH
    to use it. It can set the environment for the current session only or
    persist the changes permanently.

.PARAMETER Persist
    Save the changes permanently (requires running as Administrator for system-wide)

.PARAMETER User
    When used with -Persist, saves to user environment instead of system

.PARAMETER List
    List all detected Java installations without making changes

.EXAMPLE
    .\switch-to-java21.ps1
    # Switches to JDK 21 for the current session only

.EXAMPLE
    .\switch-to-java21.ps1 -Persist
    # Switches to JDK 21 and saves permanently (system-wide, requires Admin)

.EXAMPLE
    .\switch-to-java21.ps1 -Persist -User
    # Switches to JDK 21 and saves permanently (user only, no Admin needed)

.EXAMPLE
    .\switch-to-java21.ps1 -List
    # Lists all detected Java installations
#>

[CmdletBinding()]
param(
    [switch]$Persist,
    [switch]$User,
    [switch]$List,
    [switch]$Help
)

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Common JDK 21 installation locations on Windows
$JavaSearchPaths = @(
    # Eclipse Adoptium (Temurin)
    "C:\Program Files\Eclipse Adoptium\jdk-21*",
    "C:\Program Files (x86)\Eclipse Adoptium\jdk-21*",

    # Oracle JDK
    "C:\Program Files\Java\jdk-21*",
    "C:\Program Files (x86)\Java\jdk-21*",

    # Microsoft Build of OpenJDK
    "C:\Program Files\Microsoft\jdk-21*",
    "C:\Program Files (x86)\Microsoft\jdk-21*",

    # Amazon Corretto
    "C:\Program Files\Amazon Corretto\jdk21*",
    "C:\Program Files (x86)\Amazon Corretto\jdk21*",

    # Azul Zulu
    "C:\Program Files\Zulu\zulu-21*",
    "C:\Program Files (x86)\Zulu\zulu-21*",

    # BellSoft Liberica
    "C:\Program Files\BellSoft\liberica-jdk-21*",
    "C:\Program Files (x86)\BellSoft\liberica-jdk-21*",

    # SAP Machine
    "C:\Program Files\SapMachine\JDK\21*",

    # Scoop package manager
    "$env:USERPROFILE\scoop\apps\temurin21-jdk\current",
    "$env:USERPROFILE\scoop\apps\openjdk21\current",
    "$env:USERPROFILE\scoop\apps\sapmachine21-jdk\current",
    "$env:USERPROFILE\scoop\apps\zulu21-jdk\current",

    # Chocolatey
    "C:\Program Files\OpenJDK\jdk-21*",

    # SDKMAN (via WSL or Git Bash, but check anyway)
    "$env:USERPROFILE\.sdkman\candidates\java\21*",

    # Custom locations
    "C:\Java\jdk-21*",
    "D:\Java\jdk-21*"
)

# Search paths for any Java installation (for -List option)
$AllJavaSearchPaths = @(
    "C:\Program Files\Eclipse Adoptium\jdk-*",
    "C:\Program Files\Java\jdk-*",
    "C:\Program Files\Java\jdk*",
    "C:\Program Files\Microsoft\jdk-*",
    "C:\Program Files\Amazon Corretto\jdk*",
    "C:\Program Files\Zulu\zulu-*",
    "C:\Program Files\BellSoft\liberica-jdk-*",
    "C:\Program Files\SapMachine\JDK\*",
    "$env:USERPROFILE\scoop\apps\temurin*-jdk\current",
    "$env:USERPROFILE\scoop\apps\openjdk*\current",
    "C:\Program Files\OpenJDK\jdk-*"
)

function Get-JavaVersion {
    param([string]$JavaHome)

    $javaBin = Join-Path $JavaHome "bin\java.exe"
    if (Test-Path $javaBin) {
        try {
            $versionOutput = & $javaBin -version 2>&1 | Out-String
            if ($versionOutput -match '"(\d+)[\._]') {
                return $matches[1]
            }
            if ($versionOutput -match 'version "(\d+)') {
                return $matches[1]
            }
        } catch {
            return "?"
        }
    }
    return "?"
}

function Get-JavaVendor {
    param([string]$JavaHome)

    $javaBin = Join-Path $JavaHome "bin\java.exe"
    if (Test-Path $javaBin) {
        try {
            $versionOutput = & $javaBin -version 2>&1 | Out-String
            if ($versionOutput -match "Temurin|Adoptium") { return "Eclipse Temurin" }
            if ($versionOutput -match "Microsoft") { return "Microsoft" }
            if ($versionOutput -match "Corretto") { return "Amazon Corretto" }
            if ($versionOutput -match "Zulu") { return "Azul Zulu" }
            if ($versionOutput -match "GraalVM") { return "GraalVM" }
            if ($versionOutput -match "OpenJDK") { return "OpenJDK" }
            if ($versionOutput -match "Java\(TM\)") { return "Oracle" }
            return "Unknown"
        } catch {
            return "Unknown"
        }
    }
    return "Unknown"
}

function Find-AllJavaInstallations {
    $installations = @()

    foreach ($pattern in $AllJavaSearchPaths) {
        $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $found) {
            $javaBin = Join-Path $dir.FullName "bin\java.exe"
            if (Test-Path $javaBin) {
                $version = Get-JavaVersion $dir.FullName
                $vendor = Get-JavaVendor $dir.FullName
                $installations += [PSCustomObject]@{
                    Version = $version
                    Vendor = $vendor
                    Path = $dir.FullName
                }
            }
        }
    }

    # Also check current JAVA_HOME
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
        $alreadyListed = $installations | Where-Object { $_.Path -eq $env:JAVA_HOME }
        if (-not $alreadyListed) {
            $version = Get-JavaVersion $env:JAVA_HOME
            $vendor = Get-JavaVendor $env:JAVA_HOME
            $installations += [PSCustomObject]@{
                Version = $version
                Vendor = $vendor
                Path = $env:JAVA_HOME
            }
        }
    }

    return $installations | Sort-Object Version -Descending
}

function Find-Java21 {
    foreach ($pattern in $JavaSearchPaths) {
        $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $javaBin = Join-Path $found.FullName "bin\java.exe"
            if (Test-Path $javaBin) {
                return $found.FullName
            }
        }
    }
    return $null
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# List mode
if ($List) {
    Write-Host ""
    Write-Host "Detected Java Installations" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host ""

    $installations = Find-AllJavaInstallations

    if ($installations.Count -eq 0) {
        Write-Host "No Java installations found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Install JDK 21 using one of these methods:" -ForegroundColor White
        Write-Host "  winget install EclipseAdoptium.Temurin.21.JDK" -ForegroundColor Gray
        Write-Host "  scoop install temurin21-jdk" -ForegroundColor Gray
        Write-Host "  choco install temurin21" -ForegroundColor Gray
    } else {
        Write-Host ("{0,-8} {1,-20} {2}" -f "Version", "Vendor", "Path") -ForegroundColor White
        Write-Host ("{0,-8} {1,-20} {2}" -f "-------", "------", "----")

        foreach ($inst in $installations) {
            $isCurrent = ($env:JAVA_HOME -eq $inst.Path)
            $marker = if ($isCurrent) { " <-- current" } else { "" }

            if ($inst.Version -eq "21") {
                Write-Host ("{0,-8} {1,-20} {2}{3}" -f $inst.Version, $inst.Vendor, $inst.Path, $marker) -ForegroundColor Green
            } elseif ($isCurrent) {
                Write-Host ("{0,-8} {1,-20} {2}{3}" -f $inst.Version, $inst.Vendor, $inst.Path, $marker) -ForegroundColor Yellow
            } else {
                Write-Host ("{0,-8} {1,-20} {2}" -f $inst.Version, $inst.Vendor, $inst.Path)
            }
        }
    }

    Write-Host ""

    if ($env:JAVA_HOME) {
        Write-Host "Current JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Cyan
    } else {
        Write-Host "Current JAVA_HOME: (not set)" -ForegroundColor Yellow
    }

    Write-Host ""
    exit 0
}

# Main execution - find and switch to Java 21
Write-Host ""
Write-Host "Searching for JDK 21..." -ForegroundColor Cyan

$java21Path = Find-Java21

if (-not $java21Path) {
    Write-Host ""
    Write-Host "ERROR: JDK 21 not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Searched locations:" -ForegroundColor Yellow
    foreach ($pattern in $JavaSearchPaths) {
        Write-Host "  - $pattern" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Install JDK 21 using one of these methods:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Using winget (recommended):" -ForegroundColor Cyan
    Write-Host "    winget install EclipseAdoptium.Temurin.21.JDK" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Using scoop:" -ForegroundColor Cyan
    Write-Host "    scoop bucket add java"
    Write-Host "    scoop install temurin21-jdk" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Using chocolatey:" -ForegroundColor Cyan
    Write-Host "    choco install temurin21" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Manual download:" -ForegroundColor Cyan
    Write-Host "    https://adoptium.net/temurin/releases/?version=21" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$vendor = Get-JavaVendor $java21Path
Write-Host "Found JDK 21 ($vendor): $java21Path" -ForegroundColor Green

# Store previous values
$previousJavaHome = $env:JAVA_HOME
$previousPath = $env:PATH

# Set for current session
$env:JAVA_HOME = $java21Path
$env:PATH = "$java21Path\bin;$env:PATH"

# Verify it works
Write-Host ""
Write-Host "Verifying Java version..." -ForegroundColor Cyan
try {
    $javaVersion = & "$java21Path\bin\java.exe" -version 2>&1 | Out-String
    Write-Host $javaVersion -ForegroundColor Gray
} catch {
    Write-Host "WARNING: Could not verify Java version" -ForegroundColor Yellow
}

# Persist if requested
if ($Persist) {
    Write-Host ""

    if ($User) {
        # User-level environment variables (no admin needed)
        Write-Host "Saving to user environment variables..." -ForegroundColor Cyan

        try {
            [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $java21Path, [System.EnvironmentVariableTarget]::User)

            # Update user PATH
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

            # Remove any existing Java paths from user PATH
            $pathParts = $userPath -split ';' | Where-Object {
                $_ -and
                $_ -notmatch 'jdk-?\d+' -and
                $_ -notmatch 'Java\\jdk' -and
                $_ -notmatch 'Eclipse Adoptium' -and
                $_ -notmatch 'Zulu' -and
                $_ -notmatch 'Corretto'
            }

            # Add new Java path at the beginning
            $newPath = @("$java21Path\bin") + $pathParts | Where-Object { $_ } | Select-Object -Unique
            $newPathString = $newPath -join ';'

            [System.Environment]::SetEnvironmentVariable("PATH", $newPathString, [System.EnvironmentVariableTarget]::User)

            Write-Host "SUCCESS: Environment variables saved (user level)" -ForegroundColor Green
            Write-Host ""
            Write-Host "NOTE: Open a new terminal for changes to take effect." -ForegroundColor Yellow
        } catch {
            Write-Host "ERROR: Failed to save environment variables: $_" -ForegroundColor Red
            exit 1
        }
    } else {
        # System-level environment variables (requires admin)
        if (-not (Test-Administrator)) {
            Write-Host "ERROR: Administrator privileges required for system-wide changes." -ForegroundColor Red
            Write-Host ""
            Write-Host "Options:" -ForegroundColor Yellow
            Write-Host "  1. Run PowerShell as Administrator and try again"
            Write-Host "  2. Use -User flag to save to user environment only:"
            Write-Host "     .\switch-to-java21.ps1 -Persist -User"
            Write-Host ""
            Write-Host "Current session has been switched to JDK 21 (not persisted)." -ForegroundColor Cyan
            exit 1
        }

        Write-Host "Saving to system environment variables..." -ForegroundColor Cyan

        try {
            [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $java21Path, [System.EnvironmentVariableTarget]::Machine)

            # Update system PATH
            $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

            # Remove any existing Java paths
            $pathParts = $machinePath -split ';' | Where-Object {
                $_ -and
                $_ -notmatch 'jdk-?\d+' -and
                $_ -notmatch 'Java\\jdk' -and
                $_ -notmatch 'Eclipse Adoptium' -and
                $_ -notmatch 'Zulu' -and
                $_ -notmatch 'Corretto'
            }

            # Add new Java path at the beginning
            $newPath = @("$java21Path\bin") + $pathParts | Where-Object { $_ } | Select-Object -Unique
            $newPathString = $newPath -join ';'

            [System.Environment]::SetEnvironmentVariable("PATH", $newPathString, [System.EnvironmentVariableTarget]::Machine)

            Write-Host "SUCCESS: Environment variables saved (system level)" -ForegroundColor Green
            Write-Host ""
            Write-Host "NOTE: Open a new terminal for changes to take effect." -ForegroundColor Yellow
        } catch {
            Write-Host "ERROR: Failed to save environment variables: $_" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host ""
    Write-Host "SUCCESS: Switched to JDK 21 for this session only." -ForegroundColor Green
    Write-Host ""
    Write-Host "To make this permanent, run:" -ForegroundColor Yellow
    Write-Host "  .\switch-to-java21.ps1 -Persist -User    # User level (no admin)" -ForegroundColor Gray
    Write-Host "  .\switch-to-java21.ps1 -Persist          # System level (requires admin)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Current settings:" -ForegroundColor Cyan
Write-Host "  JAVA_HOME = $env:JAVA_HOME"
Write-Host ""

exit 0
