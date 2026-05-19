<#
.SYNOPSIS
    Unregisters the QuestOps Watchdog scheduled task.

.PARAMETER TaskName
    Name of the scheduled task to remove (default: "QuestOps Watchdog").
#>

param(
    [string]$TaskName = "QuestOps Watchdog"
)

# ---------------------------------------------------------------------------
# Check if the scheduled task exists
# ---------------------------------------------------------------------------
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $task) {
    Write-Host "Scheduled task '$TaskName' does not exist. Nothing to uninstall." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Unregister the task
# ---------------------------------------------------------------------------
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    Write-Host "SUCCESS: Scheduled task '$TaskName' has been unregistered." -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "ERROR: Could not unregister scheduled task '$TaskName'." -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    Write-Host "`nTip: Some systems require running PowerShell as Administrator to remove scheduled tasks." -ForegroundColor Yellow
    exit 1
}
