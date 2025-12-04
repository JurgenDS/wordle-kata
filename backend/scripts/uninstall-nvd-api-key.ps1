# PowerShell script to remove NVD_API_KEY from Windows environment variables
# Usage: .\scripts\uninstall-nvd-api-key.ps1
#        .\scripts\uninstall-nvd-api-key.ps1 -System (if set as system variable)

param(
    [switch]$System  # Remove from system variables (requires Administrator)
)

# Check if running as Administrator (needed for -System)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($System -and -not $isAdmin) {
    Write-Host "Error: Removing system environment variable requires Administrator privileges." -ForegroundColor Red
    exit 1
}

Write-Host "Removing NVD_API_KEY from Windows environment variables..." -ForegroundColor Cyan
Write-Host ""

# Check if variable exists
$scope = if ($System) { "Machine" } else { "User" }
$existingKey = [System.Environment]::GetEnvironmentVariable("NVD_API_KEY", $scope)

if (-not $existingKey) {
    # Check the other scope
    $otherScope = if ($System) { "User" } else { "Machine" }
    $existingKeyOther = [System.Environment]::GetEnvironmentVariable("NVD_API_KEY", $otherScope)
    
    if ($existingKeyOther) {
        Write-Host "NVD_API_KEY found in $otherScope scope, not $scope scope." -ForegroundColor Yellow
        Write-Host "Run with -System flag to remove from system variables, or without to remove from user variables." -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "NVD_API_KEY not found in environment variables." -ForegroundColor Yellow
        exit 0
    }
}

# Show preview
$keyPreview = $existingKey.Substring(0, [Math]::Min(8, $existingKey.Length))
Write-Host "Found NVD_API_KEY: $keyPreview..." -ForegroundColor Cyan
Write-Host "Scope: $scope" -ForegroundColor Cyan
Write-Host ""

# Confirm before removing
$confirmation = Read-Host "Remove NVD_API_KEY from $scope environment variables? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Removal cancelled." -ForegroundColor Yellow
    exit 0
}

# Remove the environment variable
try {
    Write-Host "Removing NVD_API_KEY..." -ForegroundColor Cyan
    [System.Environment]::SetEnvironmentVariable("NVD_API_KEY", $null, $scope)
    Write-Host "✓ Removed from $scope environment variables" -ForegroundColor Green
    
    # Also remove from current session
    Remove-Item Env:\NVD_API_KEY -ErrorAction SilentlyContinue
    Write-Host "✓ Removed from current PowerShell session" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "NVD_API_KEY has been removed." -ForegroundColor Green
    Write-Host "Note: You may need to restart your terminal/IDE for changes to take effect." -ForegroundColor Yellow
    
} catch {
    Write-Host "✗ Error removing environment variable: $_" -ForegroundColor Red
    Write-Host "  Try running as Administrator if removing from system variables" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

