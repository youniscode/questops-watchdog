<#
.SYNOPSIS
    Interactive setup wizard for QuestOps Watchdog.
    Guides non-technical clients through server configuration and installation.

.DESCRIPTION
    This script prompts for server details, creates a generated config file,
    sets the Discord webhook environment variable, and optionally installs
     the scheduled task.
#>

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Prompt-User {
    param(
        [string]$Question,
        [string]$DefaultValue = "",
        [bool]$IsSecret = $false
    )

    $promptText = if ($DefaultValue) { $Question + " [" + $DefaultValue + "]: " } else { $Question + ": " }
    
    if ($IsSecret) {
        $input = Read-Host -Prompt $Question -AsSecureString
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($input)
        try {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
    else {
        $result = Read-Host -Prompt $promptText.TrimEnd(": ")
        if ([string]::IsNullOrWhiteSpace($result)) {
            return $DefaultValue
        }
        return $result
    }
}

function Prompt-Choice {
    param(
        [string]$Question,
        [array]$Options,
        [int]$DefaultIndex = 0
    )

    Write-Host "`n$Question" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $Options[$i])
    }

    $choice = Read-Host -Prompt "Select option (1-$($Options.Count)) [$($DefaultIndex + 1)]"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $Options[$DefaultIndex]
    }

    if ($choice -match '^\d+$') {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $Options.Count) {
            return $Options[$idx]
        }
    }

    Write-Host "Invalid selection, using default: $($Options[$DefaultIndex])" -ForegroundColor Yellow
    return $Options[$DefaultIndex]
}

function Prompt-YesNo {
    param(
        [string]$Question,
        [bool]$DefaultYes = $true
    )

    $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $choice = Read-Host -Prompt "$Question $suffix"
    
    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $DefaultYes
    }

    if ($choice -match '^y') { return $true }
    if ($choice -match '^n') { return $false }

    return $DefaultYes
}

# ---------------------------------------------------------------------------
# Main Wizard
# ---------------------------------------------------------------------------
Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "      QuestOps Watchdog - Client Setup Wizard" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "This wizard will help you configure monitoring for your game server."
Write-Host "It will create a configuration file and can set up automated alerts."
Write-Host "============================================================`n"

# 1. Server display name
$serverName = Prompt-User "1. Server display name (e.g. My Valheim Server)" "My Game Server"

# 2. Game type
$gameOptions = @("Project Zomboid", "Valheim", "Minecraft", "ICARUS", "7 Days to Die", "Other")
$gameType = Prompt-Choice "2. Select your game type" $gameOptions

# 3. Process name
$defaultProcess = switch ($gameType) {
    "Project Zomboid" { "ProjectZomboid64.exe" }
    "Valheim"         { "valheim_server.exe" }
    "Minecraft"       { "java.exe" }
    "ICARUS"          { "IcarusServer-Win64-Shipping.exe" }
    "7 Days to Die"   { "7DaysToDieServer.exe" }
    Default           { "server.exe" }
}
Write-Host "`nThe process name is the name of the executable file (ending in .exe) that runs your server." -ForegroundColor Gray
$processName = Prompt-User "3. Server process name" $defaultProcess

# 4. Log folder path
Write-Host "`nThe log folder is where your server writes its activity logs." -ForegroundColor Gray
$logPath = Prompt-User "4. Log folder path (e.g. C:\Games\Server\Logs)"

# 5. Backup folder path
Write-Host "`nThe backup folder is where your server stores its backup files." -ForegroundColor Gray
$backupPath = Prompt-User "5. Backup folder path (e.g. C:\Games\Server\Backups)"

# 6. Disk path
Write-Host "`nThe disk path is the drive letter or folder to monitor for free space." -ForegroundColor Gray
$diskPath = Prompt-User "6. Disk path to monitor" "C:\"

# 7. Minimum free disk GB
$minFreeGB = Prompt-User "7. Minimum free disk space (GB) before alerting" "20"

# 8. Log freshness max age minutes
$logMaxAge = Prompt-User "8. Maximum age of logs (minutes) before alerting" "30"

# 9. Backup freshness max age hours
$backupMaxAge = Prompt-User "9. Maximum age of backups (hours) before alerting" "48"

