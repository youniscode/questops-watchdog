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
# Form Definition
# ---------------------------------------------------------------------------
[int]$formWidth = 760
[int]$formHeight = 780
$form = New-Object Windows.Forms.Form
$form.Text = "QuestOps Watchdog Setup Wizard"
$form.Size = New-Object System.Drawing.Size -ArgumentList $formWidth, $formHeight
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 9

[int]$y = 20
[int]$labelWidth = 180
[int]$inputWidth = 360
[int]$buttonWidth = 80
[int]$marginLeft = 20
[int]$spacing = 10

function Add-Label {
    param([string]$Text, [int]$Top)
    $label = New-Object Windows.Forms.Label
    $label.Text = $Text
    [int]$xPos = $marginLeft
    [int]$yPos = $Top + 3
    $label.Location = New-Object System.Drawing.Point -ArgumentList $xPos, $yPos
    $label.Size = New-Object System.Drawing.Size -ArgumentList $labelWidth, 20
    $form.Controls.Add($label)
}

# 1. Server Name
Add-Label "Server Display Name:" $y
$txtServerName = New-Object Windows.Forms.TextBox
[int]$xName = $labelWidth + $spacing
[int]$wName = $inputWidth + $buttonWidth + $spacing
$txtServerName.Location = New-Object System.Drawing.Point -ArgumentList $xName, $y
$txtServerName.Size = New-Object System.Drawing.Size -ArgumentList $wName, 25
$txtServerName.Text = "My Game Server"
$form.Controls.Add($txtServerName)
$y += 35

# 2. Game Type
Add-Label "Game Type:" $y
$cmbGameType = New-Object Windows.Forms.ComboBox
[int]$xGame = $labelWidth + $spacing
[int]$wGame = $inputWidth + $buttonWidth + $spacing
$cmbGameType.Location = New-Object System.Drawing.Point -ArgumentList $xGame, $y
$cmbGameType.Size = New-Object System.Drawing.Size -ArgumentList $wGame, 25
$cmbGameType.DropDownStyle = "DropDownList"
$gameOptions = @("Project Zomboid", "Valheim", "Minecraft", "ICARUS", "7 Days to Die", "Other")
foreach ($opt in $gameOptions) { $cmbGameType.Items.Add($opt) }
$cmbGameType.SelectedIndex = 0
$form.Controls.Add($cmbGameType)
$y += 35

# 3. Process Name
Add-Label "Process Name (.exe):" $y
$txtProcessName = New-Object Windows.Forms.TextBox
[int]$xProc = $labelWidth + $spacing
[int]$wProc = $inputWidth + $buttonWidth + $spacing
$txtProcessName.Location = New-Object System.Drawing.Point -ArgumentList $xProc, $y
$txtProcessName.Size = New-Object System.Drawing.Size -ArgumentList $wProc, 25
$txtProcessName.Text = "ProjectZomboid64.exe"
$form.Controls.Add($txtProcessName)
$y += 35

# Update process name based on game selection
$cmbGameType.Add_SelectedIndexChanged({
    $txtProcessName.Text = switch ($cmbGameType.SelectedItem) {
        "Project Zomboid" { "ProjectZomboid64.exe" }
        "Valheim"         { "valheim_server.exe" }
        "Minecraft"       { "java.exe" }
        "ICARUS"          { "IcarusServer-Win64-Shipping.exe" }
        "7 Days to Die"   { "7DaysToDieServer.exe" }
        Default           { "server.exe" }
    }
})

# 4. Log Folder
Add-Label "Log Folder Path:" $y
$txtLogPath = New-Object Windows.Forms.TextBox
[int]$xLog = $labelWidth + $spacing
$txtLogPath.Location = New-Object System.Drawing.Point -ArgumentList $xLog, $y
$txtLogPath.Size = New-Object System.Drawing.Size -ArgumentList $inputWidth, 25
$form.Controls.Add($txtLogPath)

$btnBrowseLog = New-Object Windows.Forms.Button
$btnBrowseLog.Text = "Browse..."
[int]$xBrowseLog = $labelWidth + $inputWidth + ($spacing * 2)
[int]$yBrowseLog = $y - 1
$btnBrowseLog.Location = New-Object System.Drawing.Point -ArgumentList $xBrowseLog, $yBrowseLog
$btnBrowseLog.Size = New-Object System.Drawing.Size -ArgumentList $buttonWidth, 25
$btnBrowseLog.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") { $txtLogPath.Text = $dialog.SelectedPath }
})
$form.Controls.Add($btnBrowseLog)
$y += 35

