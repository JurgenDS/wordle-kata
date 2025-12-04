#
# Import OWASP Dependency-Check database cache (Windows)
# This extracts the pre-cached database to speed up first-time builds
#

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Get script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$DataDir = Join-Path $ProjectRoot "data\owasp-cache"
$ArchiveFile = Join-Path $DataDir "dependency-check-data.zip"

# Target location - uses USERPROFILE to work on any Windows machine
$TargetDir = Join-Path $env:USERPROFILE ".m2\repository\org\owasp"

Write-Host ""
Write-Host "+-----------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|  OWASP Dependency-Check Cache Import                      |" -ForegroundColor Cyan
Write-Host "+-----------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# Check if archive exists
if (-not (Test-Path $ArchiveFile)) {
    Write-Host "ERROR: Cache archive not found at:" -ForegroundColor Red
    Write-Host "  $ArchiveFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Make sure you have pulled the latest changes from the repository."
    exit 1
}

# Show archive info
$ArchiveSize = (Get-Item $ArchiveFile).Length / 1MB
Write-Host "Archive: $ArchiveFile"
Write-Host ("Size: {0:N1} MB" -f $ArchiveSize)
Write-Host "Target: $TargetDir\dependency-check-data\"
Write-Host ""

# Check if target already exists
$TargetDataDir = Join-Path $TargetDir "dependency-check-data"
if (Test-Path $TargetDataDir) {
    if (-not $Force) {
        Write-Host "Existing database found at: $TargetDataDir" -ForegroundColor Yellow
        $response = Read-Host "Do you want to replace it? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Import cancelled."
            exit 0
        }
    }

    Write-Host "Removing existing database..."
    Remove-Item -Path $TargetDataDir -Recurse -Force
}

# Create target directory
if (-not (Test-Path $TargetDir)) {
    Write-Host "Creating target directory..."
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# Extract archive
Write-Host "Extracting database..."
try {
    # Use .NET for extraction (works on all Windows versions)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ArchiveFile, $TargetDir)
} catch {
    # Fallback to Expand-Archive (PowerShell 5.0+)
    Write-Host "Trying alternative extraction method..."
    Expand-Archive -Path $ArchiveFile -DestinationPath $TargetDir -Force
}

# Verify extraction
if (Test-Path $TargetDataDir) {
    $TargetSize = (Get-ChildItem -Path $TargetDataDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host ""
    Write-Host "Import complete!" -ForegroundColor Green
    Write-Host ("  Location: {0}" -f $TargetDataDir)
    Write-Host ("  Size: {0:N1} MB" -f $TargetSize)
    Write-Host ""
    Write-Host "OWASP Dependency-Check will now use this cached database."
    Write-Host "First Maven build with dependency-check will be much faster!"
} else {
    Write-Host ""
    Write-Host "ERROR: Extraction failed. Database directory not found." -ForegroundColor Red
    exit 1
}
