<#
.SYNOPSIS
    Sends a test Discord alert to verify webhook configuration.
    Reads the webhook URL from the QUESTOPS_DISCORD_WEBHOOK environment variable.
#>

$webhookUrl = $env:QUESTOPS_DISCORD_WEBHOOK

if (-not $webhookUrl) {
    Write-Host "ERROR: Environment variable QUESTOPS_DISCORD_WEBHOOK is not set." -ForegroundColor Red
    Write-Host "Set it to your Discord webhook URL before running this script." -ForegroundColor Yellow
    Write-Host "Example: `$env:QUESTOPS_DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/...'" -ForegroundColor Yellow
    exit 1
}

# Resolve path to the discord helper library
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$libPath = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "lib\discord.ps1"
. $libPath

Write-Host "Sending test Discord alert..." -ForegroundColor Cyan

$result = Send-QODiscordWebhook -WebhookUrl $webhookUrl `
    -Title "QuestOps Watchdog - Test Alert" `
    -Description "This is a test message from QuestOps Watchdog. If you see this, your webhook is configured correctly." `
    -Severity info `
    -ServerName "Test Server"

if ($result) {
    Write-Host "SUCCESS: Test alert sent. Check your Discord channel." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "FAILED: Could not send test alert. Check the webhook URL and network." -ForegroundColor Red
    exit 1
}
