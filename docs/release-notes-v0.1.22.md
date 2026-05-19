# QuestOps Watchdog v0.1.22 — Release Notes

## Overview

QuestOps Watchdog is a portable Windows PowerShell monitoring and alerting toolkit for self-hosted game servers. This is the first MVP release.

Everything runs on your machine. No cloud, no accounts, no monthly fees, no databases, no Python, no npm.

## Core Features

### Monitoring

Four read-only health checks that never modify files or services:

- **Process check** — Verifies the game server process is running
- **Log freshness check** — Confirms log files are updating within expected intervals
- **Backup freshness check** — Confirms backup directories are up to date
- **Disk space check** — Alerts when free disk space drops below threshold

### Validation

A dedicated config validator (`validate_config.ps1`) catches issues before any check runs:

- JSON structure and required fields
- Discord webhook URL safety (rejects URLs in JSON, requires environment variables)
- Numeric threshold type checking (positive numbers for ages/sizes, non-negative for cooldowns)
- Placeholder path detection on enabled servers
- Per-server metadata (category/tags) type validation

### Alerting

- Discord embed alerts with severity colors: critical (red), warning (orange), success (green), info (blue)
- Per-check cooldown timers to prevent notification spam
- Per-server webhook URL override support
- Optional grouped summary embed at end of each run

### Maintenance Mode

Flag-file-based alert suppression for planned downtime:

- Create a flag file to enable, delete to disable — no config changes needed
- Checks and logging continue during maintenance
- Summary shows suppressed alert count

### Recovery Alerts

One-time notification when a previously-failing check passes again:

- Active failures tracked in per-server state files
- Green recovery embed sent on failure-to-healthy transition
- No repeated notifications — recovery fires exactly once

### Release Packaging

Idempotent ZIP packaging for portable deployment:

- Reads version from VERSION file
- Excludes runtime data (logs, state, git, temp configs)
- Produces a single portable ZIP for any Windows machine

## Supported Game Types

Configure one or mix any:

- Project Zomboid
- Valheim
- Minecraft
- ICARUS
- 7 Days to Die
- Enshrouded, Conan Exiles, Palworld
- Any Windows dedicated server with a process name, log folder, or backup folder

The production template ships with all six game types pre-configured but disabled — pick your server, replace paths, and enable.

## Discord Integration

- Webhook URL stored in environment variable only (never in config files or logs)
- Test script included (scripts/test_discord.ps1)
- Config validator rejects JSON files containing webhook URLs

## Installer and Uninstaller

- `scripts/install_task.ps1` — Registers Windows scheduled task with configurable interval and optional pre-flight validation
- `scripts/uninstall_task.ps1` — Removes the scheduled task safely

## Known Limitations (v0.1)

- Single-machine only — no remote server monitoring
- No auto-healing or server restart capability
- No web dashboard or graphical UI
- No mobile push notifications
- No database — state stored as flat JSON files
- No built-in diagnosis engine

## Roadmap Preview

Near-term improvements being considered:

- Human-readable diagnosis summary from state files
- More compact alert grouping and per-server run history
- Local HTML status page from state files
- Additional validators (network port, certificate expiry)
- Multi-server organization with tag-based routing

## Requirements

- Windows 7 / Server 2012 or later
- Windows PowerShell 5.1 (built into Windows)
- No additional software or modules required

## Resources

- [Installation Guide](docs/install.md)
- [Changelog](CHANGELOG.md)
- [Project Map](PROJECTMAP.md)
- [QA Checklist](docs/qa-checklist.md)
- [Release Checklist](docs/release-checklist.md)
- [Final QA Report](docs/final-qa-report.md)
