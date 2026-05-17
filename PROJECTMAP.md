# QuestOps Watchdog — Project Map

## Product Vision

QuestOps Watchdog is a standalone Windows PowerShell monitoring agent for self-hosted game servers. It monitors local game server processes, checks log and backup freshness, watches disk space, and sends clean Discord alerts — all without cloud dependencies, accounts, or subscriptions.

## Target Users

- Small gaming community server owners
- WindowsGSM users
- Valheim, Project Zomboid, Minecraft, ICARUS, 7 Days to Die admins
- Self-hosted server owners who want simple local monitoring

## Architecture Overview

```
┌─────────────────────────────────────────┐
│  QuestOps Watchdog (PowerShell 5.1)     │
│                                         │
│  scripts/questops_watchdog.ps1          │
│    ├── lib/checks.ps1    (health checks)│
│    ├── lib/discord.ps1   (webhook send) │
│    ├── lib/state.ps1     (cooldown/runtime state)
│    └── config/servers.json (monitored servers)
│                                         │
│  Outputs:                               │
│    ├── logs/    (product log files)     │
│    └── state/   (last alert timestamps) │
└─────────────────────────────────────────┘
```

- No external dependencies
- No external PowerShell modules
- No admin privilege required
- No database
- No cloud services

## Folder Structure

```
questops-watchdog/
├── config/              JSON config files
│   ├── servers.example.json      Example config (all servers disabled)
│   └── servers.local.test.json   Safe local test config (enabled, uses repo paths)
├── scripts/
│   ├── questops_watchdog.ps1  Main runner (reads config, runs checks, sends alerts)
│   ├── test_discord.ps1       Discord webhook test script
│   ├── install_task.ps1       Scheduled task installer
│   └── uninstall_task.ps1     Scheduled task uninstaller
├── lib/
│   ├── checks.ps1       Monitoring checks (Test-QOProcessRunning, Test-QOLogFreshness, Test-QOBackupFreshness, Test-QODiskSpace)
│   ├── discord.ps1      Discord webhook sender (Send-QODiscordWebhook)
│   ├── state.ps1        State & cooldown management (Read/Write/Test/Set, path builder)
│   └── diagnosis.ps1    (future) human-readable issue summaries
├── state/               Runtime state files (cooldowns, last status)
├── logs/                Local product logs
└── docs/
    └── install.md       Install instructions
```

## Build Phases

| Phase | Description |
|-------|-------------|
| 0 — Local MVP Foundation | Base structure, docs, config schema, no code yet |
| 1 — Core Checks | Process check, log freshness, disk space, backup freshness |
| 2 — Discord Integration | Webhook sender, alert formatting, cooldown logic |
| 3 — Runner + Schedule | Main loop, scheduled task integration, logging |
| 4 — Testing + Polish | Test coverage, edge cases, documentation finalization |

## Current Phase

**Phase 3 — Runner + Schedule (complete)**

Completed:
- Repository structure created (config/, scripts/, lib/, state/, logs/, docs/)
- README.md
- PROJECTMAP.md
- AI_WORKSPACE_RULES.md
- docs/install.md
- config/servers.example.json (example config with Valheim + Project Zomboid)
- config/servers.local.test.json (safe local test config — uses repo paths, enabled, 1-min cooldown)
- lib/discord.ps1 — Send-QODiscordWebhook function (Discord embed alerts, severity colours, error-safe, true/false return)
- scripts/test_discord.ps1 — Webhook test script (reads QUESTOPS_DISCORD_WEBHOOK env var, dot-sources lib, sends test embed)
- lib/checks.ps1 — All four monitoring check functions:
  - Test-QOProcessRunning — checks process by name
  - Test-QOLogFreshness — checks newest log file age
  - Test-QOBackupFreshness — checks newest backup item age
  - Test-QODiskSpace — checks drive free space
- lib/state.ps1 — State & cooldown management:
  - Get-QOStateFilePath — builds per-server state file path
  - Read-QOState — reads state JSON (empty hashtable if missing/corrupt)
  - Write-QOState — writes state JSON, creates parent folders
  - Test-QOAlertCooldown — checks cooldown per alert key
  - Set-QOAlertSent — records last-sent timestamp
- scripts/questops_watchdog.ps1 — Main runner (reads config, runs checks, manages cooldowns, sends alerts, writes state/logs, daily log file with timestamps and all check results)
- scripts/install_task.ps1 — Scheduled task installer (params: ConfigPath, TaskName, IntervalMinutes; validates paths; interactive user only; no passwords)
- scripts/uninstall_task.ps1 — Scheduled task uninstaller (safe; warns if task doesn't exist)

## Assumptions

- All servers run on the same Windows machine as the watchdog
- Discord webhook URLs are configured per monitored server (or shared)
- Process names map 1:1 to monitored game server executables
- No admin rights required for basic checks (may affect some process queries)
- Users are comfortable editing JSON config files manually

## Known Limitations (v0.1)

- Single-machine only — no remote server monitoring
- No auto-healing/restart capability
- No web dashboard or UI
- No mobile push notifications
- No database — state stored as flat JSON files

## Next Recommended Step

Phase 4 — Testing + Polish. Run the full watchdog locally using the test config, verify all checks, Discord alerts, cooldowns, state persistence, and log files work end-to-end, then write initial test coverage or smoke-test notes.
