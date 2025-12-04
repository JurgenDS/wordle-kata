# PowerShell script to run Maven commands with .env file loaded
# Usage: .\mvn-with-env.ps1 install
#        .\mvn-with-env.ps1 clean verify
#        .\mvn-with-env.ps1 dependency-check:check

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$MavenArgs
)

# Get the backend directory (where this script is located)
$BACKEND_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $BACKEND_DIR ".env"

# Load .env file if it exists
if (Test-Path $ENV_FILE) {
    Write-Host "Loading environment variables from .env..." -ForegroundColor Cyan
    Get-Content $ENV_FILE | ForEach-Object {
        # Skip comments and empty lines
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Set in both current session ($env:) and process environment
            Set-Item -Path "env:$key" -Value $value
            [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
        }
    }
    if ($env:NVD_API_KEY) {
        $keyPreview = $env:NVD_API_KEY.Substring(0, [Math]::Min(8, $env:NVD_API_KEY.Length))
        Write-Host "NVD_API_KEY loaded: $keyPreview... (will speed up OWASP Dependency-Check)" -ForegroundColor Green
    } else {
        Write-Host "Warning: NVD_API_KEY not found in .env file" -ForegroundColor Yellow
        Write-Host "  CVE scanning will be slower (downloading full NVD database)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: .env file not found at $ENV_FILE" -ForegroundColor Yellow
    Write-Host "  Create it with: NVD_API_KEY=your-key-here" -ForegroundColor Yellow
    Write-Host "  CVE scanning will be slower without API key" -ForegroundColor Yellow
}

# Verify the key is set before running Maven
if (-not $env:NVD_API_KEY) {
    Write-Host ""
    Write-Host "Note: Running without NVD_API_KEY - this may take several minutes" -ForegroundColor Yellow
    Write-Host "      Get a free API key at: https://nvd.nist.gov/developers/request-an-api-key" -ForegroundColor Cyan
}

# Run Maven with the provided arguments
Write-Host ""
Write-Host "Running: mvn $($MavenArgs -join ' ')" -ForegroundColor Cyan
& mvn @MavenArgs

