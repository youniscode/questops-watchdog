$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot

. (Join-Path $RepoRoot "lib\discord.ps1")

$webhookUrl = $env:QUESTOPS_DISCORD_WEBHOOK

if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
    Write-Host "Missing QUESTOPS_DISCORD_WEBHOOK environment variable."
    exit 1
}

$sent = Send-QODiscordWebhook `
    -WebhookUrl $webhookUrl `
    -Title "QuestOps Watchdog Test" `
    -Description "Discord webhook test completed successfully." `
    -Severity "success" `
    -ServerName "Test Server"

if ($sent) {
    Write-Host "Discord test message sent successfully."
    exit 0
}

Write-Host "Discord test message failed."
exit 2
