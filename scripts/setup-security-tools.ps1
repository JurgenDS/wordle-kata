#
# Windows Security Tools Setup Script (PowerShell)
# Installs gitleaks and semgrep for secret scanning and SAST
#
# Run with: powershell -ExecutionPolicy Bypass -File setup-security-tools.ps1
#

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  $Message" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Install-Gitleaks {
    Write-Step "Installing gitleaks..."

    if (Test-Command "gitleaks") {
        $version = & gitleaks version 2>$null
        Write-Success "gitleaks is already installed ($version)"
        return $true
    }

    # Try winget first
    if (Test-Command "winget") {
        Write-Info "Installing via winget..."
        try {
            winget install --id Gitleaks.Gitleaks -e --accept-source-agreements --accept-package-agreements
            if (Test-Command "gitleaks") {
                Write-Success "gitleaks installed successfully via winget"
                return $true
            }
        } catch {
            Write-Warning "winget installation failed, trying alternatives..."
        }
    }

    # Try scoop
    if (Test-Command "scoop") {
        Write-Info "Installing via scoop..."
        try {
            scoop install gitleaks
            if (Test-Command "gitleaks") {
                Write-Success "gitleaks installed successfully via scoop"
                return $true
            }
        } catch {
            Write-Warning "scoop installation failed, trying alternatives..."
        }
    }

    # Try chocolatey
    if (Test-Command "choco") {
        Write-Info "Installing via chocolatey..."
        try {
            choco install gitleaks -y
            if (Test-Command "gitleaks") {
                Write-Success "gitleaks installed successfully via chocolatey"
                return $true
            }
        } catch {
            Write-Warning "chocolatey installation failed"
        }
    }

    Write-Failure "Could not install gitleaks automatically"
    Write-Info "Please install a package manager and try again:"
    Write-Host "  - winget: Included in Windows 11 and Windows 10 App Installer"
    Write-Host "  - scoop: https://scoop.sh (run: irm get.scoop.sh | iex)"
    Write-Host "  - chocolatey: https://chocolatey.org"
    return $false
}

function Install-Semgrep {
    Write-Step "Installing semgrep..."

    if (Test-Command "semgrep") {
        $version = & semgrep --version 2>$null | Select-Object -First 1
        Write-Success "semgrep is already installed ($version)"
        return $true
    }

    # Try winget first
    if (Test-Command "winget") {
        Write-Info "Installing via winget..."
        try {
            winget install --id Semgrep.Semgrep -e --accept-source-agreements --accept-package-agreements
            if (Test-Command "semgrep") {
                Write-Success "semgrep installed successfully via winget"
                return $true
            }
        } catch {
            Write-Warning "winget installation failed, trying pip..."
        }
    }

    # Try pip
    if (Test-Command "pip") {
        Write-Info "Installing via pip..."
        try {
            pip install semgrep
            Write-Success "semgrep installed successfully via pip"
            Write-Warning "You may need to restart your terminal for semgrep to be available"
            return $true
        } catch {
            Write-Warning "pip installation failed"
        }
    }

    if (Test-Command "pip3") {
        Write-Info "Installing via pip3..."
        try {
            pip3 install semgrep
            Write-Success "semgrep installed successfully via pip3"
            Write-Warning "You may need to restart your terminal for semgrep to be available"
            return $true
        } catch {
            Write-Warning "pip3 installation failed"
        }
    }

    Write-Failure "Could not install semgrep automatically"
    Write-Info "Please install Python and pip, then run: pip install semgrep"
    return $false
}

function Check-Java {
    Write-Step "Checking Java version..."

    if (Test-Command "java") {
        $javaVersion = & java -version 2>&1 | Select-Object -First 1
        Write-Success "Java is installed: $javaVersion"

        # Check if it's Java 21 or compatible
        if ($javaVersion -match '"(\d+)') {
            $majorVersion = [int]$Matches[1]
            if ($majorVersion -ge 25) {
                Write-Warning "Java $majorVersion detected - SpotBugs requires Java 21"
                Write-Info "Install Java 21 alongside your current version:"
                Write-Host "  winget install --id EclipseAdoptium.Temurin.21.JDK"
            }
        }
        return $true
    } else {
        Write-Warning "Java not found - required for backend builds"
        Write-Info "Install Java 21:"
        Write-Host "  winget install --id EclipseAdoptium.Temurin.21.JDK"
        return $false
    }
}

# Main
Write-Host ""
Write-Host "  ================================================================" -ForegroundColor White
Write-Host "  |                                                              |" -ForegroundColor White
Write-Host "  |       SECURITY TOOLS SETUP (Windows)                         |" -ForegroundColor White
Write-Host "  |                                                              |" -ForegroundColor White
Write-Host "  ================================================================" -ForegroundColor White
Write-Host ""

Write-Header "INSTALLING SECURITY TOOLS"

$gitleaksOk = Install-Gitleaks
Write-Host ""
$semgrepOk = Install-Semgrep

Write-Header "CHECKING PREREQUISITES"

$javaOk = Check-Java

Write-Header "SETUP SUMMARY"

Write-Host ("{0,-35} {1}" -f "Tool", "Status")
Write-Host "-----------------------------------------------------"

if ($gitleaksOk -or (Test-Command "gitleaks")) {
    Write-Host ("{0,-35}" -f "gitleaks (secret scanning)") -NoNewline
    Write-Host " Installed" -ForegroundColor Green
} else {
    Write-Host ("{0,-35}" -f "gitleaks (secret scanning)") -NoNewline
    Write-Host " Not installed" -ForegroundColor Red
}

if ($semgrepOk -or (Test-Command "semgrep")) {
    Write-Host ("{0,-35}" -f "semgrep (SAST)") -NoNewline
    Write-Host " Installed" -ForegroundColor Green
} else {
    Write-Host ("{0,-35}" -f "semgrep (SAST)") -NoNewline
    Write-Host " Not installed" -ForegroundColor Red
}

if ($javaOk) {
    Write-Host ("{0,-35}" -f "java (backend builds)") -NoNewline
    Write-Host " Installed" -ForegroundColor Green
} else {
    Write-Host ("{0,-35}" -f "java (backend builds)") -NoNewline
    Write-Host " Not installed" -ForegroundColor Yellow
}

Write-Host ""

if ($gitleaksOk -and $semgrepOk) {
    Write-Host "All security tools installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the quality check (in WSL or Git Bash):"
    Write-Host "  ./quality-check.sh"
} else {
    Write-Host "Some tools could not be installed automatically." -ForegroundColor Yellow
    Write-Host "Please install them manually using the instructions above."
}

Write-Host ""
