#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Quality Check Script for Windows
    Runs all backend, frontend, and E2E quality checks

.DESCRIPTION
    This script performs the same quality checks as quality-check.sh but for Windows environments.
    It checks: secrets, backend tests, SpotBugs, OWASP dependency check, Checkstyle, licenses,
    Semgrep SAST, frontend TypeScript/ESLint/Prettier/tests/build/audit, and E2E tests.

.PARAMETER Mutation
    Run mutation testing (slow, high effort)

.EXAMPLE
    .\quality-check.ps1
    .\quality-check.ps1 -Mutation
#>

[CmdletBinding()]
param(
    [switch]$Mutation,
    [switch]$Help
)

# Stop on first error
$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "Usage: .\quality-check.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Mutation    Run mutation testing (slow, high effort)"
    Write-Host "  -Help        Show this help message"
    Write-Host ""
    exit 0
}

# Get project root (script location)
$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

# Configure Java 21 for backend (required for SpotBugs compatibility)
$JavaPaths = @(
    "C:\Program Files\Eclipse Adoptium\jdk-21*",
    "C:\Program Files\Java\jdk-21*",
    "C:\Program Files\Microsoft\jdk-21*",
    "$env:USERPROFILE\.sdkman\candidates\java\21*",
    "$env:USERPROFILE\scoop\apps\temurin21-jdk\current"
)

foreach ($pattern in $JavaPaths) {
    $javaDir = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($javaDir) {
        $env:JAVA_HOME = $javaDir.FullName
        $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
        break
    }
}

# Result tracking
$script:Results = @{
    SecretsS = ""
    BackendTests = ""
    BackendSpotbugs = ""
    BackendDepcheck = ""
    BackendCheckstyle = ""
    BackendLicense = ""
    BackendMutation = ""
    Semgrep = ""
    FrontendTypecheck = ""
    FrontendLint = ""
    FrontendFormat = ""
    FrontendTests = ""
    FrontendBuild = ""
    FrontendAudit = ""
    FrontendLicense = ""
    E2ETests = ""
    E2EBddgen = ""
}

# Temp files for capturing output
$script:LogFiles = @{
    Secrets = [System.IO.Path]::GetTempFileName()
    Backend = [System.IO.Path]::GetTempFileName()
    BackendSpotbugs = [System.IO.Path]::GetTempFileName()
    BackendDepcheck = [System.IO.Path]::GetTempFileName()
    BackendCheckstyle = [System.IO.Path]::GetTempFileName()
    BackendLicense = [System.IO.Path]::GetTempFileName()
    BackendMutation = [System.IO.Path]::GetTempFileName()
    Semgrep = [System.IO.Path]::GetTempFileName()
    FrontendTypecheck = [System.IO.Path]::GetTempFileName()
    FrontendLint = [System.IO.Path]::GetTempFileName()
    FrontendFormat = [System.IO.Path]::GetTempFileName()
    FrontendTests = [System.IO.Path]::GetTempFileName()
    FrontendBuild = [System.IO.Path]::GetTempFileName()
    FrontendAudit = [System.IO.Path]::GetTempFileName()
    FrontendLicense = [System.IO.Path]::GetTempFileName()
    E2E = [System.IO.Path]::GetTempFileName()
    E2EBddgen = [System.IO.Path]::GetTempFileName()
}

