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

### Server Metadata: Category & Tags

Each server can optionally include `category` (string) and `tags` (array of strings) for identification:

```json
{
  "name": "Valheim",
  "category": "survival",
  "tags": ["valheim", "survival", "viking"],
  "enabled": false,
  ...
}
```

- `category` — a single classification label (e.g. "survival", "sandbox", "mmo", "test")
- `tags` — free-form array of identifiers for filtering or display
- Both are optional; the run summary embed includes them in per-server field values when present
- The config validator warns when enabled servers lack `category` or `tags`, and fails on type mismatches (category must be a string, tags must be an array)

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

## Maintenance Mode

Temporarily suppress Discord alerts for a server during planned maintenance. Checks still run and results appear in logs — only the Discord notification is suppressed.

### Configuration

Each server can have a `maintenance` section in the config:

```json
"maintenance": {
  "enabled": false,
  "flagPath": ".\\state\\maintenance\\my-server.flag",
  "suppressAlerts": true
}
```

- `enabled` — set to `true` to check for the flag file
- `flagPath` — path to a flag file (create/remove this file to toggle maintenance)
- `suppressAlerts` — when `true`, Discord alerts are suppressed during maintenance

### Usage

Create the flag file to enable maintenance mode, then remove it when done:

```powershell
# Enable maintenance mode (creates flag file)
New-Item -ItemType File -Path ".\\state\\maintenance\\local-test.flag" -Force

# Run the watchdog — checks run, logs write, alerts are suppressed
powershell -File scripts\\questops_watchdog.ps1 -ConfigPath config\\servers.local.test.json

# Disable maintenance mode (remove flag file)
Remove-Item -LiteralPath ".\\state\\maintenance\\local-test.flag"
```

When maintenance is active, the console shows `MAINTENANCE : active (alerts suppressed)` per server, and the summary includes the suppressed count. Alerts suppressed by maintenance are logged separately from cooldown-suppressed alerts.

## Recovery Alerts

When a previously-failing check passes again, QuestOps Watchdog sends one recovery alert (severity: success, green). This prevents repeated notifications while still notifying you when the issue is resolved.

Recovery behavior:
- Only sent once per transition (failing → healthy), never repeated
- Not sent during maintenance mode (alongside failure alert suppression)
- Not sent if there was no previous failure recorded
- Recovery titles: "Process Recovered", "Log Freshness Recovered", "Backup Freshness Recovered", "Disk Space Recovered"
- The summary includes the count of recovery alerts sent

The `active_failures` list is tracked in per-server state files under `state/<ServerKey>/state.json`. A recovery is eligible when:
1. The check was previously failing (recorded in `active_failures`)
2. The check now passes
3. Discord webhook is configured
4. Maintenance mode is not active

## Run Summary Embed

At the end of each run, the watchdog can optionally send one grouped Discord summary embed showing the overall run health — total servers, checks, alerts, suppressed, recoveries, and per-server status fields.

Config (placed at the top level, alongside `discord` and `global`):

```json
"summary": {
  "enabled": false,
  "sendOnlyOnIssues": true,
  "includeHealthyServers": false,
  "cooldownMinutes": 30
}
```

- `enabled` — set to `true` to enable summary embeds
- `sendOnlyOnIssues` — when `true`, only sends summary if there are issues, recoveries, or suppressed alerts
- `includeHealthyServers` — when `false`, only servers with issues/maintenance/recoveries appear in fields
- `cooldownMinutes` — prevents sending repeated summary embeds (uses `__summary__/state.json`)

Summary embed fields show per-server status: "Healthy", "Issue (N failed)", "Maintenance Mode", or "Skipped".

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

# Validate config before running checks (exits early if config is invalid)
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.test.json -ValidateConfig
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
# Use the local test config first (safe, no production paths, with validation)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.local.test.json -ValidateConfig

# Install without validation
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.local.test.json

# Use your production config when ready (with validation)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.json -ValidateConfig

# Custom interval (every 10 minutes)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.json -IntervalMinutes 10
```

When `-ValidateConfig` is used:
1. The config is validated by `scripts/validate_config.ps1` before the task is created
2. If validation fails, installation is aborted with exit 1
3. If validation passes, the task action includes `-ValidateConfig` so every scheduled run validates before executing checks
4. The install summary shows `Validation: Yes`

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

## Config Validation

Validate a config before running the watchdog:

```powershell
powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.local.test.json
powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.production.template.json
```

The validator performs the following checks and exits 0 on pass, 1 on failure. Never sends alerts or modifies files.

| Category | Checks |
|----------|--------|
| File/JSON | File exists, valid JSON |
| Required fields | productName, configVersion, global, discord, servers (non-empty) |
| Discord (global) | webhookUrlEnvVar is an env var name (not a URL), warns if enabled but env var not set |
| Summary | Warns if enabled but Discord disabled, warns if sendOnlyOnIssues or includeHealthyServers are missing, validates cooldownMinutes >= 0 |
| Names/Enabled | Each server has name and enabled flag |
| Metadata | category must be string (warns if empty), tags must be array of strings (warns if empty, fails on non-string elements) |
| Process | Fails if enabled but process.name is missing |
| Log file | Warns if enabled but path missing, fails if maxAgeMinutes is not a positive number |
| Disk | Warns if enabled but path missing, fails if minFreeGB is not a positive number |
| Backup | Warns if enabled but path missing, fails if maxAgeHours is not a positive number |
| Discord (per-server) | Fails if webhookUrlEnvVar contains a URL, warns if missing env var (falls back to global), validates cooldownMinutes >= 0, warns if discord section absent (falls back to global) |
| Placeholder paths | Warns if enabled server still uses REPLACE_ME in logFile, backup, or disk paths |

## Release Packaging

Package a clean release ZIP for distribution:

```powershell
# Package with a specific version
powershell -File scripts\package_release.ps1 -Version "0.1.0"

# Package with default version "dev"
powershell -File scripts\package_release.ps1
```

Generated output:

- Release folder: `dist\questops-watchdog-<version>\`
- ZIP archive:   `dist\questops-watchdog-<version>.zip`

### Included in the release

| Item | Source |
|------|--------|
| `README.md`, `PROJECTMAP.md`, `AI_WORKSPACE_RULES.md` | Project root |
| `config\` | All JSON config files |
| `scripts\` | All PowerShell scripts (runner, installer, validator, packager, test) |
| `lib\` | All PowerShell library modules (checks, discord, state) |
| `docs\` | Documentation |

### Excluded from the release

- `.git\`, `.gitignore` — version control files
- `logs\` — runtime log files (`*.log`)
- `state\` — runtime state files
- `dist\` — previous build artifacts
- Temporary test configs (`__*.json`)

## Setup

See [docs/install.md](docs/install.md) for manual setup instructions.