# 10. Discord webhook URL
Write-Host "`nEnter your Discord Webhook URL. This will be stored safely in your user environment variables." -ForegroundColor Gray
Write-Host "The URL will NOT be printed to the screen or saved in the configuration file." -ForegroundColor Yellow
$webhookUrl = Prompt-User "10. Discord Webhook URL" -IsSecret $true

if (-not [string]::IsNullOrWhiteSpace($webhookUrl)) {
    Write-Host "Setting environment variable QUESTOPS_DISCORD_WEBHOOK..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", $webhookUrl, "User")
    $env:QUESTOPS_DISCORD_WEBHOOK = $webhookUrl
} else {
    Write-Host "No webhook URL provided. Alerts will be suppressed until one is configured." -ForegroundColor Yellow
}

# 11. Enable summary reporting?
$enableSummary = Prompt-YesNo "11. Enable summary reporting? (Sends one grouped alert at the end of each run)"

# 12. Enable maintenance mode support?
$enableMaintenance = Prompt-YesNo "12. Enable maintenance mode support? (Allows pausing alerts by creating a flag file)"

# 13. Install scheduled task?
$installTask = Prompt-YesNo "13. Install automated scheduled task? (Runs the watchdog automatically)" $false

# 14. Scheduled task interval minutes
$taskInterval = 5
if ($installTask) {
    $taskInterval = Prompt-User "14. How often should the watchdog run (minutes)?" "5"
}

# ---------------------------------------------------------------------------
# Generate Config
# ---------------------------------------------------------------------------
$cleanGameTag = $gameType.Replace(" ", "").ToLower()
$tags = @($cleanGameTag, "windows", "dedicated")

$config = @{
    productName = "QuestOps Watchdog"
    configVersion = 1
    global = @{
        checkIntervalMinutes = [int]$taskInterval
        logDateFormat = "yyyy-MM-dd HH:mm:ss"
        stateDir = ".\\state"
        logDir = ".\\logs"
    }
    discord = @{
        webhookUrlEnvVar = "QUESTOPS_DISCORD_WEBHOOK"
        enabled = $true
        defaultCooldownMinutes = 30
    }
    summary = @{
        enabled = $enableSummary
        sendOnlyOnIssues = $true
        includeHealthyServers = $false
        cooldownMinutes = 30
    }
    servers = @(
        @{
            name = $serverName
            category = "production"
            tags = $tags
            enabled = $true
            process = @{
                name = $processName
                enabled = $true
            }
            logFile = @{
                path = $logPath
                maxAgeMinutes = [int]$logMaxAge
                enabled = ([bool]$logPath)
            }
            disk = @{
                path = $diskPath
                minFreeGB = [int]$minFreeGB
                enabled = ([bool]$diskPath)
            }
            backup = @{
                path = $backupPath
                maxAgeHours = [int]$backupMaxAge
                enabled = ([bool]$backupPath)
            }
            maintenance = @{
                enabled = $enableMaintenance
                flagPath = ".\\state\\maintenance\\$($cleanGameTag).flag"
                suppressAlerts = $true
            }
            discord = @{
                webhookUrlEnvVar = "QUESTOPS_DISCORD_WEBHOOK"
                cooldownMinutes = 30
            }
        }
    )
}

$configDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\config"
$configPath = Join-Path -Path $configDir -ChildPath "servers.client.generated.json"

Write-Host "`nWriting configuration to $configPath..." -ForegroundColor Cyan
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8

# ---------------------------------------------------------------------------
# Validate Config
# ---------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$validatorPath = Join-Path -Path $scriptDir -ChildPath "validate_config.ps1"

Write-Host "Validating generated configuration..." -ForegroundColor Cyan
& $validatorPath -ConfigPath $configPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nWARNING: The generated configuration failed validation. Please review the errors above." -ForegroundColor Red
} else {
    Write-Host "`nConfiguration generated and validated successfully." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Install Task
# ---------------------------------------------------------------------------
if ($installTask) {
    $installerPath = Join-Path -Path $scriptDir -ChildPath "install_task.ps1"
    Write-Host "`nInstalling scheduled task..." -ForegroundColor Cyan
    & $installerPath -ConfigPath "config\servers.client.generated.json" -IntervalMinutes [int]$taskInterval -ValidateConfig
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "      Setup Wizard Complete!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "You can now run the watchdog manually to test your alerts:"
Write-Host "powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.client.generated.json -ValidateConfig"
Write-Host "`nLogs will be written to the 'logs' folder."
Write-Host "============================================================`n"
