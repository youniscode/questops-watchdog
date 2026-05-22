<#
.SYNOPSIS
    GUI setup wizard for QuestOps Watchdog.
    Provides a user-friendly interface for server configuration and installation.

.DESCRIPTION
    This script uses WinForms to collect server details, generate a config file,
    set environment variables, and manage task installation.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$configPath = Join-Path -Path $projectRoot -ChildPath "config\servers.client.generated.json"

# ---------------------------------------------------------------------------
# Theme Colors
# ---------------------------------------------------------------------------
$colorBg      = [System.Drawing.ColorTranslator]::FromHtml("#151A1E")
$colorPanel   = [System.Drawing.ColorTranslator]::FromHtml("#1F252B")
$colorText    = [System.Drawing.ColorTranslator]::FromHtml("#E6E6E6")
$colorTextSec = [System.Drawing.ColorTranslator]::FromHtml("#B8C0C8")
$colorInputBg = [System.Drawing.ColorTranslator]::FromHtml("#0F1317")
$colorInputText = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$colorAccent  = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")
$colorBtnBg   = [System.Drawing.ColorTranslator]::FromHtml("#26313A")

# ---------------------------------------------------------------------------
# Global State
# ---------------------------------------------------------------------------
[int]$labelWidth = 180
[int]$inputWidth = 360
[int]$buttonWidth = 80
[int]$marginLeft = 30
[int]$rightColX = 650
$statusControls = @{}
$txtOutput = $null

# ---------------------------------------------------------------------------
# Styled Control Helpers
# ---------------------------------------------------------------------------
function New-StyledLabel {
    param([string]$Text, [int]$Left, [int]$Top, [int]$Width = $labelWidth, [bool]$Secondary = $false)
    $label = New-Object Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point -ArgumentList $Left, ($Top + 3)
    $label.Size = New-Object System.Drawing.Size -ArgumentList $Width, 20
    if ($Secondary) { $label.ForeColor = $colorTextSec } else { $label.ForeColor = $colorText }
    return $label
}

function New-StyledTextBox {
    param([int]$Left, [int]$Top, [int]$Width)
    $txt = New-Object Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point -ArgumentList $Left, $Top
    $txt.Size = New-Object System.Drawing.Size -ArgumentList $Width, 25
    $txt.BackColor = $colorInputBg
    $txt.ForeColor = $colorInputText
    $txt.BorderStyle = "FixedSingle"
    return $txt
}

function New-StyledButton {
    param([string]$Text, [int]$Left, [int]$Top, [int]$Width, [int]$Height = 35, [bool]$Accent = $false)
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point -ArgumentList $Left, $Top
    $btn.Size = New-Object System.Drawing.Size -ArgumentList $Width, $Height
    $btn.BackColor = if ($Accent) { $colorAccent } else { $colorBtnBg }
    $btn.ForeColor = if ($Accent) { [System.Drawing.Color]::Black } else { $colorText }
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 9, ([System.Drawing.FontStyle]::Bold)
    return $btn
}

function New-StyledCheckBox {
    param([string]$Text, [int]$Left, [int]$Top, [bool]$Checked = $true)
    $chk = New-Object Windows.Forms.CheckBox
    $chk.Text = $Text
    $chk.Location = New-Object System.Drawing.Point -ArgumentList $Left, $Top
    $chk.Size = New-Object System.Drawing.Size -ArgumentList 400, 25
    $chk.Checked = $Checked
    $chk.ForeColor = $colorText
    $chk.FlatStyle = "Flat"
    return $chk
}

function Add-StatusRow {
    param([string]$Key, [string]$Label, [int]$Top)
    $form.Controls.Add((New-StyledLabel "$Label" $rightColX $Top 180 $true))
    $val = New-StyledLabel "..." ($rightColX + 180) $Top 300 $false
    $statusControls[$Key] = $val
    $form.Controls.Add($val)
}

