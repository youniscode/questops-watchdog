<#
.SYNOPSIS
    Validates a QuestOps Watchdog JSON config file for common errors.

.PARAMETER ConfigPath
    Path to the JSON config file to validate.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

$pass   = 0
$warn   = 0
$fail   = 0

function Write-Result {
    param([string]$Label, [string]$Message)
    switch ($Label) {
        'PASS' { $script:pass++; Write-Host ('PASS   ' + $Message) -ForegroundColor Green }
        'WARN' { $script:warn++; Write-Host ('WARN   ' + $Message) -ForegroundColor Yellow }
        'FAIL' { $script:fail++; Write-Host ('FAIL   ' + $Message) -ForegroundColor Red }
    }
}

function Test-IsNumeric {
    param([object]$Value)
    return $Value -is [byte] -or $Value -is [int] -or $Value -is [long] -or $Value -is [decimal] -or $Value -is [single] -or $Value -is [double]
}

Write-Host ('= ' * 30)
Write-Host ' QuestOps Watchdog - Config Validator'
Write-Host ('= ' * 30)
Write-Result -Label 'INFO' -Message ('Validating: ' + $ConfigPath)

# ---------------------------------------------------------------------------
# 1. File exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    Write-Result -Label 'FAIL' -Message 'File not found.'
    exit 1
}
Write-Result -Label 'PASS' -Message 'File exists.'

# ---------------------------------------------------------------------------
# 2. Valid JSON
# ---------------------------------------------------------------------------
try {
    $config = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
}
catch {
    Write-Result -Label 'FAIL' -Message 'Invalid JSON (' + $_.Exception.Message + ').'
    exit 1
}
Write-Result -Label 'PASS' -Message 'Valid JSON.'

# ---------------------------------------------------------------------------
# 3. Required top-level fields
# ---------------------------------------------------------------------------
if (-not $config.productName) {
    Write-Result -Label 'FAIL' -Message '"productName" is missing or empty.'
    exit 1
}
Write-Result -Label 'PASS' -Message ('productName: ' + $config.productName)

if ($config.configVersion -eq $null) {
    Write-Result -Label 'FAIL' -Message '"configVersion" is missing.'
    exit 1
}
Write-Result -Label 'PASS' -Message ('configVersion: ' + $config.configVersion)

if (-not $config.global) {
    Write-Result -Label 'FAIL' -Message '"global" section is missing.'
    exit 1
}
Write-Result -Label 'PASS' -Message '"global" section present.'

if (-not $config.discord) {
    Write-Result -Label 'FAIL' -Message '"discord" section is missing.'
    exit 1
}
Write-Result -Label 'PASS' -Message '"discord" section present.'

if (-not $config.servers -or $config.servers.Count -eq 0) {
    Write-Result -Label 'FAIL' -Message '"servers" array is missing or empty.'
    exit 1
}
$entryLabel = 'entries'
if ($config.servers.Count -eq 1) { $entryLabel = 'entry' }
Write-Result -Label 'PASS' -Message ('servers: ' + $config.servers.Count + ' ' + $entryLabel + '.')

# ---------------------------------------------------------------------------
# 4. Global Discord checks
# ---------------------------------------------------------------------------
$globalEnvVar = $config.discord.webhookUrlEnvVar
if (-not $globalEnvVar) {
    Write-Result -Label 'FAIL' -Message 'discord.webhookUrlEnvVar is missing or empty.'
    exit 1
}

if ($globalEnvVar -match 'https?://') {
    Write-Result -Label 'FAIL' -Message 'discord.webhookUrlEnvVar looks like a direct URL. Use an environment variable name, not the webhook URL itself.'
    exit 1
}
Write-Result -Label 'PASS' -Message ('discord.webhookUrlEnvVar: <env>:' + $globalEnvVar)

$discordEnabled = if ($config.discord.enabled) { $true } else { $false }
if ($discordEnabled) {
    $globalWebhookValue = [Environment]::GetEnvironmentVariable($globalEnvVar)
    if (-not $globalWebhookValue) {
        Write-Result -Label 'WARN' -Message ('discord.enabled is true but environment variable "' + $globalEnvVar + '" is not set.')
    }
}

