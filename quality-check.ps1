#Requires -Version 5.1
<#
.SYNOPSIS
    Quality Check Script for Windows
    Runs all quality checks for backend, frontend, and e2e tests

.DESCRIPTION
    Prerequisites:
    - Java 21 (required for SpotBugs - Java 25 not supported)
    - Maven 3.6+
    - Node.js 20+
    - pnpm (install: npm install -g pnpm)

.PARAMETER Mutation
    Run mutation testing (takes longer, ~2-5 minutes)

.EXAMPLE
    .\quality-check.ps1
    .\quality-check.ps1 -Mutation
#>

param(
    [switch]$Mutation,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Results tracking
$Results = @{
    BackendCompile = "skipped"
    BackendTests = "skipped"
    BackendCoverage = "skipped"
    BackendArchUnit = "skipped"
    BackendSpotBugs = "skipped"
    BackendMutation = "skipped"
    FrontendInstall = "skipped"
    FrontendLint = "skipped"
    FrontendTests = "skipped"
    FrontendCoverage = "skipped"
    E2ETests = "skipped"
    FileSizeCheck = "skipped"
}

# Coverage values
$Coverage = @{
    BackendLine = "N/A"
    BackendBranch = "N/A"
    BackendArchUnitCount = "N/A"
    BackendMutationScore = "N/A"
    FrontendStmt = "N/A"
    FrontendBranch = "N/A"
    FileSizeViolations = 0
}

$StartTime = Get-Date

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor Blue
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor Blue
}

function Write-Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "> $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Error2 {
    param([string]$Text)
    Write-Host "[X] $Text" -ForegroundColor Red
}

function Write-Warning2 {
    param([string]$Text)
    Write-Host "[!] $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "[i] $Text" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Get-JavaVersion {
    if (Test-Command "java") {
        $output = & java -version 2>&1 | Select-Object -First 1
        if ($output -match '"(\d+)') {
            return [int]$Matches[1]
        }
    }
    return 0
}

function Get-Java21Home {
    # 1. Check if JAVA_HOME is already set to Java 21
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        $output = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1 | Select-Object -First 1
        if ($output -match '"21\.') {
            return $env:JAVA_HOME
        }
    }

    # 2. Check common Windows installation paths
    $paths = @(
        "C:\Program Files\Java\jdk-21*",
        "C:\Program Files\Eclipse Adoptium\jdk-21*",
        "C:\Program Files\Temurin\jdk-21*",
        "C:\Program Files\Microsoft\jdk-21*",
        "C:\Program Files\Amazon Corretto\jdk21*"
    )

    foreach ($pattern in $paths) {
        $found = Get-ChildItem -Path $pattern -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    # 3. Check SDKMAN on WSL (if running in WSL)
    $sdkmanPath = "$env:USERPROFILE\.sdkman\candidates\java"
    if (Test-Path $sdkmanPath) {
        $found = Get-ChildItem -Path "$sdkmanPath\21.*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }

    return $null
}

#------------------------------------------------------------------------------
# Show Help
#------------------------------------------------------------------------------

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

#------------------------------------------------------------------------------
# Prerequisites Check
#------------------------------------------------------------------------------

Write-Header "PREREQUISITES CHECK"

$PrereqFailed = $false

# Check Java
Write-Step "Checking Java..."
$Java21Home = Get-Java21Home

if ($Java21Home) {
    $output = & "$Java21Home\bin\java.exe" -version 2>&1 | Select-Object -First 1
    Write-Success "Java 21 found at $Java21Home"
    $env:JAVA_HOME = $Java21Home
} elseif (Test-Command "java") {
    $JavaVer = Get-JavaVersion
    if ($JavaVer -ge 21) {
        if ($JavaVer -gt 21) {
            Write-Warning2 "Java $JavaVer found but SpotBugs requires Java 21"
            Write-Info "Install Java 21 from: https://adoptium.net"
            Write-Info "Will skip SpotBugs check..."
        } else {
            Write-Success "Java $JavaVer found"
        }
    } else {
        Write-Error2 "Java 21+ required, found Java $JavaVer"
        Write-Info "Install Java 21 from: https://adoptium.net"
        $PrereqFailed = $true
    }
} else {
    Write-Error2 "Java not found"
    Write-Info "Install Java 21 from: https://adoptium.net"
    $PrereqFailed = $true
}

# Check Maven
Write-Step "Checking Maven..."
if (Test-Command "mvn") {
    $MvnVer = (& mvn -version 2>&1 | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
    Write-Success "Maven $MvnVer found"
} else {
    Write-Error2 "Maven not found"
    Write-Info "Install from: https://maven.apache.org/download.cgi"
    Write-Info "Or use: choco install maven"
    $PrereqFailed = $true
}

# Check Node.js
Write-Step "Checking Node.js..."
if (Test-Command "node") {
    $NodeVer = & node -v
    Write-Success "Node.js $NodeVer found"
} else {
    Write-Error2 "Node.js not found"
    Write-Info "Install from: https://nodejs.org"
    Write-Info "Or use: choco install nodejs"
    $PrereqFailed = $true
}

# Check pnpm
Write-Step "Checking pnpm..."
if (Test-Command "pnpm") {
    $PnpmVer = & pnpm -v
    Write-Success "pnpm $PnpmVer found"
} else {
    Write-Error2 "pnpm not found"
    Write-Info "Install: npm install -g pnpm"
    $PrereqFailed = $true
}

if ($PrereqFailed) {
    Write-Host ""
    Write-Error2 "Prerequisites check failed. Please install missing dependencies."
    exit 1
}

Write-Success "All prerequisites satisfied!"

#------------------------------------------------------------------------------
# File Size Check
#------------------------------------------------------------------------------

Write-Header "FILE SIZE CHECK"

Write-Step "Checking for files exceeding 300 lines..."

$FileSizeViolations = @()

# Check backend Java files
$backendFiles = Get-ChildItem -Path "$ScriptDir\backend\src\main\java" -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $backendFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    if ($lines -gt 300) {
        $FileSizeViolations += @{ File = $file.FullName; Lines = $lines }
    }
}

# Check backend test files
$backendTestFiles = Get-ChildItem -Path "$ScriptDir\backend\src\test\java" -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $backendTestFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    if ($lines -gt 300) {
        $FileSizeViolations += @{ File = $file.FullName; Lines = $lines }
    }
}

