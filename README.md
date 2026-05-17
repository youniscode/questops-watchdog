# QuestOps Watchdog

A local Windows PowerShell monitoring agent for self-hosted game servers.

## MVP v0.1 — Local Only

QuestOps Watchdog checks your game servers and sends clean Discord alerts when something is wrong. Everything runs locally on your machine. No cloud, no accounts, no monthly fees.

## Supported Checks (v0.1)

- **Process Check** — Is the server process running?
- **Log Freshness** — Is the log file updating recently?
- **Backup Freshness** — Is the backup directory up to date?
- **Disk Space** — Is free disk space above the threshold?

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
├── lib/             PowerShell module scripts (checks, discord, state)
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

## Setup

See [docs/install.md](docs/install.md) for manual setup instructions.
