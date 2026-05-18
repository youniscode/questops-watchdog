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
# 4. Discord webhook env var
# ---------------------------------------------------------------------------
$globalEnvVar = $config.discord.webhookUrlEnvVar
if (-not $globalEnvVar) {
    Write-Result -Label 'FAIL' -Message 'discord.webhookUrlEnvVar is missing or empty.'
    exit 1
}
if ($globalEnvVar -match '^https?://') {
    Write-Result -Label 'FAIL' -Message 'discord.webhookUrlEnvVar looks like a direct URL. Use an environment variable name, not the webhook URL itself.'
    exit 1
}
Write-Result -Label 'PASS' -Message ('discord.webhookUrlEnvVar: <env>:' + $globalEnvVar)

# ---------------------------------------------------------------------------
# 5. Per-server validation
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

    # warn if enabled but paths contain REPLACE_ME
    if ($sv.enabled) {
        $raw = Get-Content -LiteralPath $ConfigPath -Raw
        if ($raw -match 'REPLACE_ME') {
            Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but still contains placeholder paths (REPLACE_ME).')
        }
    }

    # category validation
    if ($sv.PSObject.Properties.Name -contains 'category') {
        if ($sv.category -isnot [string]) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" "category" must be a string.')
        }
    }
    elseif ($sv.enabled) {
        Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but has no "category" field.')
    }

    # tags validation
    if ($sv.PSObject.Properties.Name -contains 'tags') {
        if ($sv.tags -isnot [array]) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" "tags" must be an array of strings.')
        }
    }
    elseif ($sv.enabled) {
        Write-Result -Label 'WARN' -Message ($tag + ' "' + $sv.name + '" is enabled but has no "tags" field.')
    }

    # process check
    if ($sv.process -and $sv.process.enabled) {
        if (-not $sv.process.name) {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" process check enabled but "process.name" is missing.')
        }
        else {
            Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" process: ' + $sv.process.name)
        }
    }

    # logFile check
    if ($sv.logFile -and $sv.logFile.enabled) {
        $logOk = $true
        if (-not $sv.logFile.path)    { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" logFile.path missing.');  $logOk = $false }
        if (-not $sv.logFile.maxAgeMinutes) { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" logFile.maxAgeMinutes missing.'); $logOk = $false }
        if ($logOk) { Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" log: ' + $sv.logFile.path) }
    }

    # disk check
    if ($sv.disk -and $sv.disk.enabled) {
        $diskOk = $true
        if (-not $sv.disk.path)         { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" disk.path missing.');          $diskOk = $false }
        if (-not $sv.disk.minFreeGB)    { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" disk.minFreeGB missing.');     $diskOk = $false }
        if ($diskOk) { Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" disk: ' + $sv.disk.path + ' (min ' + $sv.disk.minFreeGB + ' GB)') }
    }

    # backup check
    if ($sv.backup -and $sv.backup.enabled) {
        $backupOk = $true
        if (-not $sv.backup.path)        { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" backup.path missing.');        $backupOk = $false }
        if (-not $sv.backup.maxAgeHours) { Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" backup.maxAgeHours missing.'); $backupOk = $false }
        if ($backupOk) { Write-Result -Label 'PASS' -Message ($tag + ' "' + $sv.name + '" backup: ' + $sv.backup.path + ' (max ' + $sv.backup.maxAgeHours + ' hr)') }
    }

    # discord per-server
    if ($sv.discord) {
        if ($sv.discord.webhookUrlEnvVar -match '^https?://') {
            Write-Result -Label 'FAIL' -Message ($tag + ' "' + $sv.name + '" discord.webhookUrlEnvVar looks like a direct URL. Use an env var name.')
        }
    }
}

# ---------------------------------------------------------------------------
# Summary
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