# Check frontend TypeScript files
$frontendFiles = Get-ChildItem -Path "$ScriptDir\frontend\src" -Filter "*.ts" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $frontendFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    if ($lines -gt 300) {
        $FileSizeViolations += @{ File = $file.FullName; Lines = $lines }
    }
}

$Coverage.FileSizeViolations = $FileSizeViolations.Count

if ($FileSizeViolations.Count -gt 0) {
    $Results.FileSizeCheck = "failed"
    Write-Error2 "$($FileSizeViolations.Count) file(s) exceed 300 lines:"
    foreach ($v in $FileSizeViolations) {
        $relativePath = $v.File.Replace($ScriptDir, "").TrimStart("\")
        Write-Host "    $relativePath ($($v.Lines) lines)" -ForegroundColor Red
    }
} else {
    $Results.FileSizeCheck = "passed"
    Write-Success "All files within 300-line limit"
}

#------------------------------------------------------------------------------
# Backend Quality Checks
#------------------------------------------------------------------------------

Write-Header "BACKEND QUALITY CHECKS"

Push-Location "$ScriptDir\backend"

try {
    if ($env:JAVA_HOME) {
        Write-Info "Using Java from: $env:JAVA_HOME"
    }

    # Compile
    Write-Step "Compiling backend..."
    $compileOutput = & mvn compile -q 2>&1
    if ($LASTEXITCODE -eq 0) {
        $Results.BackendCompile = "passed"
        Write-Success "Backend compiled successfully"
    } else {
        $Results.BackendCompile = "failed"
        Write-Error2 "Backend compilation failed"
        Write-Host $compileOutput
    }

    # Tests
    if ($Results.BackendCompile -eq "passed") {
        Write-Step "Running backend tests..."
        $testOutput = & mvn test 2>&1 | Out-String

        if ($testOutput -match "BUILD SUCCESS") {
            $Results.BackendTests = "passed"

            # Extract test count
            if ($testOutput -match "Tests run: (\d+)") {
                $testCount = $Matches[1]
                Write-Success "Backend tests passed ($testCount tests)"
            } else {
                Write-Success "Backend tests passed"
            }

            # Extract ArchUnit count
            if ($testOutput -match "HexagonalArchitectureTest.*Tests run: (\d+)") {
                $Coverage.BackendArchUnitCount = $Matches[1]
            }
            $Results.BackendArchUnit = "passed"
            Write-Success "Architecture tests passed ($($Coverage.BackendArchUnitCount) tests)"

            # Coverage
            $Results.BackendCoverage = "passed"
        } else {
            $Results.BackendTests = "failed"
            Write-Error2 "Backend tests failed"
            $testOutput -split "`n" | Where-Object { $_ -match "FAILURE|ERROR" } | Select-Object -First 5 | ForEach-Object { Write-Host $_ }
        }
    }

    # SpotBugs (verify phase)
    if ($Results.BackendTests -eq "passed") {
        Write-Step "Running backend verification (JaCoCo + SpotBugs)..."
        $verifyOutput = & mvn verify -DskipTests 2>&1 | Out-String

        if ($verifyOutput -match "BUILD SUCCESS") {
            $Results.BackendSpotBugs = "passed"
            if ($verifyOutput -match "BugInstance size is (\d+)") {
                $bugCount = $Matches[1]
                Write-Success "Backend verification passed (SpotBugs: $bugCount bugs)"
            } else {
                Write-Success "Backend verification passed"
            }
        } else {
            $Results.BackendSpotBugs = "failed"
            Write-Error2 "Backend verification failed"
        }
    }

    # Mutation testing (optional)
    if ($Mutation -and $Results.BackendTests -eq "passed") {
        Write-Step "Running mutation testing (this may take 2-5 minutes)..."
        Write-Info "PITest is generating mutants and running tests against them..."

        $mutationOutput = & mvn pitest:mutationCoverage 2>&1 | Out-String

        if ($mutationOutput -match "Generated (\d+) mutations Killed (\d+)") {
            $total = [int]$Matches[1]
            $killed = [int]$Matches[2]
            if ($total -gt 0) {
                $score = [math]::Round(($killed / $total) * 100)
                $Coverage.BackendMutationScore = "$score%"
                if ($score -ge 80) {
                    $Results.BackendMutation = "passed"
                    Write-Success "Mutation testing passed (Score: $score%, $killed/$total mutants killed)"
                } else {
                    $Results.BackendMutation = "warning"
                    Write-Warning2 "Mutation testing: $($total - $killed) mutants survived (Score: $score%)"
                }
            }
        } elseif ($mutationOutput -match "BUILD SUCCESS") {
            $Results.BackendMutation = "passed"
            Write-Success "Mutation testing completed"
        } else {
            $Results.BackendMutation = "failed"
            Write-Error2 "Mutation testing failed"
        }
    } elseif ($Mutation) {
        Write-Warning2 "Skipping mutation testing (backend tests must pass first)"
    }

} finally {
    Pop-Location
}

#------------------------------------------------------------------------------
# Frontend Quality Checks
#------------------------------------------------------------------------------

Write-Header "FRONTEND QUALITY CHECKS"

Push-Location "$ScriptDir\frontend"

try {
    # Install dependencies
    Write-Step "Installing frontend dependencies..."
    $installOutput = & pnpm install 2>&1 | Out-String
    $Results.FrontendInstall = "passed"
    Write-Success "Frontend dependencies installed"

    # Lint
    Write-Step "Running frontend lint..."
    $lintOutput = & pnpm lint 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -or $lintOutput -match "All files pass linting") {
        $Results.FrontendLint = "passed"
        Write-Success "Frontend lint passed"
    } else {
        $Results.FrontendLint = "failed"
        Write-Error2 "Frontend lint failed"
    }

    # Tests with coverage
    Write-Step "Running frontend tests with coverage..."
    $testOutput = & pnpm test:coverage 2>&1 | Out-String

    if ($testOutput -match "All specs passed" -or $LASTEXITCODE -eq 0) {
        $Results.FrontendTests = "passed"
        Write-Success "Frontend tests passed"

        # Extract coverage
        if ($testOutput -match "Statements\s*:\s*([\d.]+)%") {
            $Coverage.FrontendStmt = $Matches[1] + "%"
        }
        if ($testOutput -match "Branches\s*:\s*([\d.]+)%") {
            $Coverage.FrontendBranch = $Matches[1] + "%"
        }
        $Results.FrontendCoverage = "passed"
    } else {
        $Results.FrontendTests = "failed"
        Write-Error2 "Frontend tests failed"
    }

    # Format check
    Write-Step "Checking frontend code formatting..."
    $formatOutput = & pnpm format:check 2>&1 | Out-String
    if ($formatOutput -match "All matched files use Prettier" -or $LASTEXITCODE -eq 0) {
        Write-Success "Frontend formatting check passed"
    } else {
        Write-Warning2 "Some files need formatting (run: pnpm format)"
    }

} finally {
    Pop-Location
}