# ---------------------------------------------------------------------------
# Game Templates
# ---------------------------------------------------------------------------
$gameTemplates = @{
    "Project Zomboid" = @{
        process = "ProjectZomboid64.exe"
        logPath = "$env:USERPROFILE\Zomboid\Logs"
        backupPath = "$env:USERPROFILE\Zomboid"
        diskPath = "C:\"
        minFreeGB = "20"
        logMaxAge = "30"
        backupMaxAge = "48"
        tags = @("project-zomboid", "windows", "dedicated", "modded")
    }
    "Valheim" = @{
        process = "valheim_server.exe"
        logPath = "C:\GameServers\Valheim\logs"
        backupPath = "C:\GameServers\Valheim\backups"
        diskPath = "C:\"
        minFreeGB = "20"
        logMaxAge = "30"
        backupMaxAge = "48"
        tags = @("valheim", "windows", "steam", "dedicated")
    }
    "Minecraft" = @{
        process = "java.exe"
        logPath = "C:\GameServers\Minecraft\logs"
        backupPath = "C:\GameServers\Minecraft\backups"
        diskPath = "C:\"
        minFreeGB = "20"
        logMaxAge = "30"
        backupMaxAge = "48"
        tags = @("minecraft", "java", "windows", "dedicated")
    }
    "ICARUS" = @{
        process = "IcarusServer-Win64-Shipping.exe"
        logPath = "C:\GameServers\ICARUS\logs"
        backupPath = "C:\GameServers\ICARUS\backups"
        diskPath = "C:\"
        minFreeGB = "30"
        logMaxAge = "45"
        backupMaxAge = "48"
        tags = @("icarus", "windows", "steam", "dedicated")
    }
    "7 Days to Die" = @{
        process = "7DaysToDieServer.exe"
        logPath = "C:\GameServers\7DaysToDie\logs"
        backupPath = "C:\GameServers\7DaysToDie\backups"
        diskPath = "C:\"
        minFreeGB = "20"
        logMaxAge = "30"
        backupMaxAge = "48"
        tags = @("7-days-to-die", "windows", "steam", "dedicated")
    }
    "Other" = @{
        process = "server.exe"
        logPath = "C:\GameServers\YourServer\logs"
        backupPath = "C:\GameServers\YourServer\backups"
        diskPath = "C:\"
        minFreeGB = "20"
        logMaxAge = "30"
        backupMaxAge = "48"
        tags = @("windows", "dedicated", "custom")
    }
}

# ---------------------------------------------------------------------------
# Logic Functions
# ---------------------------------------------------------------------------
function Write-OutputBox {
    param($Text)
    if ($null -eq $txtOutput) { return }
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtOutput.AppendText("[$timestamp] $Text`r`n")
}

function Update-Status {
    Write-OutputBox "Refreshing local status..."

    # Config File
    if (Test-Path $configPath) {
        $statusControls["ConfigFile"].Text = "Exists"
        $statusControls["ConfigFile"].ForeColor = $colorAccent
        
        # Config Validation
        $validatorPath = Join-Path -Path $scriptDir -ChildPath "validate_config.ps1"
        $process = Start-Process powershell.exe -ArgumentList "-NoProfile", "-File", "`"$validatorPath`"", "-ConfigPath", "`"$configPath`"" -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            $statusControls["ConfigValid"].Text = "Valid"
            $statusControls["ConfigValid"].ForeColor = $colorAccent
        } else {
            $statusControls["ConfigValid"].Text = "Invalid"
            $statusControls["ConfigValid"].ForeColor = [System.Drawing.Color]::Red
        }
    } else {
        $statusControls["ConfigFile"].Text = "Missing"
        $statusControls["ConfigFile"].ForeColor = [System.Drawing.Color]::Yellow
        $statusControls["ConfigValid"].Text = "N/A"
        $statusControls["ConfigValid"].ForeColor = $colorTextSec
    }

    # Webhook
    $webhook = [Environment]::GetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", "User")
    if (-not [string]::IsNullOrWhiteSpace($webhook)) {
        $statusControls["Webhook"].Text = "Detected"
        $statusControls["Webhook"].ForeColor = $colorAccent
    } else {
        $statusControls["Webhook"].Text = "Missing"
        $statusControls["Webhook"].ForeColor = [System.Drawing.Color]::Yellow
    }

    # Scheduled Task
    $taskName = "QuestOps Watchdog"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        $statusControls["Task"].Text = "Installed"
        $statusControls["Task"].ForeColor = $colorAccent
    } else {
        $statusControls["Task"].Text = "Not Installed"
        $statusControls["Task"].ForeColor = [System.Drawing.Color]::Yellow
    }

    # Latest Log & Summary
    $logDir = Join-Path $projectRoot "logs"
    if (Test-Path $logDir) {
        $latestLog = Get-ChildItem -Path $logDir -Filter "questops-watchdog-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestLog) {
            $statusControls["LastLog"].Text = $latestLog.LastWriteTime.ToString("yyyy-MM-dd")
            $statusControls["LastLog"].ForeColor = $colorAccent

            $lines = Get-Content -Path $latestLog.FullName -Tail 50
            $summaryLine = $lines | Where-Object { $_ -match "Summary:" } | Select-Object -Last 1
            if ($summaryLine) {
                $statusControls["SummaryLine"].Text = $summaryLine.Split("Summary:")[1].Trim()
                $statusControls["SummaryLine"].ForeColor = $colorAccent
            } else {
                $statusControls["SummaryLine"].Text = "Summary not found in log."
                $statusControls["SummaryLine"].ForeColor = $colorTextSec
            }
        } else {
            $statusControls["LastLog"].Text = "None found"
            $statusControls["LastLog"].ForeColor = [System.Drawing.Color]::Yellow
            $statusControls["SummaryLine"].Text = "No log files available."
        }
    }

    # Package
    $packagePath = Join-Path $projectRoot "dist\questops-client-package.zip"
    if (Test-Path $packagePath) {
        $statusControls["Package"].Text = "Exists"
        $statusControls["Package"].ForeColor = $colorAccent
    } else {
        $statusControls["Package"].Text = "Missing"
        $statusControls["Package"].ForeColor = $colorTextSec
    }

    Write-OutputBox "Status refresh complete."
}

