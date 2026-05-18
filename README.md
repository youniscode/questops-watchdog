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

### Production Template

`config/servers.production.template.json` includes entries for all six supported game types:
Valheim, Project Zomboid, Minecraft, ICARUS, 7 Days to Die, and Windrose.

**All entries are disabled by default (`"enabled": false`).** Replace placeholder paths
(`C:\\REPLACE_ME\\...`) with your real server paths, then enable one server at a time.

Safe defaults in the template:
- `minFreeGB`: 20
- `cooldownMinutes`: 30
- `backup maxAgeHours`: 48
- Log max age varies by game (30 min most games, 45 min for ICARUS and Windrose)

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

Copy a config from `config/` to `config/servers.json` and edit:

| Config File | Purpose |
|-------------|---------|
| `servers.example.json` | Reference example (all disabled, Valheim + Project Zomboid) |
| `servers.local.test.json` | Safe test config (enabled, uses repo paths, 1-min cooldown) |
| `servers.production.template.json` | Production template (all disabled, 6 game types, placeholder paths, 30-min cooldown) |

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

# Local test (enabled server, safe paths, short cooldown)
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.test.json

# Validate production template (all servers disabled — safe to run)
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.production.template.json
```

The local test config (`config/servers.local.test.json`) is pre-configured for safe testing:
- Checks the PowerShell process (always running when the script runs)
- Monitors the repo's own `.\logs` directory for log freshness and backups
- Checks C: drive with a 1 GB minimum threshold
- Uses `QUESTOPS_DISCORD_WEBHOOK` env var name (same as the Discord test script)
- 1-minute cooldown for faster testing

The script:
1. Reads the config and identifies enabled servers
2. Runs each enabled check (process, log, backup, disk)
3. Sends a Discord alert when a check fails (cooldown prevents spam)
4. Writes per-server state files to `state/`
5. Writes a daily log file to `logs/questops-watchdog-YYYY-MM-DD.log`
6. Prints a coloured console summary

Logs are written to the directory configured in `global.logDir` (default: `.\logs`). Each run appends to the current day's log file with timestamps, server names, check results, and alert activity. Webhook URLs are never logged.

Set the Discord webhook URL via environment variable (name defined in config):
```powershell
$env:QUEST_OPS_DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/your-id/your-token'
```

## Scheduled Task (Automated Runs)

Install a repeating scheduled task (runs every 5 minutes by default):

```powershell
# Use the local test config first (safe, no production paths)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.local.test.json

# Use your production config when ready
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.json

# Custom interval (every 10 minutes)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.json -IntervalMinutes 10
```

Uninstall the scheduled task:

```powershell
powershell -File scripts\uninstall_task.ps1

# Custom task name (if changed during install)
powershell -File scripts\uninstall_task.ps1 -TaskName "Custom Task Name"
```

**Important notes:**
- The task runs only when you are logged on (interactive) — no passwords stored
- The task is registered but does NOT start automatically; start it from Task Scheduler or run `Start-ScheduledTask -TaskName "QuestOps Watchdog"`
- Some systems require running PowerShell as Administrator to register scheduled tasks
- Always test with `config/servers.local.test.json` first before switching to production configs

## Setup

See [docs/install.md](docs/install.md) for manual setup instructions.
