<#
.SYNOPSIS
    QuestOps Watchdog — local game server monitoring agent.
    Reads a JSON config, runs health checks, and sends Discord alerts.

.PARAMETER ConfigPath
    Path to server configuration JSON (default: config/servers.example.json).
#>

param(
    [string]$ConfigPath = "config\servers.example.json",
    [switch]$ValidateConfig
)

# ---------------------------------------------------------------------------
# Resolve paths relative to the project root (parent of scripts/)
# ---------------------------------------------------------------------------
$scriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot  = Split-Path -Parent $scriptRoot

# ---------------------------------------------------------------------------
# Dot-source libraries
# ---------------------------------------------------------------------------
. (Join-Path -Path $projectRoot -ChildPath "lib\discord.ps1")
. (Join-Path -Path $projectRoot -ChildPath "lib\checks.ps1")
. (Join-Path -Path $projectRoot -ChildPath "lib\state.ps1")

# ---------------------------------------------------------------------------
# Resolve config path
# ---------------------------------------------------------------------------
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    Write-Host "ERROR: Config file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Optional config validation
# ---------------------------------------------------------------------------
if ($ValidateConfig) {
    $validatorPath = Join-Path -Path $scriptRoot -ChildPath "validate_config.ps1"
    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
        Write-Host "ERROR: Validator script not found: $validatorPath" -ForegroundColor Red
        exit 1
    }
    Write-Host "Validating config before run..." -ForegroundColor Cyan
    & $validatorPath -ConfigPath $ConfigPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Config validation failed. Aborting." -ForegroundColor Red
        exit 1
    }
    Write-Host "Config validation passed. Proceeding with checks.`n" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Read configuration
