<#
.SYNOPSIS
    Packages QuestOps Watchdog into a clean release ZIP.

.PARAMETER Version
    Release version label (default: "dev").

.PARAMETER OutputDir
    Directory where the release folder and ZIP are created (default: ".\dist").
#>

param(
    [string]$Version   = "dev",
    [string]$OutputDir = ".\dist"
)

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$scriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot  = Split-Path -Parent $scriptRoot

# If -Version was not explicitly provided, try reading from VERSION file
if (-not $PSBoundParameters.ContainsKey('Version')) {
    $versionFilePath = Join-Path -Path $projectRoot -ChildPath "VERSION"
    if (Test-Path -LiteralPath $versionFilePath -PathType Leaf) {
        $Version = (Get-Content -LiteralPath $versionFilePath -Raw).Trim()
    }
}

# Strip leading "v" to avoid double v in folder/filename
$cleanVersion = $Version -replace '^v', ''

if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path -Path $projectRoot -ChildPath $OutputDir
}
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)

$releaseName = "questops-watchdog-v$cleanVersion"
$releaseDir  = Join-Path -Path $OutputDir -ChildPath $releaseName
$zipPath     = Join-Path -Path $OutputDir -ChildPath ("$releaseName.zip")

Write-Host "Packaging QuestOps Watchdog v$cleanVersion..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Ensure output directory exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Remove previous release folder and ZIP for clean build
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $releaseDir) {
    Remove-Item -LiteralPath $releaseDir -Recurse -Force
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

# ---------------------------------------------------------------------------
# Create release folder
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

# ---------------------------------------------------------------------------
# Copy product directories
# ---------------------------------------------------------------------------
$dirs = @("config", "scripts", "lib", "docs")

foreach ($d in $dirs) {
    $src = Join-Path -Path $projectRoot -ChildPath $d
    $dst = Join-Path -Path $releaseDir -ChildPath $d

    if (Test-Path -LiteralPath $src) {
        Copy-Item -Path $src -Destination $dst -Recurse
    }
    else {
        Write-Host ("  WARN: Source directory not found: $d") -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Copy root-level files
# ---------------------------------------------------------------------------
$files = @("README.md", "CHANGELOG.md", "VERSION", "PROJECTMAP.md", "AI_WORKSPACE_RULES.md")

foreach ($f in $files) {
    $src = Join-Path -Path $projectRoot -ChildPath $f

    if (Test-Path -LiteralPath $src -PathType Leaf) {
        Copy-Item -Path $src -Destination $releaseDir
    }
    else {
        Write-Host ("  WARN: Source file not found: $f") -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Remove excluded file types from release
# ---------------------------------------------------------------------------
Get-ChildItem -Path $releaseDir -Recurse -Include "*.log" | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $releaseDir -Recurse -Filter "__*.json" | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $releaseDir -Recurse -Filter "servers.local.*.json" | Where-Object { $_.Name -ne 'servers.local.test.json' } | Remove-Item -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# Count files in release
# ---------------------------------------------------------------------------
$fileCount = (Get-ChildItem -Path $releaseDir -Recurse -File).Count

# ---------------------------------------------------------------------------
# Create ZIP
# ---------------------------------------------------------------------------
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    [System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDir, $zipPath)
}
catch {
    Write-Host "ERROR: Failed to create ZIP file." -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Print release summary
# ---------------------------------------------------------------------------
Write-Host ("`nSUCCESS: Release v$cleanVersion packaged.") -ForegroundColor Green
Write-Host "  Version:     v$cleanVersion" -ForegroundColor Cyan
Write-Host "  Release dir: $releaseDir" -ForegroundColor Cyan
Write-Host "  ZIP:         $zipPath" -ForegroundColor Cyan
Write-Host "  Files:       $fileCount" -ForegroundColor Cyan
exit 0