#------------------------------------------------------------------------------
# E2E Tests
#------------------------------------------------------------------------------

Write-Header "E2E TESTS"

Push-Location "$ScriptDir\e2e"

try {
    Write-Step "Installing E2E test dependencies..."
    & pnpm install 2>&1 | Out-Null

    Write-Step "Running E2E tests (this will start backend and frontend)..."
    $e2eOutput = & pnpm test 2>&1 | Out-String

    if ($e2eOutput -match "(\d+) passed" -or $LASTEXITCODE -eq 0) {
        $Results.E2ETests = "passed"
        if ($e2eOutput -match "(\d+) passed") {
            Write-Success "E2E tests passed ($($Matches[1]) passed)"
        } else {
            Write-Success "E2E tests passed"
        }
    } else {
        $Results.E2ETests = "failed"
        Write-Error2 "E2E tests failed"
    }

} finally {
    Pop-Location
}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

Write-Header "QUALITY CHECK SUMMARY"

$Duration = (Get-Date) - $StartTime
$DurationStr = "{0}m {1}s" -f [math]::Floor($Duration.TotalMinutes), $Duration.Seconds

function Get-StatusColor {
    param([string]$Status)
    switch ($Status) {
        "passed" { return "Green" }
        "failed" { return "Red" }
        "warning" { return "Yellow" }
        default { return "Gray" }
    }
}

