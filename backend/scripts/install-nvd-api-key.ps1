# PowerShell script to install NVD_API_KEY as a Windows environment variable
# This makes the key available to all processes without needing to load from .env file
# Usage: .\scripts\install-nvd-api-key.ps1
#        .\scripts\install-nvd-api-key.ps1 -System (requires Administrator)

param(
    [switch]$System,  # Set as system variable (requires Administrator)
    [string]$ApiKey   # API key to set (optional, will read from .env or prompt)
)

# Check if running as Administrator (needed for -System)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($System -and -not $isAdmin) {
    Write-Host "Error: Setting system environment variable requires Administrator privileges." -ForegroundColor Red
    Write-Host "Either:" -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host "  2. Use without -System flag to set as user variable (recommended)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Installing NVD_API_KEY as Windows environment variable..." -ForegroundColor Cyan
Write-Host ""

# Determine target scope
$scope = if ($System) { "System" } else { "User" }
Write-Host "Target scope: $scope" -ForegroundColor Cyan

# Get API key from parameter, .env file, or prompt
$apiKeyValue = $null

if ($ApiKey) {
    $apiKeyValue = $ApiKey
    Write-Host "Using API key from parameter" -ForegroundColor Green
} else {
    # Try to read from .env file
    $BACKEND_DIR = Split-Path -Parent $PSScriptRoot
    $ENV_FILE = Join-Path $BACKEND_DIR ".env"
    
    if (Test-Path $ENV_FILE) {
        Write-Host "Reading from .env file: $ENV_FILE" -ForegroundColor Cyan
        Get-Content $ENV_FILE | ForEach-Object {
            if ($_ -match '^\s*NVD_API_KEY\s*=\s*(.+)$') {
                $apiKeyValue = $matches[1].Trim()
            }
        }
        
        if ($apiKeyValue) {
            Write-Host "✓ Found NVD_API_KEY in .env file" -ForegroundColor Green
        } else {
            Write-Host "⚠ NVD_API_KEY not found in .env file" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ .env file not found at: $ENV_FILE" -ForegroundColor Yellow
    }
    
    # If still not found, prompt user
    if (-not $apiKeyValue) {
        Write-Host ""
        Write-Host "Enter your NVD API key:" -ForegroundColor Cyan
        Write-Host "  (Get a free key at: https://nvd.nist.gov/developers/request-an-api-key)" -ForegroundColor Gray
        $apiKeyValue = Read-Host "NVD_API_KEY"
        
        if ([string]::IsNullOrWhiteSpace($apiKeyValue)) {
            Write-Host "Error: API key cannot be empty" -ForegroundColor Red
            exit 1
        }
    }
}

# Show preview of key (first 8 characters)
$keyPreview = $apiKeyValue.Substring(0, [Math]::Min(8, $apiKeyValue.Length))
Write-Host ""
Write-Host "API Key preview: $keyPreview..." -ForegroundColor Cyan
Write-Host "Full key length: $($apiKeyValue.Length) characters" -ForegroundColor Gray
Write-Host ""

# Confirm before setting
$confirmation = Read-Host "Set NVD_API_KEY as $scope environment variable? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Installation cancelled." -ForegroundColor Yellow
    exit 0
}

# Set the environment variable
try {
    Write-Host "Setting NVD_API_KEY..." -ForegroundColor Cyan
    
    if ($System) {
        # System-level (requires admin)
        [System.Environment]::SetEnvironmentVariable("NVD_API_KEY", $apiKeyValue, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "✓ Set as System environment variable" -ForegroundColor Green
        Write-Host "  Note: You may need to restart your terminal/IDE for changes to take effect" -ForegroundColor Yellow
    } else {
        # User-level (no admin required)
        [System.Environment]::SetEnvironmentVariable("NVD_API_KEY", $apiKeyValue, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ Set as User environment variable" -ForegroundColor Green
        Write-Host "  Note: You may need to restart your terminal/IDE for changes to take effect" -ForegroundColor Yellow
    }
    
    # Also set in current session so it's immediately available
    $env:NVD_API_KEY = $apiKeyValue
    Write-Host "✓ Set in current PowerShell session" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Verifying installation..." -ForegroundColor Cyan
    
    # Verify it was set correctly
    $verifyKey = [System.Environment]::GetEnvironmentVariable("NVD_API_KEY", $(if ($System) { "Machine" } else { "User" }))
    if ($verifyKey -eq $apiKeyValue) {
        Write-Host "✓ Verification successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "NVD_API_KEY is now available to all processes." -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Restart your terminal/IDE to ensure all processes see the variable" -ForegroundColor White
        Write-Host "  2. Run: mvn dependency-check:check (no need to load .env file)" -ForegroundColor White
        Write-Host "  3. The API key will speed up CVE scanning" -ForegroundColor White
    } else {
        Write-Host "⚠ Verification failed - key may not be set correctly" -ForegroundColor Yellow
        Write-Host "  Try restarting your terminal and running this script again" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ Error setting environment variable: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    if ($System) {
        Write-Host "  - Make sure you're running as Administrator" -ForegroundColor Yellow
    } else {
        Write-Host "  - Try running as Administrator with -System flag" -ForegroundColor Yellow
    }
    Write-Host "  - Or manually set it via System Properties > Environment Variables" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

