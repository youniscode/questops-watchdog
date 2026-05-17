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
│   └── servers.json     (future) monitored server definitions
├── scripts/
│   ├── questops_watchdog.ps1  (future) main runner
│   ├── test_discord.ps1       (future) webhook test
│   └── install_task.ps1       (future) scheduled task installer
├── lib/
│   ├── checks.ps1       (future) process, log, disk, backup checks
│   ├── discord.ps1      (future) Discord webhook sender
│   ├── state.ps1        (future) cooldown and state management
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

**Phase 0 — Local MVP Foundation**

Completed:
- Repository structure created (config/, scripts/, lib/, state/, logs/, docs/)
- README.md
- PROJECTMAP.md
- AI_WORKSPACE_RULES.md
- docs/install.md
- config/servers.example.json (example config with Valheim + Project Zomboid)

Not started:
- PowerShell check scripts
- Discord webhook integration
- Main runner script
- Scheduled task setup

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

Implement the first core check (process check) in `lib/checks.ps1`, reading from `config/servers.json`.
