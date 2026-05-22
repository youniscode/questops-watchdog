<#
.SYNOPSIS
    Builds a standalone EXE for the QuestOps Watchdog GUI Setup Wizard.
    Requires the PS2EXE module to be installed manually.

.DESCRIPTION
    This script checks for scripts\setup_client_gui.ps1 and the Invoke-PS2EXE command.
    If found, it compiles the script into dist\exe\QuestOpsWatchdogSetup.exe.
#>

$ErrorActionPreference = "Stop"

$scriptPath = "scripts\setup_client_gui.ps1"
$outputDir = "dist\exe"
$outputExe = Join-Path $outputDir "QuestOpsWatchdogSetup.exe"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "      QuestOps Watchdog - EXE Build Script" -ForegroundColor Cyan
Write-Host "============================================================`n"

# 1. Check for source script
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Source script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

# 2. Check for Invoke-PS2EXE
if (-not (Get-Command "Invoke-PS2EXE" -ErrorAction SilentlyContinue)) {
    Write-Host "PS2EXE is not installed. Install it manually if you want EXE packaging." -ForegroundColor Yellow
    Write-Host "To install, run this command in an Administrator PowerShell window:"
    Write-Host "`n  Install-Module ps2exe -Scope CurrentUser`n" -ForegroundColor Green
    exit 1
}

# 3. Create output directory
if (-not (Test-Path $outputDir)) {
    Write-Host "Creating directory: $outputDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 4. Compile
Write-Host "Compiling $scriptPath to $outputExe..." -ForegroundColor Cyan

try {
    Invoke-PS2EXE -InputFile $scriptPath -OutputFile $outputExe -NoConsole -IconFile "docs\assets\screenshots\logo.ico" -Title "QuestOps Watchdog Setup Wizard" -Description "Interactive setup wizard for QuestOps Watchdog monitoring." -Company "QuestOps" -Product "QuestOps Watchdog" -FileVersion "0.1.28" -ErrorAction Stop
    
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "      BUILD SUCCESSFUL" -ForegroundColor Green
    Write-Host "============================================================"
    Write-Host "EXE Location: $outputExe"
    Write-Host "Note: Always test the EXE and check for antivirus false positives before delivery."
    Write-Host "============================================================`n"
}
catch {
    Write-Host "`nERROR: Build failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