function Update-From-Template {
    $selected = $cmbGameType.SelectedItem
    if (-not $gameTemplates.ContainsKey($selected)) { return }
    $template = $gameTemplates[$selected]

    if (![string]::IsNullOrWhiteSpace($txtLogPath.Text) -and $txtLogPath.Text -notlike "*YourServer*" -and $txtLogPath.Text -notlike "*$env:USERPROFILE*") {
         $result = [System.Windows.Forms.MessageBox]::Show("Load recommended defaults for $selected? This will overwrite your current paths and thresholds.", "Load Template", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
         if ($result -eq "No") { return }
    }

    $txtProcessName.Text = $template.process
    $txtLogPath.Text = $template.logPath
    $txtBackupPath.Text = $template.backupPath
    $txtDiskPath.Text = $template.diskPath
    $txtMinFreeGB.Text = $template.minFreeGB
    $txtLogMaxAge.Text = $template.logMaxAge
    $txtBackupMaxAge.Text = $template.backupMaxAge
    
    Write-OutputBox "Loaded recommended defaults for $selected."
}

function Auto-Detect-Paths {
    Write-OutputBox "Scanning for common paths..."
    $foundAny = $false

    # Project Zomboid
    $pzCandidates = @(
        "$env:USERPROFILE\Zomboid",
        "C:\Users\$env:USERNAME\Zomboid"
    )
    foreach ($path in $pzCandidates) {
        if (Test-Path $path) {
            Write-OutputBox "Detected Project Zomboid data: $path"
            $foundAny = $true
            $logCand = Join-Path $path "Logs"
            if (Test-Path $logCand) {
                $txtLogPath.Text = $logCand
                Write-OutputBox "  -> Suggested Log Path: $logCand"
            }
            $txtBackupPath.Text = $path
            Write-OutputBox "  -> Suggested Backup Path: $path"
            $cmbGameType.SelectedItem = "Project Zomboid"
        }
    }

    # WindowsGSM, SteamCMD, etc (suggestions only)
    $candidates = @("C:\WindowsGSM", "D:\WindowsGSM", "C:\steamcmd", "C:\SteamCMD", "C:\GameServers", "C:\Servers")
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            Write-OutputBox "Detected server candidate folder: $path"
            $foundAny = $true
        }
    }

    if (-not $foundAny) {
        Write-OutputBox "No common paths detected automatically."
    }
}