# 5. Backup Folder
Add-Label "Backup Folder Path:" $y
$txtBackupPath = New-Object Windows.Forms.TextBox
[int]$xBackup = $labelWidth + $spacing
$txtBackupPath.Location = New-Object System.Drawing.Point -ArgumentList $xBackup, $y
$txtBackupPath.Size = New-Object System.Drawing.Size -ArgumentList $inputWidth, 25
$form.Controls.Add($txtBackupPath)

$btnBrowseBackup = New-Object Windows.Forms.Button
$btnBrowseBackup.Text = "Browse..."
[int]$xBrowseBackup = $labelWidth + $inputWidth + ($spacing * 2)
[int]$yBrowseBackup = $y - 1
$btnBrowseBackup.Location = New-Object System.Drawing.Point -ArgumentList $xBrowseBackup, $yBrowseBackup
$btnBrowseBackup.Size = New-Object System.Drawing.Size -ArgumentList $buttonWidth, 25
$btnBrowseBackup.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") { $txtBackupPath.Text = $dialog.SelectedPath }
})
$form.Controls.Add($btnBrowseBackup)
$y += 35

# 6. Disk Path
Add-Label "Disk Path to Monitor:" $y
$txtDiskPath = New-Object Windows.Forms.TextBox
[int]$xDisk = $labelWidth + $spacing
[int]$wDisk = $inputWidth + $buttonWidth + $spacing
$txtDiskPath.Location = New-Object System.Drawing.Point -ArgumentList $xDisk, $y
$txtDiskPath.Size = New-Object System.Drawing.Size -ArgumentList $wDisk, 25
$txtDiskPath.Text = "C:\"
$form.Controls.Add($txtDiskPath)
$y += 35

# 7. Thresholds Row
Add-Label "Min Free Disk (GB):" $y
$txtMinFreeGB = New-Object Windows.Forms.TextBox
[int]$xMinFree = $labelWidth + $spacing
$txtMinFreeGB.Location = New-Object System.Drawing.Point -ArgumentList $xMinFree, $y
$txtMinFreeGB.Size = New-Object System.Drawing.Size -ArgumentList 60, 25
$txtMinFreeGB.Text = "20"
$form.Controls.Add($txtMinFreeGB)

$lblLogAge = New-Object Windows.Forms.Label
$lblLogAge.Text = "Log Max Age (Min):"
[int]$xLogAge = $labelWidth + 80
[int]$yLogAge = $y + 3
$lblLogAge.Location = New-Object System.Drawing.Point -ArgumentList $xLogAge, $yLogAge
$lblLogAge.Size = New-Object System.Drawing.Size -ArgumentList 120, 20
$form.Controls.Add($lblLogAge)

$txtLogMaxAge = New-Object Windows.Forms.TextBox
[int]$xLogMax = $labelWidth + 200
$txtLogMaxAge.Location = New-Object System.Drawing.Point -ArgumentList $xLogMax, $y
$txtLogMaxAge.Size = New-Object System.Drawing.Size -ArgumentList 60, 25
$txtLogMaxAge.Text = "30"
$form.Controls.Add($txtLogMaxAge)

$lblBackupAge = New-Object Windows.Forms.Label
$lblBackupAge.Text = "Backup Max Age (Hr):"
[int]$xBackAge = $labelWidth + 270
[int]$yBackAge = $y + 3
$lblBackupAge.Location = New-Object System.Drawing.Point -ArgumentList $xBackAge, $yBackAge
$lblBackupAge.Size = New-Object System.Drawing.Size -ArgumentList 130, 20
$form.Controls.Add($lblBackupAge)

$txtBackupMaxAge = New-Object Windows.Forms.TextBox
[int]$xBackMax = $labelWidth + 400
$txtBackupMaxAge.Location = New-Object System.Drawing.Point -ArgumentList $xBackMax, $y
$txtBackupMaxAge.Size = New-Object System.Drawing.Size -ArgumentList 60, 25
$txtBackupMaxAge.Text = "48"
$form.Controls.Add($txtBackupMaxAge)
$y += 40

