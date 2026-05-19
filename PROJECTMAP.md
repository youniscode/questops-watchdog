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
│   ├── servers.example.json                Example config (all servers disabled)
│   ├── servers.local.test.json             Safe local test config (enabled, uses repo paths)
│   └── servers.production.template.json    Production template (all disabled, 6 games, placeholder paths)
├── scripts/
│   ├── questops_watchdog.ps1  Main runner (reads config, runs checks, sends alerts)
│   ├── test_discord.ps1       Discord webhook test script
│   ├── install_task.ps1       Scheduled task installer
│   ├── uninstall_task.ps1     Scheduled task uninstaller
│   └── validate_config.ps1    Config file validator
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
| 5 — Polish & Hardening | Config validation on run, encoding fixes, edge case hardening |
| 6 — Maintenance Mode | Flag-file based maintenance mode, alert suppression during planned downtime |
| 7 — Recovery Alerts | Send one-time success notifications when a failing check recovers |
| 8 — Summary Embed | Optional grouped Discord summary at end of each run |
| 9 — Category/Tags Metadata | Per-server category and tags for identification, validation, and summary display |
| 10 — Validation Hardening | Production-ready config validation: numeric thresholds, type safety, path checks, Discord safety, summary consistency |
| 11 — Task Installer Hardening | Safe scheduled task installer with pre-install config validation, clear install summary, and persistent -ValidateConfig in task action |

## Current Phase

**Phase 11 — Task Installer Hardening (complete)**

Completed:
- Repository structure created (config/, scripts/, lib/, state/, logs/, docs/)
- README.md
- PROJECTMAP.md
- AI_WORKSPACE_RULES.md
- docs/install.md
- config/servers.example.json (example config with Valheim + Project Zomboid)
- config/servers.local.test.json (safe local test config — uses repo paths, enabled, 1-min cooldown, includes disabled maintenance section)
- config/servers.production.template.json (production template — all disabled, 6 game types, each includes disabled maintenance section with per-server flag paths)
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
  - Task 13: Added -ValidateConfig switch — calls validate_config.ps1 before running checks; stops safely if config is invalid
  - Task 14: Added maintenance mode support — per-server maintenance.enabled + flagPath; checks run, logs write, alerts suppressed; $totalSuppressed counter in summary
  - Task 15: Added recovery alerts — tracks active failures via Set-QOAlertActive/Clear-QOAlertActive/Test-QOAlertActive in lib/state.ps1; sends one `success` recovery embed per transition from failing to healthy; respects maintenance mode; $totalRecoveries counter in summary
  - Task 16: Added optional grouped run summary embed — configurable via top-level `summary` section; collects per-server results (healthy/issue/skipped/maintenance); sends one Discord embed at end of run with rollup counts and per-server fields; respects sendOnlyOnIssues, includeHealthyServers, and cooldownMinutes settings; cooldown tracked in `__summary__/state.json`
- scripts/install_task.ps1 — Scheduled task installer (params: ConfigPath, TaskName, IntervalMinutes, ValidateConfig; validates paths; interactive user only; no passwords; pre-install config validation via -ValidateConfig; persistent -ValidateConfig in task action; clear install summary)
- scripts/uninstall_task.ps1 — Scheduled task uninstaller (safe; warns if task doesn't exist)
- scripts/validate_config.ps1 — Config file validator (checks structure, fields, webhook env var safety, numeric thresholds, type safety, path validation; exits 0/1)

Testing verified:
- All 4 checks run and report correctly with test config (process=running, log/backup=fresh, disk=OK)
- Process failure correctly detected (STOPPED) when process name is invalid
- Alert suppression logged with accurate reason ("no webhook URL configured") when no Discord webhook is set
- Cooldown suppression works — cooldown message shown when cooldown is active
- Daily log file created with timestamps, check results, alert/suppression entries, and summary
- State files created only when alerts are actually sent (not on suppression)
- All 3 config files pass validation (servers.local.test.json, servers.example.json, servers.production.template.json)
- Inline `if` expressions inside PowerShell string concatenation fixed in validate_config.ps1 (line 119)
- Alert suppression messages fixed in questops_watchdog.ps1 (all 4 checks) — now distinguishes cooldown vs. missing webhook URL
- -ValidateConfig switch calls validate_config.ps1 and aborts on failure
- Maintenance mode suppresses Discord alerts while checks/logs continue running
- maintenance section added to all config files (disabled by default, enabled by creating flag file)
- Summary includes suppressed count
- Recovery alerts sent when a previously-failing check passes again (one-time per transition)
- Recovery alerts suppressed during maintenance mode or when webhook URL is not set
- active_failures tracked in per-server state via Set-QOAlertActive / Clear-QOAlertActive / Test-QOAlertActive
- lib/state.ps1 functions: Set-QOAlertActive, Clear-QOAlertActive, Test-QOAlertActive
- Summary embed sends grouped Discord embed with per-server fields at end of run
- Summary respects cooldown, sendOnlyOnIssues, and includeHealthyServers settings
- Summary section added to all config files (disabled by default)
- Task 17 — Category/Tags Metadata:
  - `config/servers.local.test.json`: added category "test" and tags ["local","test","windows"]
  - `config/servers.production.template.json`: added category + unique tags to all 6 server entries
  - `scripts/validate_config.ps1`: warns when enabled server lacks category/tags; fails on type mismatch
  - `scripts/questops_watchdog.ps1`: stores Category/Tags in $serverResults; includes in summary embed field values when present
  - `README.md`: documented category/tags fields and validation behavior
- Task 18 — Validation Hardening:
  - `scripts/validate_config.ps1` — full rewrite with hardened validation:
    - Numeric type checking via Test-IsNumeric (catches string, bool, object instead of number)
    - logFile.maxAgeMinutes must be positive number (not just truthy)
    - disk.minFreeGB must be positive number
    - backup.maxAgeHours must be positive number
    - discord.cooldownMinutes must be >= 0 if present
    - summary.cooldownMinutes must be >= 0 if present
    - Empty category string warns
    - Empty tags array warns
    - Each tag element validated as string (fails on non-strings)
    - Discord global warns if enabled but env var not set
    - Per-server discord warns if missing webhookUrlEnvVar or no discord section
    - Per-server discord.webhookUrlEnvVar fails if it contains http:// or https:// anywhere
    - Summary warns if enabled but Discord disabled
    - Summary warns if sendOnlyOnIssues or includeHealthyServers are missing
    - Placeholder path check now per-server (checks each field individually instead of raw file scan)
    - Missing path on enabled check warns instead of fails
- Task 19 — Task Installer Hardening:
  - `scripts/install_task.ps1` — added -ValidateConfig switch:
    - Calls validate_config.ps1 before registering the task if -ValidateConfig is used
    - Aborts installation with exit 1 if validation fails
    - Verifies validate_config.ps1 exists before calling it
    - Task action includes -ValidateConfig when installer was called with -ValidateConfig
    - Clear install summary showing task name, interval, resolved config path, validation enabled (Yes/No), runner path
    - No secrets printed
  - `README.md`: updated Scheduled Task section with safe install command, -ValidateConfig usage, and uninstall command

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

Add `lib/diagnosis.ps1` — a human-readable issue summary generator that reads state files and produces plain-text summaries of current server health, recent failures, and recovery history. Useful for local health checks without Discord.