function Export-Client-Package {
    if (-not (Test-Path $configPath)) {
        Write-OutputBox "ERROR: Generated config not found. Click 'Generate Config' first."
        return
    }

    try {
        $exportDir = Join-Path $projectRoot "dist\client-package"
        if (Test-Path $exportDir) { Remove-Item $exportDir -Recurse -Force }
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

        Write-OutputBox "Creating client package in dist\client-package..."
        $toCopy = @("README.md", "CHANGELOG.md", "VERSION", "docs", "scripts", "lib")
        foreach ($item in $toCopy) {
            $src = Join-Path $projectRoot $item
            if (Test-Path $src) { Copy-Item $src -Destination $exportDir -Recurse -Force }
        }
        
        $confDest = Join-Path $exportDir "config"
        New-Item -ItemType Directory -Path $confDest -Force | Out-Null
        Copy-Item $configPath -Destination (Join-Path $confDest "servers.client.generated.json")

        $instrPath = Join-Path $exportDir "DELIVERY-INSTRUCTIONS.md"
        $instrContent = @"
# QuestOps Watchdog - Client Delivery Instructions
1. Extract to `C:\QuestOpsWatchdog`
2. Set `QUESTOPS_DISCORD_WEBHOOK` user environment variable
3. Run `powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.client.generated.json`
4. Run `powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.client.generated.json -ValidateConfig`
5. Install task: `powershell -File scripts\install_task.ps1 -ConfigPath config\servers.client.generated.json -IntervalMinutes 5 -ValidateConfig`
"@
        $instrContent | Out-File -FilePath $instrPath -Encoding utf8

        $zipFile = Join-Path $projectRoot "dist\questops-client-package.zip"
        if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
        
        Write-OutputBox "Zipping package to dist\questops-client-package.zip..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($exportDir, $zipFile)

        Write-OutputBox "SUCCESS: Client package exported."
        Update-Status
    }
    catch {
        Write-OutputBox "ERROR: Failed to export package. $($_.Exception.Message)"
    }
}

function Send-Test-Alert {
    if ([string]::IsNullOrWhiteSpace($txtWebhook.Text)) {
        Write-OutputBox "ERROR: Discord Webhook URL is required."
        return
    }

    [Environment]::SetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", $txtWebhook.Text, "User")
    $env:QUESTOPS_DISCORD_WEBHOOK = $txtWebhook.Text

    Write-OutputBox "Sending Discord test alert..."
    $discordLib = Join-Path $projectRoot "lib\discord.ps1"
    if (-not (Test-Path $discordLib)) { Write-OutputBox "ERROR: Discord library missing."; return }

    try {
        . $discordLib
        $result = Send-QODiscordWebhook -WebhookUrl $txtWebhook.Text -Title "QuestOps Watchdog Test Alert" -Description "Success from setup wizard." -Severity "success" -ServerName $txtServerName.Text
        if ($result) { Write-OutputBox "SUCCESS: Test alert sent." } else { Write-OutputBox "FAIL: Webhook failed." }
    }
    catch { Write-OutputBox "ERROR: $($_.Exception.Message)" }
}