# ---------------------------------------------------------------------------
try {
    $config = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: Could not read config file: $ConfigPath" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Global defaults
# ---------------------------------------------------------------------------
$stateRoot            = $config.global.stateDir
$logDir               = $config.global.logDir
$globalWebhookEnvVar  = $config.discord.webhookUrlEnvVar
$globalDefaultCooldown = if ($config.discord.defaultCooldownMinutes) { $config.discord.defaultCooldownMinutes } else { 15 }

# Resolve relative state/log directories against the project root
if (-not [System.IO.Path]::IsPathRooted($stateRoot)) {
    $stateRoot = Join-Path -Path $projectRoot -ChildPath $stateRoot
}
if (-not [System.IO.Path]::IsPathRooted($logDir)) {
    $logDir = Join-Path -Path $projectRoot -ChildPath $logDir
}

# Ensure log directory exists
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Daily log file path
$runLogPath = Join-Path -Path $logDir -ChildPath ("questops-watchdog-" + (Get-Date -Format "yyyy-MM-dd") + ".log")

# Small logging helper
function Write-QORunLog {
    param(
        [string]$Path,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Path -Value "$timestamp $Message"
}

# ---------------------------------------------------------------------------
# Run summary counters
# ---------------------------------------------------------------------------
$totalServers     = 0
$totalChecks      = 0
$totalAlerts      = 0
$totalSuppressed  = 0
$totalRecoveries  = 0
$serverResults    = @()
$runTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "QuestOps Watchdog v0.1" -ForegroundColor Cyan
Write-Host "Run: $runTimestamp" -ForegroundColor Cyan
Write-Host "Config: $ConfigPath" -ForegroundColor Cyan
Write-Host ("=" * 60)
Write-QORunLog -Path $runLogPath -Message 'QuestOps Watchdog v0.1 - Run started'
Write-QORunLog -Path $runLogPath -Message ('Config: ' + $ConfigPath)
Write-QORunLog -Path $runLogPath -Message ('= ' * 25)

# ---------------------------------------------------------------------------
# Process each server
# ---------------------------------------------------------------------------
foreach ($server in $config.servers) {

    # Skip disabled servers
    if (-not $server.enabled) {
        $serverResults += @{
            Name = $server.name; Status = "skipped"; Issues = 0
            Alerts = 0; Suppressed = 0; Recoveries = 0
        }
        Write-Host ("[SKIP]  $($server.name)") -ForegroundColor DarkGray
        Write-QORunLog -Path $runLogPath -Message ('SKIP   ' + $server.name)
        continue
    }

    $totalServers++
    Write-Host ("`n[SERVER] $($server.name)") -ForegroundColor Yellow
    Write-QORunLog -Path $runLogPath -Message ('SERVER ' + $server.name)

    # Generate a filesystem-safe server key from the server name
    $serverKey = ($server.name.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $serverKey) { $serverKey = "server-$totalServers" }

    # Load per-server state
    $statePath = Get-QOStateFilePath -StateRoot $stateRoot -ServerKey $serverKey
    $state     = Read-QOState -StatePath $statePath
    $stateChanged = $false

    # Resolve webhook URL from environment variable (never hardcoded)
    $envVarName = if ($server.discord.webhookUrlEnvVar) { $server.discord.webhookUrlEnvVar } else { $globalWebhookEnvVar }
    $webhookUrl = [Environment]::GetEnvironmentVariable($envVarName)

    # Resolve cooldown (per-server or global default)
    $cooldownMinutes = if ($server.discord.cooldownMinutes) { $server.discord.cooldownMinutes } else { $globalDefaultCooldown }

    # Per-server result tracking for summary embed
    $srvIssues = 0; $srvAlerts = 0; $srvSuppressed = 0; $srvRecoveries = 0

    # -----------------------------------------------------------------------
    # Maintenance mode detection
    # -----------------------------------------------------------------------
    $maintenanceSuppress = $false
    if ($server.maintenance -and $server.maintenance.enabled) {
        $flagPath = $server.maintenance.flagPath
        if (-not [System.IO.Path]::IsPathRooted($flagPath)) {
            $flagPath = Join-Path -Path $projectRoot -ChildPath $flagPath
        }
        if (Test-Path -LiteralPath $flagPath -PathType Leaf) {
            $maintenanceSuppress = if ($server.maintenance.suppressAlerts) { $true } else { $false }
            $mmLabel = if ($maintenanceSuppress) { 'suppressed' } else { 'not suppressed' }
            Write-Host "  MAINTENANCE : active (alerts $mmLabel)" -ForegroundColor Magenta
            Write-QORunLog -Path $runLogPath -Message ('  MAINTENANCE : active (alerts ' + $mmLabel + ')')
        }
    }

    # -----------------------------------------------------------------------
    # Process check
    # -----------------------------------------------------------------------
    if ($server.process.enabled) {
        $totalChecks++
        $procName = $server.process.name -replace '\.exe$', ''
        $result   = Test-QOProcessRunning -ProcessName $procName

        if (-not $result.Running) {
            $state = Set-QOAlertActive -State $state -AlertKey "process_stopped"
            $stateChanged = $true
            $srvIssues++
            if ($maintenanceSuppress) {
                $totalSuppressed++; $srvSuppressed++
                Write-QORunLog -Path $runLogPath -Message '  ALERT suppressed: process_stopped (maintenance mode)'
            }
            else {
                $cooldown = Test-QOAlertCooldown -State $state -AlertKey "process_stopped" -CooldownMinutes $cooldownMinutes
                if ($cooldown.CanSend -and $webhookUrl) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Process Stopped" `
                        -Description "Server process '$($server.process.name)' is not running." `
                        -Severity critical `
                        -ServerName $server.name
                    if ($sent) {
                        $state = Set-QOAlertSent -State $state -AlertKey "process_stopped"
                        $stateChanged = $true
                        $totalAlerts++; $srvAlerts++
                        Write-QORunLog -Path $runLogPath -Message ('  ALERT sent: process_stopped for ' + $server.process.name)
                    }
                }
                else {
                    $suppressReason = if (-not $cooldown.CanSend) { $cooldown.Message } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  ALERT suppressed: process_stopped (' + $suppressReason + ')')
                }
            }
            Write-Host ("  PROCESS : STOPPED") -ForegroundColor Red
            Write-QORunLog -Path $runLogPath -Message '  PROCESS : STOPPED'
        }
        else {
            if (Test-QOAlertActive -State $state -AlertKey "process_stopped") {
                if ($webhookUrl -and -not $maintenanceSuppress) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Process Recovered" `
                        -Description "Server process '$($server.process.name)' is running again." `
                        -Severity success `
                        -ServerName $server.name
                    if ($sent) {
                        $totalRecoveries++; $srvRecoveries++
                        Write-QORunLog -Path $runLogPath -Message ('  RECOVERY sent: process_stopped for ' + $server.process.name)
                    }
                }
                else {
                    $recoverySuppress = if ($maintenanceSuppress) { 'maintenance mode' } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  RECOVERY suppressed: process_stopped (' + $recoverySuppress + ')')
                }
                $state = Clear-QOAlertActive -State $state -AlertKey "process_stopped"
                $stateChanged = $true
            }
            Write-Host ("  PROCESS : Running") -ForegroundColor Green
            Write-QORunLog -Path $runLogPath -Message '  PROCESS : Running'
        }
    }

    # -----------------------------------------------------------------------
    # Log freshness check
    # -----------------------------------------------------------------------
    if ($server.logFile.enabled) {
        $totalChecks++
        $result = Test-QOLogFreshness -Path $server.logFile.path -MaxAgeMinutes $server.logFile.maxAgeMinutes

        if (-not $result.Fresh) {
            $state = Set-QOAlertActive -State $state -AlertKey "log_stale"
            $stateChanged = $true
            $srvIssues++
            if ($maintenanceSuppress) {
                $totalSuppressed++; $srvSuppressed++
                Write-QORunLog -Path $runLogPath -Message '  ALERT suppressed: log_stale (maintenance mode)'
            }
            else {
                $cooldown = Test-QOAlertCooldown -State $state -AlertKey "log_stale" -CooldownMinutes $cooldownMinutes
                if ($cooldown.CanSend -and $webhookUrl) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Log Stale" `
                        -Description "Server log has not updated in $($result.AgeMinutes) minutes (limit $($server.logFile.maxAgeMinutes) min)." `
                        -Severity warning `
                        -ServerName $server.name
                    if ($sent) {
                        $state = Set-QOAlertSent -State $state -AlertKey "log_stale"
                        $stateChanged = $true
                        $totalAlerts++; $srvAlerts++
                        Write-QORunLog -Path $runLogPath -Message ('  ALERT sent: log_stale (age ' + $result.AgeMinutes + ' min)')
                    }
                }
                else {
                    $suppressReason = if (-not $cooldown.CanSend) { $cooldown.Message } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  ALERT suppressed: log_stale (' + $suppressReason + ')')
                }
            }
            Write-Host ("  LOG     : STALE ($($result.AgeMinutes) min)") -ForegroundColor Red
            Write-QORunLog -Path $runLogPath -Message ('  LOG     : STALE (age ' + $result.AgeMinutes + ' min)')
        }
        else {
            if (Test-QOAlertActive -State $state -AlertKey "log_stale") {
                if ($webhookUrl -and -not $maintenanceSuppress) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Log Freshness Recovered" `
                        -Description "Server log is updating again (last write $($result.AgeMinutes) min ago)." `
                        -Severity success `
                        -ServerName $server.name
                    if ($sent) {
                        $totalRecoveries++; $srvRecoveries++
                        Write-QORunLog -Path $runLogPath -Message '  RECOVERY sent: log_stale'
                    }
                }
                else {
                    $recoverySuppress = if ($maintenanceSuppress) { 'maintenance mode' } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  RECOVERY suppressed: log_stale (' + $recoverySuppress + ')')
                }
                $state = Clear-QOAlertActive -State $state -AlertKey "log_stale"
                $stateChanged = $true
            }
            Write-Host ("  LOG     : Fresh") -ForegroundColor Green
            Write-QORunLog -Path $runLogPath -Message '  LOG     : Fresh'
        }
    }

    # -----------------------------------------------------------------------
    # Backup freshness check
    # -----------------------------------------------------------------------
    if ($server.backup.enabled) {
        $totalChecks++
        $result = Test-QOBackupFreshness -Path $server.backup.path -MaxAgeHours $server.backup.maxAgeHours

        if (-not $result.Fresh) {
            $state = Set-QOAlertActive -State $state -AlertKey "backup_stale"
            $stateChanged = $true
            $srvIssues++
            if ($maintenanceSuppress) {
                $totalSuppressed++; $srvSuppressed++
                Write-QORunLog -Path $runLogPath -Message '  ALERT suppressed: backup_stale (maintenance mode)'
            }
            else {
                $cooldown = Test-QOAlertCooldown -State $state -AlertKey "backup_stale" -CooldownMinutes $cooldownMinutes
                if ($cooldown.CanSend -and $webhookUrl) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Backup Stale" `
                        -Description "Server backup has not updated in $($result.AgeHours) hours (limit $($server.backup.maxAgeHours) hr)." `
                        -Severity warning `
                        -ServerName $server.name
                    if ($sent) {
                        $state = Set-QOAlertSent -State $state -AlertKey "backup_stale"
                        $stateChanged = $true
                        $totalAlerts++; $srvAlerts++
                        Write-QORunLog -Path $runLogPath -Message ('  ALERT sent: backup_stale (age ' + $result.AgeHours + ' hr)')
                    }
                }
                else {
                    $suppressReason = if (-not $cooldown.CanSend) { $cooldown.Message } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  ALERT suppressed: backup_stale (' + $suppressReason + ')')
                }
            }
            Write-Host ("  BACKUP  : STALE ($($result.AgeHours) hr)") -ForegroundColor Red
            Write-QORunLog -Path $runLogPath -Message ('  BACKUP  : STALE (age ' + $result.AgeHours + ' hr)')
        }
        else {
            if (Test-QOAlertActive -State $state -AlertKey "backup_stale") {
                if ($webhookUrl -and -not $maintenanceSuppress) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Backup Freshness Recovered" `
                        -Description "Server backup is updating again (last write $($result.AgeHours) hr ago)." `
                        -Severity success `
                        -ServerName $server.name
                    if ($sent) {
                        $totalRecoveries++; $srvRecoveries++
                        Write-QORunLog -Path $runLogPath -Message '  RECOVERY sent: backup_stale'
                    }
                }
                else {
                    $recoverySuppress = if ($maintenanceSuppress) { 'maintenance mode' } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  RECOVERY suppressed: backup_stale (' + $recoverySuppress + ')')
                }
                $state = Clear-QOAlertActive -State $state -AlertKey "backup_stale"
                $stateChanged = $true
            }
            Write-Host ("  BACKUP  : Fresh") -ForegroundColor Green
            Write-QORunLog -Path $runLogPath -Message '  BACKUP  : Fresh'
        }
    }

    # -----------------------------------------------------------------------
    # Disk space check
    # -----------------------------------------------------------------------
    if ($server.disk.enabled) {
        $totalChecks++
        $driveLetter = $server.disk.path -replace '[:\\/].*$', ''
        $result = Test-QODiskSpace -DriveLetter $driveLetter -MinimumFreeGB $server.disk.minFreeGB

        if (-not $result.Healthy) {
            $state = Set-QOAlertActive -State $state -AlertKey "disk_low"
            $stateChanged = $true
            $srvIssues++
            if ($maintenanceSuppress) {
                $totalSuppressed++; $srvSuppressed++
                Write-QORunLog -Path $runLogPath -Message '  ALERT suppressed: disk_low (maintenance mode)'
            }
            else {
                $cooldown = Test-QOAlertCooldown -State $state -AlertKey "disk_low" -CooldownMinutes $cooldownMinutes
                if ($cooldown.CanSend -and $webhookUrl) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Disk Space Low" `
                        -Description "Drive $driveLetter has $($result.FreeGB) GB free (minimum $($server.disk.minFreeGB) GB)." `
                        -Severity warning `
                        -ServerName $server.name
                    if ($sent) {
                        $state = Set-QOAlertSent -State $state -AlertKey "disk_low"
                        $stateChanged = $true
                        $totalAlerts++; $srvAlerts++
                        Write-QORunLog -Path $runLogPath -Message ('  ALERT sent: disk_low (free ' + $result.FreeGB + ' GB)')
                    }
                }
                else {
                    $suppressReason = if (-not $cooldown.CanSend) { $cooldown.Message } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  ALERT suppressed: disk_low (' + $suppressReason + ')')
                }
            }
            Write-Host ("  DISK    : LOW ($($result.FreeGB) GB free)") -ForegroundColor Red
            Write-QORunLog -Path $runLogPath -Message ('  DISK    : LOW (free ' + $result.FreeGB + ' GB)')
        }
        else {
            if (Test-QOAlertActive -State $state -AlertKey "disk_low") {
                if ($webhookUrl -and -not $maintenanceSuppress) {
                    $sent = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
                        -Title "Disk Space Recovered" `
                        -Description "Drive $driveLetter has $($result.FreeGB) GB free (above $($server.disk.minFreeGB) GB threshold)." `
                        -Severity success `
                        -ServerName $server.name
                    if ($sent) {
                        $totalRecoveries++; $srvRecoveries++
                        Write-QORunLog -Path $runLogPath -Message '  RECOVERY sent: disk_low'
                    }
                }
                else {
                    $recoverySuppress = if ($maintenanceSuppress) { 'maintenance mode' } else { 'no webhook URL configured' }
                    Write-QORunLog -Path $runLogPath -Message ('  RECOVERY suppressed: disk_low (' + $recoverySuppress + ')')
                }
                $state = Clear-QOAlertActive -State $state -AlertKey "disk_low"
                $stateChanged = $true
            }
            Write-Host ("  DISK    : OK ($($result.FreeGB) GB free)") -ForegroundColor Green
            Write-QORunLog -Path $runLogPath -Message ('  DISK    : OK (free ' + $result.FreeGB + ' GB)')
        }
    }

    # Persist state if changed
    if ($stateChanged) {
        Write-QOState -StatePath $statePath -State $state | Out-Null
    }

    # Record per-server result for summary embed
    $srvStatus = if ($maintenanceSuppress) { 'maintenance' } elseif ($srvIssues -gt 0) { 'issue' } else { 'healthy' }
    $serverResults += @{
        Name = $server.name; Status = $srvStatus; Issues = $srvIssues
        Alerts = $srvAlerts; Suppressed = $srvSuppressed; Recoveries = $srvRecoveries
    }
}

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
Write-Host ("`n" + ("=" * 60))
Write-Host "Summary: $totalServers server(s), $totalChecks check(s), $totalAlerts alert(s) sent, $totalSuppressed suppressed, $totalRecoveries recovery alert(s)." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Optional Discord summary embed
# ---------------------------------------------------------------------------
if ($config.summary -and $config.summary.enabled) {
    $summaryCooldownMinutes = if ($config.summary.cooldownMinutes) { $config.summary.cooldownMinutes } else { 30 }
    $sendOnlyOnIssues = if ($config.summary.sendOnlyOnIssues) { $true } else { $false }
    $includeHealthy = if ($config.summary.includeHealthyServers) { $true } else { $false }

    $totalIssueServers = ($serverResults | Where-Object { $_.Status -eq 'issue' } | Measure-Object).Count
    $hasIssues = $totalIssueServers -gt 0
    $hasRecoveries = $totalRecoveries -gt 0
    $hasSuppressed = $totalSuppressed -gt 0

    $shouldSend = (-not $sendOnlyOnIssues) -or $hasIssues -or $hasRecoveries -or $hasSuppressed

    if ($shouldSend) {
        $summaryWebhookUrl = [Environment]::GetEnvironmentVariable($globalWebhookEnvVar)

        if ($summaryWebhookUrl) {
            $summaryStateDir = Join-Path -Path $stateRoot -ChildPath "__summary__"
            $summaryStatePath = Join-Path -Path $summaryStateDir -ChildPath "state.json"
            $summaryState = Read-QOState -StatePath $summaryStatePath

            $summaryCooldown = Test-QOAlertCooldown -State $summaryState -AlertKey "summary_sent" -CooldownMinutes $summaryCooldownMinutes

            if ($summaryCooldown.CanSend) {
                # Build title
                if ($hasIssues) {
                    $summaryTitle = "QuestOps Watchdog Summary - Issues Detected"
                    $embedColor = 15548997
                }
                elseif ($hasRecoveries -or $hasSuppressed) {
                    $summaryTitle = "QuestOps Watchdog Summary - Recovery Detected"
                    $embedColor = 16763904
                }
                else {
                    $summaryTitle = "QuestOps Watchdog Summary"
                    $embedColor = 5814783
                }

                $summaryDesc = "Total Servers: $totalServers`nTotal Checks: $totalChecks`nAlerts Sent: $totalAlerts`nAlerts Suppressed: $totalSuppressed`nRecovery Alerts: $totalRecoveries`nServers with Issues: $totalIssueServers"

                # Build per-server fields
                $summaryFields = @()
                foreach ($srv in $serverResults) {
                    $includeSrv = $includeHealthy -or ($srv.Status -eq 'issue') -or ($srv.Status -eq 'maintenance') -or ($srv.Recoveries -gt 0) -or ($srv.Suppressed -gt 0)
                    if ($includeSrv) {
                        $statusMap = @{ healthy = "Healthy"; issue = "Issue (" + $srv.Issues + " failed)"; skipped = "Skipped"; maintenance = "Maintenance Mode" }
                        $fieldValue = $statusMap[$srv.Status]
                        $summaryFields += @{ name = $srv.Name; value = $fieldValue; inline = $true }
                    }
                }

                if ($summaryFields.Count -gt 0) {
                    $embed = @{
                        title       = $summaryTitle
                        description = $summaryDesc
                        color       = $embedColor
                        fields      = $summaryFields
                        timestamp   = [DateTime]::UtcNow.ToString("o")
                    }
                    $body = @{ embeds = @($embed) } | ConvertTo-Json -Depth 4

                    try {
                        Invoke-RestMethod -Uri $summaryWebhookUrl -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop | Out-Null
                        Write-QORunLog -Path $runLogPath -Message 'Summary embed sent to Discord.'
                    }
                    catch {
                        Write-QORunLog -Path $runLogPath -Message 'Summary embed failed to send.'
                    }

                    $summaryState = Set-QOAlertSent -State $summaryState -AlertKey "summary_sent"
                    Write-QOState -StatePath $summaryStatePath -State $summaryState | Out-Null
                }
            }
        }
    }
}

Write-QORunLog -Path $runLogPath -Message ('= ' * 25)
Write-QORunLog -Path $runLogPath -Message ('Summary: ' + $totalServers + ' server(s), ' + $totalChecks + ' check(s), ' + $totalAlerts + ' alert(s) sent, ' + $totalSuppressed + ' suppressed, ' + $totalRecoveries + ' recovery alert(s).')
Write-QORunLog -Path $runLogPath -Message 'QuestOps Watchdog v0.1 - Run finished'
