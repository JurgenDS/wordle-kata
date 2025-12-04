# PowerShell script to verify NVD_API_KEY is accessible to Maven
# Usage: .\scripts\verify-nvd-key.ps1

Write-Host "Verifying NVD_API_KEY configuration..." -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
$ENV_FILE = Join-Path (Split-Path -Parent $PSScriptRoot) ".env"
if (Test-Path $ENV_FILE) {
    Write-Host "✓ .env file found at: $ENV_FILE" -ForegroundColor Green
    
    # Load .env file
    Get-Content $ENV_FILE | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$key" -Value $value
            [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
        }
    }
} else {
    Write-Host "✗ .env file not found at: $ENV_FILE" -ForegroundColor Red
    Write-Host "  Create it with: NVD_API_KEY=your-key-here" -ForegroundColor Yellow
    exit 1
}

# Check if NVD_API_KEY is set
if ($env:NVD_API_KEY) {
    $keyPreview = $env:NVD_API_KEY.Substring(0, [Math]::Min(8, $env:NVD_API_KEY.Length))
    Write-Host "✓ NVD_API_KEY is set: $keyPreview..." -ForegroundColor Green
    Write-Host "  Full key length: $($env:NVD_API_KEY.Length) characters" -ForegroundColor Gray
} else {
    Write-Host "✗ NVD_API_KEY is not set" -ForegroundColor Red
    exit 1
}

# Verify Maven can see it by checking environment in a Maven command
Write-Host ""
Write-Host "Testing if Maven can access NVD_API_KEY..." -ForegroundColor Cyan
$mavenTest = & mvn help:evaluate -Dexpression=env.NVD_API_KEY -q -DforceStdout 2>&1
if ($mavenTest -and $mavenTest -ne "null") {
    Write-Host "✓ Maven can access NVD_API_KEY" -ForegroundColor Green
} else {
    Write-Host "⚠ Maven cannot access NVD_API_KEY from environment" -ForegroundColor Yellow
    Write-Host "  This might mean the key needs to be set differently" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To use the API key with Maven, run:" -ForegroundColor Cyan
Write-Host "  .\mvn-with-env.ps1 dependency-check:check" -ForegroundColor White
Write-Host ""
Write-Host "Or set it manually before running Maven:" -ForegroundColor Cyan
Write-Host "  `$env:NVD_API_KEY = 'your-key-here'" -ForegroundColor White
Write-Host "  mvn dependency-check:check" -ForegroundColor White

