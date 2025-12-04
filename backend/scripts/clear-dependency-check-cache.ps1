# PowerShell script to clear OWASP Dependency-Check cache on Windows
# Usage: .\scripts\clear-dependency-check-cache.ps1

Write-Host "Clearing OWASP Dependency-Check cache..." -ForegroundColor Cyan
Write-Host ""

# Find Maven local repository location
# Default locations (in order of preference):
$mavenRepoPaths = @(
    "$env:USERPROFILE\.m2\repository",
    "$env:MAVEN_HOME\repository",
    "$env:M2_HOME\repository"
)

$mavenRepo = $null
foreach ($path in $mavenRepoPaths) {
    if ($path -and (Test-Path $path)) {
        $mavenRepo = $path
        break
    }
}

# If not found in standard locations, try to get it from Maven settings
if (-not $mavenRepo) {
    try {
        $mavenOutput = & mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout 2>&1
        if ($mavenOutput -and (Test-Path $mavenOutput)) {
            $mavenRepo = $mavenOutput
        }
    } catch {
        # Maven command failed, use default
    }
}

# Fallback to default if still not found
if (-not $mavenRepo) {
    $mavenRepo = "$env:USERPROFILE\.m2\repository"
    Write-Host "Using default Maven repository location: $mavenRepo" -ForegroundColor Yellow
} else {
    Write-Host "Found Maven repository: $mavenRepo" -ForegroundColor Green
}

# Dependency-Check cache location
$dependencyCheckCache = Join-Path $mavenRepo "org\owasp\dependency-check-data"

Write-Host ""
if (Test-Path $dependencyCheckCache) {
    Write-Host "Dependency-Check cache found at:" -ForegroundColor Cyan
    Write-Host "  $dependencyCheckCache" -ForegroundColor White
    
    # Calculate size before deletion
    $cacheSize = (Get-ChildItem -Path $dependencyCheckCache -Recurse -ErrorAction SilentlyContinue | 
                  Measure-Object -Property Length -Sum).Sum
    $cacheSizeMB = [Math]::Round($cacheSize / 1MB, 2)
    
    Write-Host ""
    Write-Host "Cache size: $cacheSizeMB MB" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask for confirmation
    $confirmation = Read-Host "Do you want to delete the cache? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        try {
            Write-Host "Deleting cache..." -ForegroundColor Cyan
            Remove-Item -Path $dependencyCheckCache -Recurse -Force -ErrorAction Stop
            Write-Host "✓ Cache cleared successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next time you run dependency-check, it will download fresh data." -ForegroundColor Cyan
            Write-Host "With NVD_API_KEY set, this should be faster." -ForegroundColor Cyan
        } catch {
            Write-Host "✗ Error deleting cache: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "You may need to:" -ForegroundColor Yellow
            Write-Host "  1. Close any running Maven/Dependency-Check processes" -ForegroundColor Yellow
            Write-Host "  2. Run PowerShell as Administrator" -ForegroundColor Yellow
            Write-Host "  3. Manually delete: $dependencyCheckCache" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Cache deletion cancelled." -ForegroundColor Yellow
    }
} else {
    Write-Host "Dependency-Check cache not found at:" -ForegroundColor Yellow
    Write-Host "  $dependencyCheckCache" -ForegroundColor White
    Write-Host ""
    Write-Host "This might mean:" -ForegroundColor Cyan
    Write-Host "  - Dependency-Check hasn't been run yet" -ForegroundColor Gray
    Write-Host "  - Cache is in a different location" -ForegroundColor Gray
    Write-Host ""
    Write-Host "You can also manually clear the cache by deleting:" -ForegroundColor Cyan
    Write-Host "  $dependencyCheckCache" -ForegroundColor White
}

Write-Host ""