function Generate-Config {
    try {
        if ([string]::IsNullOrWhiteSpace($txtWebhook.Text)) { Write-OutputBox "WARNING: Webhook URL missing." } 
        else {
            [Environment]::SetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", $txtWebhook.Text, "User")
            $env:QUESTOPS_DISCORD_WEBHOOK = $txtWebhook.Text
        }

        $selectedGame = $cmbGameType.SelectedItem
        $tags = if ($gameTemplates.ContainsKey($selectedGame)) { $gameTemplates[$selectedGame].tags } else { @("windows", "dedicated") }
        $cleanGameTag = $selectedGame.Replace(" ", "").ToLower()

        $config = @{
            productName = "QuestOps Watchdog"; configVersion = 1
            global = @{ checkIntervalMinutes = [int]$txtInterval.Text; logDateFormat = "yyyy-MM-dd HH:mm:ss"; stateDir = ".\\state"; logDir = ".\\logs" }
            discord = @{ webhookUrlEnvVar = "QUESTOPS_DISCORD_WEBHOOK"; enabled = $true; defaultCooldownMinutes = 30 }
            summary = @{ enabled = $chkSummary.Checked; sendOnlyOnIssues = $true; includeHealthyServers = $false; cooldownMinutes = 30 }
            servers = @(@{
                    name = $txtServerName.Text; category = "production"; tags = $tags; enabled = $true
                    process = @{ name = $txtProcessName.Text; enabled = $true }
                    logFile = @{ path = $txtLogPath.Text; maxAgeMinutes = [int]$txtLogMaxAge.Text; enabled = ([bool]$txtLogPath.Text) }
                    disk = @{ path = $txtDiskPath.Text; minFreeGB = [int]$txtMinFreeGB.Text; enabled = ([bool]$txtDiskPath.Text) }
                    backup = @{ path = $txtBackupPath.Text; maxAgeHours = [int]$txtBackupMaxAge.Text; enabled = ([bool]$txtBackupPath.Text) }
                    maintenance = @{ enabled = $chkMaintenance.Checked; flagPath = ".\\state\\maintenance\\$($cleanGameTag).flag"; suppressAlerts = $true }
                    discord = @{ webhookUrlEnvVar = "QUESTOPS_DISCORD_WEBHOOK"; cooldownMinutes = 30 }
            })
        }
        Write-OutputBox "Writing configuration..."
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8
        Write-OutputBox "SUCCESS: Configuration generated."
        return $true
    }
    catch { Write-OutputBox "ERROR: $($_.Exception.Message)"; return $false }
}

function Validate-Config {
    $validatorPath = Join-Path -Path $scriptDir -ChildPath "validate_config.ps1"
    Write-OutputBox "Running validation..."
    $process = Start-Process powershell.exe -ArgumentList "-NoProfile", "-File", "`"$validatorPath`"", "-ConfigPath", "`"$configPath`"" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) { Write-OutputBox "SUCCESS: Validation passed."; return $true } 
    else { Write-OutputBox "FAIL: Validation failed."; return $false }
}

function Install-Task {
    $installerPath = Join-Path -Path $scriptDir -ChildPath "install_task.ps1"
    Write-OutputBox "Installing scheduled task..."
    $args = "-NoProfile -File `"$installerPath`" -ConfigPath `"config\servers.client.generated.json`" -IntervalMinutes $($txtInterval.Text) -ValidateConfig"
    $process = Start-Process powershell.exe -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) { Write-OutputBox "SUCCESS: Task installed."; return $true } 
    else { Write-OutputBox "FAIL: Task installation failed."; return $false }
}

# ---------------------------------------------------------------------------
# Form Definition (Clean 2-Column Layout)
# ---------------------------------------------------------------------------
[int]$formWidth = 1200
[int]$formHeight = 900
$form = New-Object Windows.Forms.Form
$form.Text = "QuestOps Watchdog Setup Wizard"
$form.Size = New-Object System.Drawing.Size -ArgumentList $formWidth, $formHeight
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $colorBg
$form.ForeColor = $colorText
$form.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 9, ([System.Drawing.FontStyle]::Regular)

[int]$y = 20
[int]$col2X = 650

# --- COLUMN 1: Server Configuration ---
$lblTitle1 = New-StyledLabel "SERVER CONFIGURATION" $marginLeft $y 400
$lblTitle1.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 11, ([System.Drawing.FontStyle]::Bold)
$lblTitle1.ForeColor = $colorAccent
$form.Controls.Add($lblTitle1)
$y += 40

# Inputs
$form.Controls.Add((New-StyledLabel "Server Display Name:" $marginLeft $y))
$txtServerName = New-StyledTextBox ($marginLeft + 200) $y $inputWidth
$txtServerName.Text = "My Game Server"
$form.Controls.Add($txtServerName)
$y += 35

$form.Controls.Add((New-StyledLabel "Game Type:" $marginLeft $y))
$cmbGameType = New-Object Windows.Forms.ComboBox
$cmbGameType.Location = New-Object System.Drawing.Point -ArgumentList ($marginLeft + 200), $y
$cmbGameType.Size = New-Object System.Drawing.Size -ArgumentList $inputWidth, 25
$cmbGameType.DropDownStyle = "DropDownList"
$cmbGameType.BackColor = $colorInputBg
$cmbGameType.ForeColor = $colorInputText
$cmbGameType.FlatStyle = "Flat"
$gameOptions = @("Project Zomboid", "Valheim", "Minecraft", "ICARUS", "7 Days to Die", "Other")
foreach ($opt in $gameOptions) { [void]$cmbGameType.Items.Add($opt) }
$cmbGameType.SelectedIndex = 0
$form.Controls.Add($cmbGameType)
$y += 35