# ---------------------------------------------------------------------------
# 5. Summary section checks
# ---------------------------------------------------------------------------
if ($config.summary) {
    $summaryEnabled = if ($config.summary.enabled) { $true } else { $false }
    if ($summaryEnabled -and -not $discordEnabled) {
        Write-Result -Label 'WARN' -Message 'summary.enabled is true but global discord.enabled is false. Summary embed requires Discord.'
    }

    if ($config.summary.PSObject.Properties.Name -notcontains 'sendOnlyOnIssues') {
        Write-Result -Label 'WARN' -Message 'summary.sendOnlyOnIssues is missing (defaults to true if omitted).'
    }
    elseif ($config.summary.sendOnlyOnIssues -isnot [bool]) {
        Write-Result -Label 'FAIL' -Message 'summary.sendOnlyOnIssues must be a boolean (true/false).'
    }

    if ($config.summary.PSObject.Properties.Name -notcontains 'includeHealthyServers') {
        Write-Result -Label 'WARN' -Message 'summary.includeHealthyServers is missing (defaults to false if omitted).'
    }
    elseif ($config.summary.includeHealthyServers -isnot [bool]) {
        Write-Result -Label 'FAIL' -Message 'summary.includeHealthyServers must be a boolean (true/false).'
    }

    if ($config.summary.PSObject.Properties.Name -contains 'cooldownMinutes') {
        $sc = $config.summary.cooldownMinutes
        if (-not (Test-IsNumeric $sc)) {
            Write-Result -Label 'FAIL' -Message 'summary.cooldownMinutes must be a number.'
        }
        elseif ($sc -lt 0) {
            Write-Result -Label 'FAIL' -Message 'summary.cooldownMinutes must be zero or positive (got ' + $sc + ').'
        }
    }
}