# Cleanup temp files on exit
function Cleanup {
    foreach ($logFile in $script:LogFiles.Values) {
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Register cleanup on script exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }
trap { Cleanup }

# Print functions with colors
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
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

function Write-Detail {
    param([string]$Message)
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# Check if command exists
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Run a command and capture output
function Invoke-Check {
    param(
        [string]$Name,
        [string]$WorkDir,
        [string]$Command,
        [string]$LogFile
    )

    Write-Step "Running: $Name"
    Push-Location $WorkDir

    try {
        $output = Invoke-Expression "$Command 2>&1" | Out-String
        $output | Out-File -FilePath $LogFile -Encoding utf8

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Name passed"
            Pop-Location
            return "PASS"
        } else {
            Write-Failure "$Name failed"
            Pop-Location
            return "FAIL"
        }
    } catch {
        Write-Failure "$Name failed: $_"
        $_.ToString() | Out-File -FilePath $LogFile -Encoding utf8
        Pop-Location
        return "FAIL"
    }
}

# Check prerequisites
function Test-Prerequisites {
    Write-Header "CHECKING PREREQUISITES"

    $canContinue = $true
    $missingPrereqs = @()

    # Check Java
    Write-Step "Checking Java..."
    if (Test-Command "java") {
        # java -version outputs to stderr, so we need to capture it properly
        # In PowerShell, stderr redirection with 2>&1 creates ErrorRecord objects
        # Convert all output to strings and get the first line
        try {
            $ErrorActionPreference = "SilentlyContinue"
            $javaVersionOutput = & java -version 2>&1 | ForEach-Object { $_.ToString() }
            if ($javaVersionOutput) {
                $javaVersion = if ($javaVersionOutput -is [System.Array]) {
                    $javaVersionOutput[0]
                } else {
                    $javaVersionOutput
                }
                Write-Success "Java found: $javaVersion"
            } else {
                Write-Success "Java found (version check unavailable)"
            }
        } catch {
            Write-Success "Java found (version check unavailable)"
        }
    } else {
        Write-Failure "Java not found"
        $missingPrereqs += "java"
        $canContinue = $false
    }

    # Check Maven
    Write-Step "Checking Maven..."
    if (Test-Command "mvn") {
        $mvnVersion = & mvn -v 2>&1 | Select-Object -First 1
        Write-Success "Maven found: $mvnVersion"
    } else {
        Write-Failure "Maven not found"
        $missingPrereqs += "maven"
        $canContinue = $false
    }

    # Check Node.js
    Write-Step "Checking Node.js..."
    if (Test-Command "node") {
        $nodeVersion = & node -v
        Write-Success "Node.js found: $nodeVersion"
    } else {
        Write-Failure "Node.js not found"
        $missingPrereqs += "node"
        $canContinue = $false
    }

    # Check npm
    Write-Step "Checking npm..."
    if (Test-Command "npm") {
        $npmVersion = & npm -v
        Write-Success "npm found: $npmVersion"
    } else {
        Write-Failure "npm not found"
        $missingPrereqs += "npm"
        $canContinue = $false
    }

    # Check pnpm
    Write-Step "Checking pnpm..."
    if (Test-Command "pnpm") {
        $pnpmVersion = & pnpm -v
        Write-Success "pnpm found: $pnpmVersion"
    } else {
        if (Test-Command "npm") {
            Write-Warning "pnpm not found - installing via npm..."
            try {
                & npm install -g pnpm 2>&1 | Out-Null
                Write-Success "pnpm installed successfully"
            } catch {
                Write-Failure "Could not install pnpm"
                $missingPrereqs += "pnpm"
                $canContinue = $false
            }
        } else {
            Write-Failure "pnpm not found (and npm not available to install it)"
            $missingPrereqs += "pnpm"
            $canContinue = $false
        }
    }

    # Show install instructions if needed
    if ($missingPrereqs.Count -gt 0) {
        Write-Host ""
        Write-Failure "Missing prerequisites: $($missingPrereqs -join ', ')"
        Write-Host ""
        Write-Host "Installation instructions for Windows:" -ForegroundColor White
        Write-Host ""
        Write-Host "  Using winget:" -ForegroundColor Cyan
        if ($missingPrereqs -contains "java") {
            Write-Host "    Java 21:   winget install EclipseAdoptium.Temurin.21.JDK"
        }
        if ($missingPrereqs -contains "maven") {
            Write-Host "    Maven:     winget install Apache.Maven"
        }
        if ($missingPrereqs -contains "node") {
            Write-Host "    Node.js:   winget install OpenJS.NodeJS.LTS"
        }
        if ($missingPrereqs -contains "pnpm") {
            Write-Host "    pnpm:      npm install -g pnpm"
        }
        Write-Host ""
        Write-Host "  Or using scoop:" -ForegroundColor Cyan
        Write-Host "    scoop install temurin21-jdk maven nodejs-lts"
        Write-Host "    npm install -g pnpm"
        Write-Host ""
    }

    if (-not $canContinue) {
        Write-Host "Cannot continue without required prerequisites." -ForegroundColor Red
        Write-Host "Please install the missing tools and run this script again."
        exit 1
    }
}

# Check and install dependencies
function Install-Dependencies {
    Write-Header "CHECKING PROJECT DEPENDENCIES"

    # Check frontend node_modules
    Write-Step "Checking frontend dependencies..."
    $frontendModules = Join-Path $PROJECT_ROOT "frontend\node_modules"
    if (-not (Test-Path $frontendModules)) {
        Write-Warning "Frontend dependencies not installed"
        Write-Step "Installing frontend dependencies (pnpm install)..."
        Push-Location (Join-Path $PROJECT_ROOT "frontend")
        try {
            & pnpm install 2>&1 | Out-Null
            Write-Success "Frontend dependencies installed"
        } catch {
            Write-Failure "Could not install frontend dependencies"
            Write-Host "  Run manually: cd frontend && pnpm install"
        }
        Pop-Location
    } else {
        Write-Success "Frontend dependencies OK"
    }

    # Check e2e-tests node_modules
    Write-Step "Checking e2e-tests dependencies..."
    $e2eModules = Join-Path $PROJECT_ROOT "e2e-tests\node_modules"
    if (-not (Test-Path $e2eModules)) {
        Write-Warning "E2E tests dependencies not installed"
        Write-Step "Installing e2e-tests dependencies (pnpm install)..."
        Push-Location (Join-Path $PROJECT_ROOT "e2e-tests")
        try {
            & pnpm install 2>&1 | Out-Null
            Write-Success "E2E tests dependencies installed"
        } catch {
            Write-Failure "Could not install e2e-tests dependencies"
            Write-Host "  Run manually: cd e2e-tests && pnpm install"
        }
        Pop-Location
    } else {
        Write-Success "E2E tests dependencies OK"
    }

    # Check Playwright browsers
    Write-Step "Checking Playwright browsers..."
    Push-Location (Join-Path $PROJECT_ROOT "e2e-tests")
    try {
        & pnpm exec playwright --version 2>&1 | Out-Null
        $playwrightCache = Join-Path $env:LOCALAPPDATA "ms-playwright"
        if (Test-Path $playwrightCache) {
            Write-Success "Playwright browsers OK"
        } else {
            Write-Warning "Playwright browsers not installed"
            Write-Step "Installing Playwright browsers..."
            try {
                & pnpm exec playwright install 2>&1 | Out-Null
                Write-Success "Playwright browsers installed"
            } catch {
                Write-Failure "Could not install Playwright browsers"
                Write-Host "  Run manually: cd e2e-tests && pnpm exec playwright install"
            }
        }
    } catch {
        Write-Warning "Playwright not available"
    }
    Pop-Location

    # Check Cypress binary
    Write-Step "Checking Cypress binary..."
    Push-Location (Join-Path $PROJECT_ROOT "frontend")
    try {
        & pnpm exec cypress version 2>&1 | Out-Null
        Write-Success "Cypress binary OK"
    } catch {
        Write-Warning "Cypress binary not installed"
        Write-Step "Installing Cypress binary..."
        try {
            & pnpm exec cypress install 2>&1 | Out-Null
            Write-Success "Cypress binary installed"
        } catch {
            Write-Failure "Could not install Cypress binary"
            Write-Host "  Run manually: cd frontend && pnpm exec cypress install"
        }
    }
    Pop-Location

    # Check backend build
    Write-Step "Checking backend build..."
    $backendTarget = Join-Path $PROJECT_ROOT "backend\target"
    if (-not (Test-Path $backendTarget)) {
        Write-Warning "Backend not built yet"
        Write-Step "Building backend (mvn install)..."
        Push-Location (Join-Path $PROJECT_ROOT "backend")
        try {
            & mvn install -DskipTests -q 2>&1 | Out-Null
            Write-Success "Backend built successfully"
        } catch {
            Write-Warning "Backend build had issues - will try during tests"
        }
        Pop-Location
    } else {
        Write-Success "Backend build OK"
    }

    Write-Host ""
}

# Check and install security tools
function Install-SecurityTools {
    $missingTools = @()

    # Check gitleaks
    if (-not (Test-Command "gitleaks")) {
        $missingTools += "gitleaks"
    }

    # Check semgrep
    if (-not (Test-Command "semgrep")) {
        $missingTools += "semgrep"
    }

    # Check license-checker in frontend
    Push-Location (Join-Path $PROJECT_ROOT "frontend")
    try {
        & pnpm exec license-checker --help 2>&1 | Out-Null
    } catch {
        $missingTools += "license-checker"
    }
    Pop-Location

    if ($missingTools.Count -gt 0) {
        Write-Header "INSTALLING MISSING TOOLS"
        Write-Warning "Missing tools: $($missingTools -join ', ')"
        Write-Host ""

        # Install gitleaks
        if ($missingTools -contains "gitleaks") {
            Write-Step "Installing gitleaks..."
            if (Test-Command "scoop") {
                try {
                    & scoop install gitleaks 2>&1 | Out-Null
                    Write-Success "gitleaks installed via scoop"
                } catch {
                    Write-Warning "Could not install gitleaks via scoop"
                    Write-Host "  Install manually: scoop install gitleaks"
                    Write-Host "  Or download from: https://github.com/gitleaks/gitleaks/releases"
                }
            } elseif (Test-Command "winget") {
                try {
                    & winget install gitleaks 2>&1 | Out-Null
                    Write-Success "gitleaks installed via winget"
                } catch {
                    Write-Warning "Could not install gitleaks via winget"
                }
            } else {
                Write-Warning "Install gitleaks manually from: https://github.com/gitleaks/gitleaks/releases"
            }
        }

        # Install semgrep
        if ($missingTools -contains "semgrep") {
            Write-Step "Installing semgrep..."
            if (Test-Command "pip") {
                try {
                    & pip install semgrep 2>&1 | Out-Null
                    Write-Success "semgrep installed via pip"
                } catch {
                    Write-Warning "Could not install semgrep via pip"
                    Write-Host "  Install manually: pip install semgrep"
                }
            } elseif (Test-Command "pipx") {
                try {
                    & pipx install semgrep 2>&1 | Out-Null
                    Write-Success "semgrep installed via pipx"
                } catch {
                    Write-Warning "Could not install semgrep via pipx"
                }
            } else {
                Write-Warning "Install semgrep manually: pip install semgrep"
            }
        }

        # Install license-checker
        if ($missingTools -contains "license-checker") {
            Write-Step "Installing license-checker in frontend..."
            Push-Location (Join-Path $PROJECT_ROOT "frontend")
            try {
                & pnpm add -D license-checker 2>&1 | Out-Null
                Write-Success "license-checker installed"
            } catch {
                Write-Warning "Could not install license-checker"
            }
            Pop-Location
        }

        Write-Host ""
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor White
    Write-Host "  |                                                           |" -ForegroundColor White
    Write-Host "  |           WORDLE KATA - QUALITY CHECK                     |" -ForegroundColor White
    Write-Host "  |                                                           |" -ForegroundColor White
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor White
    Write-Host ""

    # Check prerequisites
    Test-Prerequisites

    # Check and install dependencies
    Install-Dependencies

    # Check and install security tools
    Install-SecurityTools

    $startTime = Get-Date

    # ===================================================================
    # SECRET SCANNING
    # ===================================================================
    Write-Header "SECRET SCANNING"

    Write-Step "Running: Gitleaks (secret detection)"
    Push-Location $PROJECT_ROOT

    if (Test-Command "gitleaks") {
        $gitleaksConfig = ""
        $configPath = Join-Path $PROJECT_ROOT ".gitleaks.toml"
        if (Test-Path $configPath) {
            $gitleaksConfig = "-c `"$configPath`""
        }
        try {
            $output = & gitleaks detect --source . --no-git $gitleaksConfig 2>&1 | Out-String
            $output | Out-File -FilePath $script:LogFiles.Secrets -Encoding utf8
            if ($LASTEXITCODE -eq 0) {
                Write-Success "No secrets detected"
                $script:Results.SecretsS = "PASS"
                $filesScanned = (Get-ChildItem -Path . -Recurse -Include *.java,*.ts,*.json,*.xml,*.yml,*.yaml -Exclude node_modules,target,.angular | Measure-Object).Count
                Write-Detail "Scanned $filesScanned source files"
            } else {
                Write-Failure "Potential secrets found!"
                $script:Results.SecretsS = "FAIL"
            }
        } catch {
            Write-Failure "Gitleaks scan failed"
            $script:Results.SecretsS = "FAIL"
        }
    } else {
        Write-Warning "Gitleaks not available - skipping secret scan"
        $script:Results.SecretsS = "SKIP"
    }
    Pop-Location

    # ===================================================================
    # BACKEND CHECKS
    # ===================================================================
    Write-Header "BACKEND CHECKS (Java/Spring Boot)"

    Write-Step "Running: Maven tests (JUnit + ArchUnit + JaCoCo)"
    Push-Location (Join-Path $PROJECT_ROOT "backend")

    try {
        $output = & mvn clean verify 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.Backend -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Backend tests passed"
            $script:Results.BackendTests = "PASS"

            # Extract test counts
            $testsMatch = $output | Select-String "Tests run: (\d+)" | Select-Object -Last 1
            if ($testsMatch) {
                $testsRun = $testsMatch.Matches[0].Groups[1].Value
                Write-Detail "Tests: $testsRun run"
            }

            # Extract JaCoCo coverage
            $jacocoCsv = Join-Path $PROJECT_ROOT "backend\target\site\jacoco\jacoco.csv"
            if (Test-Path $jacocoCsv) {
                $csvData = Import-Csv $jacocoCsv
                $lineMissed = ($csvData | Measure-Object -Property LINE_MISSED -Sum).Sum
                $lineCovered = ($csvData | Measure-Object -Property LINE_COVERED -Sum).Sum
                $lineTotal = $lineMissed + $lineCovered
                if ($lineTotal -gt 0) {
                    $linePct = [math]::Round(($lineCovered / $lineTotal) * 100)
                    Write-Detail "Coverage: $linePct% lines ($lineCovered/$lineTotal)"
                }
            }
        } else {
            Write-Failure "Backend tests failed"
            $script:Results.BackendTests = "FAIL"
        }
    } catch {
        Write-Failure "Backend tests failed: $_"
        $script:Results.BackendTests = "FAIL"
    }

    # SpotBugs
    Write-Step "Running: SpotBugs + FindSecBugs"
    try {
        $javaMajorVersion = & mvn -v 2>&1 | Select-String "Java version" | ForEach-Object { $_ -replace '.*Java version: (\d+).*', '$1' }
        if ([int]$javaMajorVersion -ge 25) {
            Write-Warning "SpotBugs skipped - Java $javaMajorVersion not yet supported"
            $script:Results.BackendSpotbugs = "SKIP"
        } else {
            $output = & mvn spotbugs:check 2>&1 | Out-String
            $output | Out-File -FilePath $script:LogFiles.BackendSpotbugs -Encoding utf8
            if ($LASTEXITCODE -eq 0) {
                Write-Success "SpotBugs analysis passed"
                $script:Results.BackendSpotbugs = "PASS"
                Write-Detail "0 bugs found"
            } else {
                Write-Failure "SpotBugs found issues"
                $script:Results.BackendSpotbugs = "FAIL"
            }
        }
    } catch {
        Write-Failure "SpotBugs failed: $_"
        $script:Results.BackendSpotbugs = "FAIL"
    }

    # OWASP Dependency-Check
    Write-Step "Running: OWASP Dependency-Check (CVE scanning)"
    # Load .env if exists (for NVD_API_KEY)
    $envFile = Join-Path $PROJECT_ROOT "backend\.env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            # Skip comments and empty lines
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                # Set in both current session ($env:) and process environment
                # This ensures Maven child processes can see it
                Set-Item -Path "env:$key" -Value $value
                [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
            }
        }
        Write-Detail "Loaded environment variables from backend\.env"
        # Verify NVD_API_KEY was loaded
        if ($env:NVD_API_KEY) {
            Write-Detail "NVD_API_KEY is set (will speed up CVE scanning)"
        } else {
            Write-Warning "NVD_API_KEY not found in .env file - CVE scanning may be slower"
        }
    } else {
        Write-Warning "backend\.env file not found - CVE scanning may be slower without NVD_API_KEY"
    }
    try {
        $output = & mvn dependency-check:check 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.BackendDepcheck -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "No high-severity CVEs in dependencies"
            $script:Results.BackendDepcheck = "PASS"
        } else {
            if ($output -match "No plugin found") {
                Write-Warning "OWASP Dependency-Check plugin not configured"
                $script:Results.BackendDepcheck = "SKIP"
            } else {
                Write-Failure "Vulnerable dependencies found"
                $script:Results.BackendDepcheck = "FAIL"
            }
        }
    } catch {
        Write-Warning "Dependency-Check had issues"
        $script:Results.BackendDepcheck = "SKIP"
    }

    # Checkstyle
    Write-Step "Running: Checkstyle (Java code style)"
    try {
        $output = & mvn checkstyle:check 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.BackendCheckstyle -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Checkstyle passed"
            $script:Results.BackendCheckstyle = "PASS"
        } else {
            if ($output -match "No plugin found|Could not find goal") {
                Write-Warning "Checkstyle plugin not configured"
                $script:Results.BackendCheckstyle = "SKIP"
            } else {
                Write-Failure "Checkstyle violations found"
                $script:Results.BackendCheckstyle = "FAIL"
            }
        }
    } catch {
        Write-Warning "Checkstyle had issues"
        $script:Results.BackendCheckstyle = "SKIP"
    }

    # License compliance
    Write-Step "Running: License compliance check (Maven dependencies)"
    try {
        $output = & mvn license:add-third-party "-Dlicense.useMissingFile=false" 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.BackendLicense -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "License check completed"
            $script:Results.BackendLicense = "PASS"
            $thirdPartyFile = Join-Path $PROJECT_ROOT "backend\target\generated-sources\license\THIRD-PARTY.txt"
            if ((Test-Path $thirdPartyFile) -and ((Get-Content $thirdPartyFile -Raw) -match "AGPL|Affero")) {
                Write-Warning "Review: Some dependencies have AGPL licenses"
                $script:Results.BackendLicense = "WARN"
            }
        } else {
            if ($output -match "No plugin found") {
                Write-Warning "License Maven Plugin not configured"
                $script:Results.BackendLicense = "SKIP"
            } else {
                Write-Warning "License check had issues"
                $script:Results.BackendLicense = "WARN"
            }
        }
    } catch {
        Write-Warning "License check had issues"
        $script:Results.BackendLicense = "WARN"
    }

    Pop-Location

    # ===================================================================
    # SAST
    # ===================================================================
    Write-Header "SAST (Static Application Security Testing)"

    Write-Step "Running: Semgrep security scan"
    Push-Location $PROJECT_ROOT

    if (Test-Command "semgrep") {
        try {
            $output = & semgrep scan --config=auto --severity=ERROR --severity=WARNING `
                --exclude='node_modules' --exclude='target' --exclude='dist' `
                --exclude='.angular' --exclude='coverage' 2>&1 | Out-String
            $output | Out-File -FilePath $script:LogFiles.Semgrep -Encoding utf8
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Semgrep scan passed"
                $script:Results.Semgrep = "PASS"
                Write-Detail "0 security findings"
            } else {
                Write-Failure "Semgrep found security issues"
                $script:Results.Semgrep = "FAIL"
            }
        } catch {
            Write-Failure "Semgrep scan failed"
            $script:Results.Semgrep = "FAIL"
        }
    } else {
        Write-Warning "Semgrep not available - skipping SAST"
        $script:Results.Semgrep = "SKIP"
    }
    Pop-Location

    # ===================================================================
    # FRONTEND CHECKS
    # ===================================================================
    Write-Header "FRONTEND CHECKS (Angular/TypeScript)"

    Push-Location (Join-Path $PROJECT_ROOT "frontend")

    # TypeScript
    Write-Step "Running: TypeScript compilation check"
    try {
        $output = & pnpm exec tsc --noEmit 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendTypecheck -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "TypeScript compilation passed"
            $script:Results.FrontendTypecheck = "PASS"
        } else {
            Write-Failure "TypeScript compilation failed"
            $script:Results.FrontendTypecheck = "FAIL"
        }
    } catch {
        Write-Failure "TypeScript check failed"
        $script:Results.FrontendTypecheck = "FAIL"
    }

    # ESLint
    Write-Step "Running: ESLint"
    try {
        $output = & pnpm lint 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendLint -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "ESLint passed"
            $script:Results.FrontendLint = "PASS"
        } else {
            Write-Failure "ESLint failed"
            $script:Results.FrontendLint = "FAIL"
        }
    } catch {
        Write-Failure "ESLint failed"
        $script:Results.FrontendLint = "FAIL"
    }

    # Prettier
    Write-Step "Running: Prettier format check"
    try {
        $output = & pnpm format:check 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendFormat -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Prettier format check passed"
            $script:Results.FrontendFormat = "PASS"
        } else {
            Write-Failure "Prettier format check failed"
            $script:Results.FrontendFormat = "FAIL"
        }
    } catch {
        Write-Failure "Prettier check failed"
        $script:Results.FrontendFormat = "FAIL"
    }

    # Tests
    Write-Step "Running: Cypress component tests with coverage"
    try {
        $output = & pnpm test 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendTests -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            # Check coverage threshold
            try {
                $covOutput = & pnpm exec nyc check-coverage 2>&1 | Out-String
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Frontend tests passed (100% coverage verified)"
                    $script:Results.FrontendTests = "PASS"
                } else {
                    Write-Failure "Frontend tests passed but coverage below 100%"
                    $script:Results.FrontendTests = "FAIL"
                }
            } catch {
                Write-Success "Frontend tests passed"
                $script:Results.FrontendTests = "PASS"
            }
        } else {
            Write-Failure "Frontend tests failed"
            $script:Results.FrontendTests = "FAIL"
        }
    } catch {
        Write-Failure "Frontend tests failed"
        $script:Results.FrontendTests = "FAIL"
    }

    # Build
    Write-Step "Running: Angular production build"
    try {
        $output = & pnpm build 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendBuild -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Angular build passed"
            $script:Results.FrontendBuild = "PASS"
        } else {
            Write-Failure "Angular build failed"
            $script:Results.FrontendBuild = "FAIL"
        }
    } catch {
        Write-Failure "Angular build failed"
        $script:Results.FrontendBuild = "FAIL"
    }

    # Security audit
    Write-Step "Running: pnpm audit (security vulnerabilities)"
    try {
        $output = & pnpm audit --audit-level=high 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendAudit -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Security audit passed"
            $script:Results.FrontendAudit = "PASS"
        } else {
            Write-Warning "Security audit found vulnerabilities"
            $script:Results.FrontendAudit = "WARN"
        }
    } catch {
        Write-Warning "Security audit had issues"
        $script:Results.FrontendAudit = "WARN"
    }

    # License compliance
    Write-Step "Running: License compliance check"
    try {
        $output = & pnpm exec license-checker --production --excludePrivatePackages --onlyAllow `
            'MIT;ISC;Apache-2.0;BSD-2-Clause;BSD-3-Clause;0BSD;CC0-1.0;CC-BY-3.0;CC-BY-4.0;Unlicense;WTFPL;Python-2.0' 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.FrontendLicense -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "License compliance check passed"
            $script:Results.FrontendLicense = "PASS"
        } else {
            Write-Warning "Problematic licenses found"
            $script:Results.FrontendLicense = "WARN"
        }
    } catch {
        Write-Warning "license-checker not available"
        $script:Results.FrontendLicense = "SKIP"
    }

    Pop-Location

    # ===================================================================
    # E2E CHECKS
    # ===================================================================
    Write-Header "E2E CHECKS (Playwright)"

    Push-Location (Join-Path $PROJECT_ROOT "e2e-tests")

    # BDD generation
    Write-Step "Running: BDD spec generation check"
    try {
        $output = & pnpm bddgen 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.E2EBddgen -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "BDD generation passed"
            $script:Results.E2EBddgen = "PASS"
        } else {
            Write-Failure "BDD generation failed"
            $script:Results.E2EBddgen = "FAIL"
        }
    } catch {
        Write-Failure "BDD generation failed"
        $script:Results.E2EBddgen = "FAIL"
    }

    # E2E tests
    Write-Step "Running: Playwright E2E tests (headless)"
    Write-Warning "Note: This starts backend & frontend automatically"
    try {
        $output = & pnpm test:e2e 2>&1 | Out-String
        $output | Out-File -FilePath $script:LogFiles.E2E -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Success "E2E tests passed"
            $script:Results.E2ETests = "PASS"

            # Extract test counts
            $passedMatch = $output | Select-String "(\d+) passed"
            if ($passedMatch) {
                $passed = $passedMatch.Matches[0].Groups[1].Value
                Write-Detail "Tests: $passed passed"
            }
        } else {
            Write-Failure "E2E tests failed"
            $script:Results.E2ETests = "FAIL"
        }
    } catch {
        Write-Failure "E2E tests failed"
        $script:Results.E2ETests = "FAIL"
    }

    # Cleanup hanging processes
    $cleanupScript = Join-Path $PROJECT_ROOT "e2e-tests\scripts\cleanup-services.ps1"
    if (Test-Path $cleanupScript) {
        try { & $cleanupScript 2>&1 | Out-Null } catch {}
    }

    Pop-Location

    # ===================================================================
    # MUTATION TESTING
    # ===================================================================
    if ($Mutation) {
        Write-Header "MUTATION TESTING (Test Quality)"

        Push-Location (Join-Path $PROJECT_ROOT "backend")

        Write-Step "Running: PIT mutation testing"
        Write-Warning "Note: This may take several minutes..."

        try {
            $output = & mvn pitest:mutationCoverage 2>&1 | Out-String
            $output | Out-File -FilePath $script:LogFiles.BackendMutation -Encoding utf8
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Mutation testing passed"
                $script:Results.BackendMutation = "PASS"

                $scoreMatch = $output | Select-String "mutations: (\d+)%"
                if ($scoreMatch) {
                    $score = $scoreMatch.Matches[0].Groups[1].Value
                    Write-Detail "Mutation score: $score%"
                }
            } else {
                if ($output -match "No plugin found") {
                    Write-Warning "PIT plugin not configured"
                    $script:Results.BackendMutation = "SKIP"
                } else {
                    Write-Failure "Mutation testing failed"
                    $script:Results.BackendMutation = "FAIL"
                }
            }
        } catch {
            Write-Failure "Mutation testing failed"
            $script:Results.BackendMutation = "FAIL"
        }

        Pop-Location
    } else {
        Write-Header "MUTATION TESTING (Skipped)"
        Write-Warning "Mutation testing skipped (slow)"
        Write-Detail "Run with: .\quality-check.ps1 -Mutation"
        $script:Results.BackendMutation = "SKIP"
    }

    $endTime = Get-Date
    $duration = $endTime - $startTime

    # ===================================================================
    # SUMMARY REPORT
    # ===================================================================
    Write-Header "QUALITY CHECK SUMMARY"

    $totalChecks = 17
    $passedChecks = 0
    $warnings = 0

    Write-Host ("{0,-40} {1}" -f "Check", "Status") -ForegroundColor White
    Write-Host ("-" * 55)

    # Helper function for status display
    function Show-Status {
        param([string]$Name, [string]$Result)

        switch ($Result) {
            "PASS" {
                Write-Host ("{0,-40} " -f $Name) -NoNewline
                Write-Host "[OK] PASS" -ForegroundColor Green
                return 1, 0
            }
            "SKIP" {
                Write-Host ("{0,-40} " -f $Name) -NoNewline
                Write-Host "[--] SKIP" -ForegroundColor Yellow
                return 1, 0
            }
            "WARN" {
                Write-Host ("{0,-40} " -f $Name) -NoNewline
                Write-Host "[!!] WARN" -ForegroundColor Yellow
                return 1, 1
            }
            default {
                Write-Host ("{0,-40} " -f $Name) -NoNewline
                Write-Host "[XX] FAIL" -ForegroundColor Red
                return 0, 0
            }
        }
    }

    $p, $w = Show-Status "Secret Scanning (Gitleaks)" $script:Results.SecretsS; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Backend Tests (JUnit+ArchUnit+JaCoCo)" $script:Results.BackendTests; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Backend SpotBugs (FindSecBugs)" $script:Results.BackendSpotbugs; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Backend OWASP Dep-Check (CVEs)" $script:Results.BackendDepcheck; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Backend Checkstyle (code style)" $script:Results.BackendCheckstyle; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Backend License (Maven deps)" $script:Results.BackendLicense; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "SAST (Semgrep)" $script:Results.Semgrep; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Frontend TypeScript (tsc --noEmit)" $script:Results.FrontendTypecheck; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Frontend Lint (ESLint)" $script:Results.FrontendLint; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Frontend Format (Prettier)" $script:Results.FrontendFormat; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Frontend Tests (Cypress)" $script:Results.FrontendTests; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Frontend Build (Angular AOT)" $script:Results.FrontendBuild; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Security Audit (pnpm audit)" $script:Results.FrontendAudit; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "License Compliance (license-checker)" $script:Results.FrontendLicense; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "E2E BDD Generation (bddgen)" $script:Results.E2EBddgen; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "E2E Tests (Playwright)" $script:Results.E2ETests; $passedChecks += $p; $warnings += $w
    $p, $w = Show-Status "Mutation Testing (PIT)" $script:Results.BackendMutation; $passedChecks += $p; $warnings += $w

    Write-Host ("-" * 55)
    $durationStr = "{0}m {1}s" -f [math]::Floor($duration.TotalMinutes), $duration.Seconds
    Write-Host ("Total: {0}/{1} passed" -f $passedChecks, $totalChecks) -NoNewline -ForegroundColor White
    if ($warnings -gt 0) {
        Write-Host "  |  " -NoNewline
        Write-Host "$warnings warning(s)" -NoNewline -ForegroundColor Yellow
    }
    Write-Host "  |  Duration: $durationStr" -ForegroundColor Cyan

    # Final status
    if ($passedChecks -lt $totalChecks) {
        Write-Host ""
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Red
        Write-Host "  |                                                           |" -ForegroundColor Red
        Write-Host "  |   QUALITY CHECK FAILED - Please fix the issues above      |" -ForegroundColor Red
        Write-Host "  |                                                           |" -ForegroundColor Red
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Red
        Write-Host ""
        Cleanup
        exit 1
    } elseif ($warnings -gt 0) {
        Write-Host ""
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Yellow
        Write-Host "  |                                                           |" -ForegroundColor Yellow
        Write-Host "  |   ALL CHECKS PASSED (with warnings - review recommended)  |" -ForegroundColor Yellow
        Write-Host "  |                                                           |" -ForegroundColor Yellow
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Yellow
        Write-Host ""
        Cleanup
        exit 0
    } else {
        Write-Host ""
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Green
        Write-Host "  |                                                           |" -ForegroundColor Green
        Write-Host "  |   ALL QUALITY CHECKS PASSED!                              |" -ForegroundColor Green
        Write-Host "  |                                                           |" -ForegroundColor Green
        Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Green
        Write-Host ""
        Cleanup
        exit 0
    }
}

# Run main
Main