$form.Controls.Add((New-StyledLabel "Process Name (.exe):" $marginLeft $y))
$txtProcessName = New-StyledTextBox ($marginLeft + 200) $y $inputWidth
$txtProcessName.Text = "ProjectZomboid64.exe"
$form.Controls.Add($txtProcessName)
$y += 35

$form.Controls.Add((New-StyledLabel "Log Folder Path:" $marginLeft $y))
$txtLogPath = New-StyledTextBox ($marginLeft + 200) $y ($inputWidth - 90)
$form.Controls.Add($txtLogPath)
$btnBrowseLog = New-StyledButton "Browse..." ($marginLeft + 200 + $inputWidth - 80) $y 80 25
$btnBrowseLog.Add_Click({ $dialog = New-Object Windows.Forms.FolderBrowserDialog; if ($dialog.ShowDialog() -eq "OK") { $txtLogPath.Text = $dialog.SelectedPath } })
$form.Controls.Add($btnBrowseLog)
$y += 35

$form.Controls.Add((New-StyledLabel "Backup Folder Path:" $marginLeft $y))
$txtBackupPath = New-StyledTextBox ($marginLeft + 200) $y ($inputWidth - 90)
$form.Controls.Add($txtBackupPath)
$btnBrowseBackup = New-StyledButton "Browse..." ($marginLeft + 200 + $inputWidth - 80) $y 80 25
$btnBrowseBackup.Add_Click({ $dialog = New-Object Windows.Forms.FolderBrowserDialog; if ($dialog.ShowDialog() -eq "OK") { $txtBackupPath.Text = $dialog.SelectedPath } })
$form.Controls.Add($btnBrowseBackup)
$y += 35

$form.Controls.Add((New-StyledLabel "Disk Path to Monitor:" $marginLeft $y))
$txtDiskPath = New-StyledTextBox ($marginLeft + 200) $y $inputWidth
$txtDiskPath.Text = "C:\"
$form.Controls.Add($txtDiskPath)
$y += 35

$form.Controls.Add((New-StyledLabel "Min Free Disk (GB):" $marginLeft $y))
$txtMinFreeGB = New-StyledTextBox ($marginLeft + 200) $y 80
$txtMinFreeGB.Text = "20"
$form.Controls.Add($txtMinFreeGB)
$y += 35

$form.Controls.Add((New-StyledLabel "Log Max Age (Min):" $marginLeft $y))
$txtLogMaxAge = New-StyledTextBox ($marginLeft + 200) $y 80
$txtLogMaxAge.Text = "30"
$form.Controls.Add($txtLogMaxAge)
$y += 35

$form.Controls.Add((New-StyledLabel "Backup Max Age (Hr):" $marginLeft $y))
$txtBackupMaxAge = New-StyledTextBox ($marginLeft + 200) $y 80
$txtBackupMaxAge.Text = "48"
$form.Controls.Add($txtBackupMaxAge)
$y += 35

$form.Controls.Add((New-StyledLabel "Discord Webhook URL:" $marginLeft $y))
$txtWebhook = New-StyledTextBox ($marginLeft + 200) $y $inputWidth
$txtWebhook.PasswordChar = "*"
$form.Controls.Add($txtWebhook)
$y += 40

# Checkboxes
$chkSummary = New-StyledCheckBox "Enable grouped summaries (end of run report)" ($marginLeft + 200) $y
$form.Controls.Add($chkSummary)
$y += 30

$chkMaintenance = New-StyledCheckBox "Enable maintenance mode support (pausing alerts)" ($marginLeft + 200) $y
$form.Controls.Add($chkMaintenance)
$y += 30

$chkInstallTask = New-StyledCheckBox "Install automated scheduled task" ($marginLeft + 200) $y $false
$form.Controls.Add($chkInstallTask)
$y += 30