# ---------------------------------------------------------------------------
# 6. Per-server validation
# ---------------------------------------------------------------------------
for ($i = 0; $i -lt $config.servers.Count; $i++) {
    $sv = $config.servers[$i]
    $tag = 'server[' + $i + ']'

    if (-not $sv.name) {
        Write-Result -Label 'FAIL' -Message ($tag + ' "name" is missing or empty.')
        continue
    }

    if ($sv.enabled -eq $null) {
        Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" has no "enabled" field.')
        continue
    }

    $statusLabel = if ($sv.enabled) { 'enabled' } else { 'disabled' }
    Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" ' + $statusLabel + '.')

    # -----------------------------------------------------------------------
    # Category validation
    # -----------------------------------------------------------------------
    if ($sv.PSObject.Properties.Name -contains 'category') {
        if ($sv.category -isnot [string]) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" "category" must be a string.')
        }
        elseif ($sv.category -eq '') {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" "category" is empty string.')
        }
    }
    elseif ($sv.enabled) {
        Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but has no "category" field.')
    }

    # -----------------------------------------------------------------------
    # Tags validation
    # -----------------------------------------------------------------------
    if ($sv.PSObject.Properties.Name -contains 'tags') {
        if ($sv.tags -isnot [array]) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" "tags" must be an array of strings.')
        }
        else {
            if ($sv.tags.Count -eq 0) {
                Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" "tags" array is empty.')
            }
            else {
                $nonStringTags = $sv.tags | Where-Object { $_ -isnot [string] }
                foreach ($badTag in $nonStringTags) {
                    $tagDisplay = if ($badTag -eq $null) { 'null' } else { $badTag.ToString() }
                    Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" tag "' + $tagDisplay + '" is not a string.')
                }
            }
        }
    }
    elseif ($sv.enabled) {
        Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but has no "tags" field.')
    }

    # -----------------------------------------------------------------------
    # REPLACE_ME placeholder check (per-server fields only)
    # -----------------------------------------------------------------------
    if ($sv.enabled) {
        $replacePaths = @()
        if ($sv.logFile -and $sv.logFile.path -and ($sv.logFile.path -match 'REPLACE_ME')) { $replacePaths += 'logFile.path' }
        if ($sv.backup -and $sv.backup.path -and ($sv.backup.path -match 'REPLACE_ME')) { $replacePaths += 'backup.path' }
        if ($sv.disk -and $sv.disk.path -and ($sv.disk.path -match 'REPLACE_ME')) { $replacePaths += 'disk.path' }
        if ($replacePaths.Count -gt 0) {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but still contains placeholder paths in: ' + ($replacePaths -join ', '))
        }
    }

    # -----------------------------------------------------------------------
    # Process check
    # -----------------------------------------------------------------------
    if ($sv.process -and $sv.process.enabled) {
        if (-not $sv.process.name) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" process check enabled but "process.name" is missing.')
        }
        else {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" process: ' + $sv.process.name)
        }
    }

    # -----------------------------------------------------------------------
    # Log file check
    # -----------------------------------------------------------------------
    if ($sv.logFile -and $sv.logFile.enabled) {
        $logOk = $true

        if ($sv.enabled -and (-not $sv.logFile.path)) {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" logFile check enabled but "logFile.path" is missing.')
            $logOk = $false
        }

        $maxAge = $sv.logFile.maxAgeMinutes
        if ($maxAge -eq $null) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" logFile.maxAgeMinutes is missing.')
            $logOk = $false
        }
        elseif (-not (Test-IsNumeric $maxAge)) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" logFile.maxAgeMinutes must be a number.')
            $logOk = $false
        }
        elseif ($maxAge -le 0) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" logFile.maxAgeMinutes must be a positive number (got ' + $maxAge + ').')
            $logOk = $false
        }

        if ($logOk) {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" log: ' + $sv.logFile.path)
        }
    }

    # -----------------------------------------------------------------------
    # Disk check
    # -----------------------------------------------------------------------
    if ($sv.disk -and $sv.disk.enabled) {
        $diskOk = $true

        if ($sv.enabled -and (-not $sv.disk.path)) {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" disk check enabled but "disk.path" is missing.')
            $diskOk = $false
        }

        $minFree = $sv.disk.minFreeGB
        if ($minFree -eq $null) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" disk.minFreeGB is missing.')
            $diskOk = $false
        }
        elseif (-not (Test-IsNumeric $minFree)) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" disk.minFreeGB must be a number.')
            $diskOk = $false
        }
        elseif ($minFree -le 0) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" disk.minFreeGB must be a positive number (got ' + $minFree + ').')
            $diskOk = $false
        }

        if ($diskOk) {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" disk: ' + $sv.disk.path + ' (min ' + $minFree + ' GB)')
        }
    }

    # -----------------------------------------------------------------------
    # Backup check
    # -----------------------------------------------------------------------
    if ($sv.backup -and $sv.backup.enabled) {
        $backupOk = $true

        if ($sv.enabled -and (-not $sv.backup.path)) {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" backup check enabled but "backup.path" is missing.')
            $backupOk = $false
        }

        $maxHours = $sv.backup.maxAgeHours
        if ($maxHours -eq $null) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" backup.maxAgeHours is missing.')
            $backupOk = $false
        }
        elseif (-not (Test-IsNumeric $maxHours)) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" backup.maxAgeHours must be a number.')
            $backupOk = $false
        }
        elseif ($maxHours -le 0) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" backup.maxAgeHours must be a positive number (got ' + $maxHours + ').')
            $backupOk = $false
        }

        if ($backupOk) {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" backup: ' + $sv.backup.path + ' (max ' + $maxHours + ' hr)')
        }
    }

    # -----------------------------------------------------------------------
    # Discord per-server
    # -----------------------------------------------------------------------
    if ($sv.discord) {
        $svEnvVar = $sv.discord.webhookUrlEnvVar
        if ($svEnvVar -match 'https?://') {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" discord.webhookUrlEnvVar looks like a direct URL. Use an env var name.')
        }
        elseif (-not $svEnvVar) {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" discord.webhookUrlEnvVar is missing (will fall back to global Discord config).')
        }
        else {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" discord: <env>:' + $svEnvVar)
        }

        if ($sv.discord.PSObject.Properties.Name -contains 'cooldownMinutes') {
            $cd = $sv.discord.cooldownMinutes
            if (-not (Test-IsNumeric $cd)) {
                Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" discord.cooldownMinutes must be a number.')
            }
            elseif ($cd -lt 0) {
                Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" discord.cooldownMinutes must be zero or positive (got ' + $cd + ').')
            }
        }
    }
    else {
        Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" has no "discord" section (will fall back to global Discord config).')
    }
}

# ---------------------------------------------------------------------------
# 7. Summary
# ---------------------------------------------------------------------------
Write-Host ('= ' * 30)
Write-Host ('Results: ' + $pass + ' passed, ' + $warn + ' warnings, ' + $fail + ' failed.') -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host 'Validation FAILED. Fix the errors above before running the watchdog.' -ForegroundColor Red
    exit 1
}
else {
    Write-Host 'Validation PASSED.' -ForegroundColor Green
    exit 0
}