# 10. Discord Webhook
Add-Label "Discord Webhook URL:" $y
$txtWebhook = New-Object Windows.Forms.TextBox
[int]$xWebhook = $labelWidth + $spacing
[int]$wWebhook = $inputWidth + $buttonWidth + $spacing
$txtWebhook.Location = New-Object System.Drawing.Point -ArgumentList $xWebhook, $y
$txtWebhook.Size = New-Object System.Drawing.Size -ArgumentList $wWebhook, 25
$txtWebhook.PasswordChar = "*"
$form.Controls.Add($txtWebhook)
$y += 40

# Checkboxes
$chkSummary = New-Object Windows.Forms.CheckBox
$chkSummary.Text = "Enable grouped summaries (end of run report)"
[int]$xSummary = $labelWidth + $spacing
$chkSummary.Location = New-Object System.Drawing.Point -ArgumentList $xSummary, $y
$chkSummary.Size = New-Object System.Drawing.Size -ArgumentList 400, 25
$chkSummary.Checked = $true
$form.Controls.Add($chkSummary)
$y += 25

$chkMaintenance = New-Object Windows.Forms.CheckBox
$chkMaintenance.Text = "Enable maintenance mode support (pausing alerts)"
[int]$xMaint = $labelWidth + $spacing
$chkMaintenance.Location = New-Object System.Drawing.Point -ArgumentList $xMaint, $y
$chkMaintenance.Size = New-Object System.Drawing.Size -ArgumentList 400, 25
$chkMaintenance.Checked = $true
$form.Controls.Add($chkMaintenance)
$y += 25

$chkInstallTask = New-Object Windows.Forms.CheckBox
$chkInstallTask.Text = "Install automated scheduled task"
[int]$xInstallTask = $labelWidth + $spacing
$chkInstallTask.Location = New-Object System.Drawing.Point -ArgumentList $xInstallTask, $y
$chkInstallTask.Size = New-Object System.Drawing.Size -ArgumentList 220, 25
$chkInstallTask.Checked = $false
$form.Controls.Add($chkInstallTask)

$lblInterval = New-Object Windows.Forms.Label
$lblInterval.Text = "Interval (Min):"
[int]$xIntLbl = $labelWidth + 240
[int]$yIntLbl = $y + 3
$lblInterval.Location = New-Object System.Drawing.Point -ArgumentList $xIntLbl, $yIntLbl
$lblInterval.Size = New-Object System.Drawing.Size -ArgumentList 90, 20
$form.Controls.Add($lblInterval)

$txtInterval = New-Object Windows.Forms.TextBox
[int]$xIntTxt = $labelWidth + 330
$txtInterval.Location = New-Object System.Drawing.Point -ArgumentList $xIntTxt, $y
$txtInterval.Size = New-Object System.Drawing.Size -ArgumentList 50, 25
$txtInterval.Text = "5"
$form.Controls.Add($txtInterval)
$y += 50

# Output Box
$txtOutput = New-Object Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ReadOnly = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.Location = New-Object System.Drawing.Point -ArgumentList $marginLeft, $y
$txtOutput.Size = New-Object System.Drawing.Size -ArgumentList 705, 200
$txtOutput.BackColor = "Black"
$txtOutput.ForeColor = "Lime"
$txtOutput.Font = New-Object System.Drawing.Font -ArgumentList "Consolas", 9
$form.Controls.Add($txtOutput)
$y += 215