$form.Controls.Add((New-StyledLabel "Task Interval (Min):" ($marginLeft + 200) $y 120 $true))
$txtInterval = New-StyledTextBox ($marginLeft + 330) $y 60
$txtInterval.Text = "5"
$form.Controls.Add($txtInterval)
$y += 65

# --- COLUMN 2: Live Status ---
[int]$statusY = 20
$lblTitle2 = New-StyledLabel "LIVE WATCHDOG STATUS" $rightColX $statusY 400
$lblTitle2.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 11, ([System.Drawing.FontStyle]::Bold)
$lblTitle2.ForeColor = $colorAccent
$form.Controls.Add($lblTitle2)
$statusY += 40

Add-StatusRow "ConfigFile" "Config File:" $statusY; $statusY += 35
Add-StatusRow "ConfigValid" "Validation:" $statusY; $statusY += 35
Add-StatusRow "Webhook" "Webhook:" $statusY; $statusY += 35
Add-StatusRow "Task" "Scheduled Task:" $statusY; $statusY += 35
Add-StatusRow "LastLog" "Latest Log:" $statusY; $statusY += 35
Add-StatusRow "Package" "Package:" $statusY; $statusY += 35
Add-StatusRow "SummaryLine" "Latest Result:" $statusY; $statusY += 35

# --- BOTTOM: Buttons ---
$y = 580
[int]$btnW = 275
[int]$btnH = 35

# Row 1
$btnAuto = New-StyledButton "Auto-Detect Paths" $marginLeft $y $btnW $btnH -Accent $false
$btnAuto.Add_Click({ Auto-Detect-Paths })
$form.Controls.Add($btnAuto)

$btnGen = New-StyledButton "Generate Config" ($marginLeft + $btnW + 10) $y $btnW $btnH $true
$btnGen.Add_Click({ if (Generate-Config) { Update-Status } })
$form.Controls.Add($btnGen)

$btnVal = New-StyledButton "Validate Config" ($marginLeft + ($btnW * 2) + 20) $y $btnW $btnH
$btnVal.Add_Click({ if (Test-Path $configPath) { Validate-Config; Update-Status } else { Write-OutputBox "ERROR: Config missing." } })
$form.Controls.Add($btnVal)

$btnTest = New-StyledButton "Send Test Alert" ($marginLeft + ($btnW * 3) + 30) $y $btnW $btnH
$btnTest.Add_Click({ Send-Test-Alert })
$form.Controls.Add($btnTest)

$y += 45
# Row 2
$btnInstall = New-StyledButton "Install Task" $marginLeft $y $btnW $btnH $false
$btnInstall.Add_Click({ if (Generate-Config) { if (Validate-Config) { if (Install-Task) { Update-Status } } } })
$form.Controls.Add($btnInstall)

$btnExp = New-StyledButton "Export Client Package" ($marginLeft + $btnW + 10) $y $btnW $btnH
$btnExp.Add_Click({ Export-Client-Package })
$form.Controls.Add($btnExp)

$btnRef = New-StyledButton "Refresh Status" ($marginLeft + ($btnW * 2) + 20) $y $btnW $btnH
$btnRef.Add_Click({ Update-Status })
$form.Controls.Add($btnRef)

$btnExit = New-StyledButton "Close" ($marginLeft + ($btnW * 3) + 30) $y $btnW $btnH
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

$y += 50

# --- BOTTOM: Status Console ---
$txtOutput = New-Object Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ReadOnly = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.Location = New-Object System.Drawing.Point -ArgumentList $marginLeft, $y
$txtOutput.Size = New-Object System.Drawing.Size -ArgumentList 1140, 170
$txtOutput.BackColor = "Black"
$txtOutput.ForeColor = $colorAccent
$txtOutput.BorderStyle = "FixedSingle"
$txtOutput.Font = New-Object System.Drawing.Font -ArgumentList "Consolas", 9, ([System.Drawing.FontStyle]::Regular)
$form.Controls.Add($txtOutput)

# --- INIT ---
$cmbGameType.Add_SelectedIndexChanged({ Update-From-Template })
Write-OutputBox "Welcome to QuestOps Watchdog Setup Wizard."
Update-Status
$form.ShowDialog()
