# QuestOps Watchdog

A local Windows PowerShell monitoring agent for self-hosted game servers.

## MVP v0.1 — Local Only

QuestOps Watchdog checks your game servers and sends clean Discord alerts when something is wrong. Everything runs locally on your machine. No cloud, no accounts, no monthly fees.

## Supported Checks (v0.1)

All checks are available in `lib/checks.ps1`:

| Function | What It Checks | Returns |
|----------|---------------|---------|
| `Test-QOProcessRunning` | Is the server process running? | Running, Message |
| `Test-QOLogFreshness` | Is the log file updating recently? | Fresh, AgeMinutes, Message |
| `Test-QOBackupFreshness` | Is the backup directory up to date? | Fresh, AgeHours, Message |
| `Test-QODiskSpace` | Is free disk space above the threshold? | Healthy, FreeGB, Message |

Each function returns `Success = $true/$false` and never modifies the system.

### Quick Test

```powershell
. .\lib\checks.ps1
Test-QOProcessRunning -ProcessName "explorer"
Test-QODiskSpace -DriveLetter "C" -MinimumFreeGB 5
Test-QOLogFreshness -Path "C:\Windows\Logs" -MaxAgeMinutes 1440
```

## Requirements

- Windows 7 / Server 2012 or later
- Windows PowerShell 5.1 (built into Windows)
- No additional software or modules required

## What Is NOT Included (Yet)

- AI diagnosis engine
- Web dashboard
- Cloud sync or SaaS platform
- Auto-healing / server restarts
- Database storage
- User authentication
- Mobile notifications
- Multi-server remote management

## Folder Structure

```
questops-watchdog/
├── config/          JSON configuration files
├── scripts/         PowerShell scripts (runner, setup, test)
├── lib/             PowerShell module scripts
│   ├── checks.ps1   Monitoring checks (process, log, backup, disk)
│   ├── discord.ps1  Discord webhook sender
│   └── state.ps1    State & cooldown management
├── state/           Runtime state files (cooldowns, last status)
├── logs/            Local product logs
└── docs/            Documentation
```

## Configuration

Copy `config/servers.example.json` to `config/servers.json` and edit:

```json
{
  "productName": "QuestOps Watchdog",
  "configVersion": 1,
  "global": { ... },
  "discord": { "webhookUrlEnvVar": "QUEST_OPS_DISCORD_WEBHOOK" },
  "servers": [ { "name": "...", "process": {...}, "logFile": {...}, ... } ]
}
```

- Set the `QUEST_OPS_DISCORD_WEBHOOK` environment variable to your Discord webhook URL (never write it in the JSON file).
- Each server has `enabled: false` by default — change to `true` to activate.
- All paths are examples; replace with your real server paths.
- Per-server Discord webhook can override the global one via a different env var name.

## Discord Notifications

QuestOps Watchdog sends Discord embed alerts via webhook.

### Test Your Webhook

```powershell
$env:QUESTOPS_DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/your-webhook-id/your-token'
powershell -File scripts\test_discord.ps1
```

The helper library `lib/discord.ps1` provides the `Send-QODiscordWebhook` function with severity levels: `info` (blue), `warning` (orange), `critical` (red), `success` (green).

## Alert Cooldowns

State management in `lib/state.ps1` prevents Discord spam by tracking when each alert was last sent:

1. `Read-QOState` loads per-server state from `state/<ServerKey>/state.json`
2. `Test-QOAlertCooldown` checks if enough minutes have passed since the last alert for a given `AlertKey` (e.g. `"process_stopped"`, `"log_stale"`, `"disk_low"`)
3. `Set-QOAlertSent` updates the timestamp after sending
4. `Write-QOState` persists the state back to disk

Each check type has its own cooldown timer, so a "process stopped" alert and a "disk low" alert fire independently.

## Running

Run the main watchdog from the project root:

```powershell
# Using the example config (disabled servers — no alerts sent)
powershell -File scripts\questops_watchdog.ps1

# Using your own config
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.json
```

The script:
1. Reads the config and identifies enabled servers
2. Runs each enabled check (process, log, backup, disk)
3. Sends a Discord alert when a check fails (cooldown prevents spam)
4. Writes per-server state files to `state/`
5. Prints a coloured console summary

Set the Discord webhook URL via environment variable (name defined in config):
```powershell
$env:QUEST_OPS_DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/your-id/your-token'
```

## Setup

See [docs/install.md](docs/install.md) for manual setup instructions.
