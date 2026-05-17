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

## Setup

See [docs/install.md](docs/install.md) for manual setup instructions.