# ---------------------------------------------------------------------------
# Logic Functions
# ---------------------------------------------------------------------------
function Write-OutputBox {
    param($Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtOutput.AppendText("[$timestamp] $Text`r`n")
}

function Generate-Config {
    try {
        if ([string]::IsNullOrWhiteSpace($txtWebhook.Text)) {
            Write-OutputBox "WARNING: No webhook URL provided. Alerts will be suppressed."
        } else {
            Write-OutputBox "Setting environment variable QUESTOPS_DISCORD_WEBHOOK..."
            [Environment]::SetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", $txtWebhook.Text, "User")
            $env:QUESTOPS_DISCORD_WEBHOOK = $txtWebhook.Text
        }

        $cleanGameTag = $cmbGameType.SelectedItem.Replace(" ", "").ToLower()
        $tags = @($cleanGameTag, "windows", "dedicated")

        $config = @{
            productName = "QuestOps Watchdog"
            configVersion = 1
            global = @{
                checkIntervalMinutes = [int]$txtInterval.Text
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
                enabled = $chkSummary.Checked
                sendOnlyOnIssues = $true
                includeHealthyServers = $false
                cooldownMinutes = 30
            }
            servers = @(
                @{
                    name = $txtServerName.Text
                    category = "production"
                    tags = $tags
                    enabled = $true
                    process = @{
                        name = $txtProcessName.Text
                        enabled = $true
                    }
                    logFile = @{
                        path = $txtLogPath.Text
                        maxAgeMinutes = [int]$txtLogMaxAge.Text
                        enabled = ([bool]$txtLogPath.Text)
                    }
                    disk = @{
                        path = $txtDiskPath.Text
                        minFreeGB = [int]$txtMinFreeGB.Text
                        enabled = ([bool]$txtDiskPath.Text)
                    }
                    backup = @{
                        path = $txtBackupPath.Text
                        maxAgeHours = [int]$txtBackupMaxAge.Text
                        enabled = ([bool]$txtBackupPath.Text)
                    }
                    maintenance = @{
                        enabled = $chkMaintenance.Checked
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

        Write-OutputBox "Writing configuration to config\servers.client.generated.json..."
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8
        Write-OutputBox "SUCCESS: Configuration generated."
        return $true
    }
    catch {
        Write-OutputBox "ERROR: Failed to generate config. $($_.Exception.Message)"
        return $false
    }
}

function Validate-Config {
    $validatorPath = Join-Path -Path $scriptDir -ChildPath "validate_config.ps1"
    Write-OutputBox "Running validation..."
    $process = Start-Process powershell.exe -ArgumentList "-NoProfile", "-File", "`"$validatorPath`"", "-ConfigPath", "`"$configPath`"" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-OutputBox "SUCCESS: Configuration validation passed."
        return $true
    } else {
        Write-OutputBox "FAIL: Configuration validation failed. Check the console window for details."
        return $false
    }
}

function Install-Task {
    $installerPath = Join-Path -Path $scriptDir -ChildPath "install_task.ps1"
    Write-OutputBox "Installing scheduled task..."
    $args = "-NoProfile -File `"$installerPath`" -ConfigPath `"config\servers.client.generated.json`" -IntervalMinutes $($txtInterval.Text) -ValidateConfig"
    $process = Start-Process powershell.exe -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-OutputBox "SUCCESS: Scheduled task installed."
        return $true
    } else {
        Write-OutputBox "FAIL: Scheduled task installation failed."
        return $false
    }
}

# ---------------------------------------------------------------------------
# Buttons
# ---------------------------------------------------------------------------
$btnGenerate = New-Object Windows.Forms.Button
$btnGenerate.Text = "Generate Config"
$btnGenerate.Location = New-Object System.Drawing.Point -ArgumentList $marginLeft, $y
$btnGenerate.Size = New-Object System.Drawing.Size -ArgumentList 130, 35
$btnGenerate.Add_Click({ Generate-Config })
$form.Controls.Add($btnGenerate)

$btnValidate = New-Object Windows.Forms.Button
$btnValidate.Text = "Validate Config"
[int]$xVal = 160
$btnValidate.Location = New-Object System.Drawing.Point -ArgumentList $xVal, $y
$btnValidate.Size = New-Object System.Drawing.Size -ArgumentList 130, 35
$btnValidate.Add_Click({ 
    if (Test-Path $configPath) { Validate-Config } 
    else { Write-OutputBox "ERROR: Config file not found. Generate it first." }
})
$form.Controls.Add($btnValidate)

$btnInstall = New-Object Windows.Forms.Button
$btnInstall.Text = "Install Task"
[int]$xInst = 300
$btnInstall.Location = New-Object System.Drawing.Point -ArgumentList $xInst, $y
$btnInstall.Size = New-Object System.Drawing.Size -ArgumentList 130, 35
$btnInstall.Add_Click({
    if (Generate-Config) {
        if (Validate-Config) {
            Install-Task
        }
    }
})
$form.Controls.Add($btnInstall)

$btnClose = New-Object Windows.Forms.Button
$btnClose.Text = "Close"
[int]$xClose = 605
$btnClose.Location = New-Object System.Drawing.Point -ArgumentList $xClose, $y
$btnClose.Size = New-Object System.Drawing.Size -ArgumentList 120, 35
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

# Initial message
Write-OutputBox "Welcome to QuestOps Watchdog Setup Wizard."
Write-OutputBox "Fill in your server details and click 'Generate Config' to start."

$form.ShowDialog()
