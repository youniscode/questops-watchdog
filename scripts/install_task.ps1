<#
.SYNOPSIS
    Creates or updates a Windows Scheduled Task that runs QuestOps Watchdog
    on a repeating interval.

.PARAMETER ConfigPath
    Path to the server configuration JSON.

.PARAMETER TaskName
    Name of the scheduled task (default: "QuestOps Watchdog").

.PARAMETER IntervalMinutes
    Minutes between each run (default: 5).

.PARAMETER ValidateConfig
    If set, validates the config file with validate_config.ps1 before
    registering the task. The task action will also include -ValidateConfig
    so every scheduled run validates before executing checks.
#>

param(
    [string]$ConfigPath,
    [string]$TaskName = "QuestOps Watchdog",
    [int]$IntervalMinutes = 5,
    [switch]$ValidateConfig
)

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$scriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot  = Split-Path -Parent $scriptRoot
$runnerPath   = Join-Path -Path $scriptRoot -ChildPath "questops_watchdog.ps1"
$resolvedConfigPath = $ConfigPath

if (-not [System.IO.Path]::IsPathRooted($resolvedConfigPath)) {
    $resolvedConfigPath = Join-Path -Path $projectRoot -ChildPath $resolvedConfigPath
}

# ---------------------------------------------------------------------------
# Validate files exist
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    Write-Host "ERROR: Runner script not found: $runnerPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $resolvedConfigPath -PathType Leaf)) {
    Write-Host "ERROR: Config file not found: $resolvedConfigPath" -ForegroundColor Red
    Write-Host "Please provide a valid -ConfigPath to an existing JSON config file." -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
# Optional config validation before install
# ---------------------------------------------------------------------------
if ($ValidateConfig) {
    $validatorPath = Join-Path -Path $scriptRoot -ChildPath "validate_config.ps1"

    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
        Write-Host "ERROR: Validator script not found: $validatorPath" -ForegroundColor Red
        exit 1
    }

    Write-Host "Validating config before install..." -ForegroundColor Cyan
    & $validatorPath -ConfigPath $resolvedConfigPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Config validation failed. Installation aborted." -ForegroundColor Red
        exit 1
    }
    Write-Host "Config validation passed.`n" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Build scheduled task action
# ---------------------------------------------------------------------------
$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -ConfigPath `"$resolvedConfigPath`""

if ($ValidateConfig) {
    $argument = $argument + " -ValidateConfig"
}

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument -WorkingDirectory $projectRoot
}
catch {
    Write-Host "ERROR: Could not create scheduled task action. The ScheduledTasks module may not be available." -ForegroundColor Red
    Write-Host "This script requires Windows 8 / Server 2012 or later." -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
# Build trigger: repeat every IntervalMinutes indefinitely
# ---------------------------------------------------------------------------
try {
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
        -RepetitionDuration (New-TimeSpan -Days 3650)
}
catch {
    Write-Host "ERROR: Could not create scheduled task trigger." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Build principal: run as current user, only when logged on, no admin needed
# ---------------------------------------------------------------------------
try {
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
}
catch {
    Write-Host "ERROR: Could not create scheduled task principal." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Settings: allow task to run on battery, start if missed
# ---------------------------------------------------------------------------
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# ---------------------------------------------------------------------------
# Register (create or update) the task
# ---------------------------------------------------------------------------
try {
    Register-ScheduledTask -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force `
        -ErrorAction Stop

    $validationLabel = if ($ValidateConfig) { 'Yes' } else { 'No' }

    Write-Host "SUCCESS: Scheduled task '$TaskName' created." -ForegroundColor Green
    Write-Host "  Task name:   $TaskName" -ForegroundColor Cyan
    Write-Host "  Interval:    Every $IntervalMinutes minute(s)" -ForegroundColor Cyan
    Write-Host "  Config path: $resolvedConfigPath" -ForegroundColor Cyan
    Write-Host "  Validation:  $validationLabel" -ForegroundColor Cyan
    Write-Host "  Runner:      $runnerPath" -ForegroundColor Cyan
    Write-Host "  User:        $env:USERNAME (interactive only)" -ForegroundColor Cyan
    Write-Host "`nThe task is registered but NOT started automatically." -ForegroundColor Yellow
    Write-Host "To start it now, open Task Scheduler or run:" -ForegroundColor Yellow
    Write-Host "  Start-ScheduledTask -TaskName `"$TaskName`"" -ForegroundColor Yellow
    exit 0
}
catch {
    Write-Host "ERROR: Could not register scheduled task." -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    Write-Host "`nTip: Some systems require running PowerShell as Administrator to create scheduled tasks." -ForegroundColor Yellow
    exit 1
}