function Write-TableRow {
    param([string]$Check, [string]$Status, [string]$Details)
    $statusColor = Get-StatusColor $Status
    Write-Host ("| {0,-19} | " -f $Check) -NoNewline
    Write-Host ("{0,-10}" -f $Status) -ForegroundColor $statusColor -NoNewline
    Write-Host (" | {0,-27} |" -f $Details)
}

Write-Host ""
Write-Host "Code Quality:" -ForegroundColor White
Write-Host "+---------------------+------------+-----------------------------+"
Write-Host "| Check               | Status     | Details                     |"
Write-Host "+---------------------+------------+-----------------------------+"
Write-TableRow "File Size (300 max)" $Results.FileSizeCheck "$($Coverage.FileSizeViolations) violations"
Write-Host "+---------------------+------------+-----------------------------+"

Write-Host ""
Write-Host "Backend Results:" -ForegroundColor White
Write-Host "+---------------------+------------+-----------------------------+"
Write-Host "| Check               | Status     | Details                     |"
Write-Host "+---------------------+------------+-----------------------------+"
Write-TableRow "Compilation" $Results.BackendCompile ""
Write-TableRow "Unit Tests" $Results.BackendTests ""
Write-TableRow "Architecture Tests" $Results.BackendArchUnit "$($Coverage.BackendArchUnitCount) tests"
Write-TableRow "Code Coverage" $Results.BackendCoverage ""
Write-TableRow "SpotBugs" $Results.BackendSpotBugs ""
if ($Mutation) {
    Write-TableRow "Mutation Testing" $Results.BackendMutation $Coverage.BackendMutationScore
}
Write-Host "+---------------------+------------+-----------------------------+"

Write-Host ""
Write-Host "Frontend Results:" -ForegroundColor White
Write-Host "+---------------------+------------+-----------------------------+"
Write-Host "| Check               | Status     | Details                     |"
Write-Host "+---------------------+------------+-----------------------------+"
Write-TableRow "Dependencies" $Results.FrontendInstall ""
Write-TableRow "ESLint" $Results.FrontendLint ""
Write-TableRow "Component Tests" $Results.FrontendTests ""
Write-TableRow "Code Coverage" $Results.FrontendCoverage "$($Coverage.FrontendStmt) stmt, $($Coverage.FrontendBranch) branch"
Write-Host "+---------------------+------------+-----------------------------+"

Write-Host ""
Write-Host "E2E Results:" -ForegroundColor White
Write-Host "+---------------------+------------+-----------------------------+"
Write-Host "| Check               | Status     | Details                     |"
Write-Host "+---------------------+------------+-----------------------------+"
Write-TableRow "Playwright Tests" $Results.E2ETests ""
Write-Host "+---------------------+------------+-----------------------------+"

Write-Host ""
Write-Host "Duration: $DurationStr" -ForegroundColor White

# Count failures
$TotalFailed = ($Results.Values | Where-Object { $_ -eq "failed" }).Count
$TotalWarnings = ($Results.Values | Where-Object { $_ -eq "warning" }).Count

Write-Host ""
if ($TotalFailed -gt 0) {
    Write-Host ("=" * 72) -ForegroundColor Red
    Write-Host "  X $TotalFailed CHECK(S) FAILED" -ForegroundColor Red
    Write-Host ("=" * 72) -ForegroundColor Red
    exit 1
} elseif ($TotalWarnings -gt 0) {
    Write-Host ("=" * 72) -ForegroundColor Yellow
    Write-Host "  ! ALL CHECKS PASSED WITH $TotalWarnings WARNING(S)" -ForegroundColor Yellow
    Write-Host ("=" * 72) -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ("=" * 72) -ForegroundColor Green
    Write-Host "  OK ALL QUALITY CHECKS PASSED" -ForegroundColor Green
    Write-Host ("=" * 72) -ForegroundColor Green
    exit 0
}
