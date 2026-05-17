# AI Workspace Rules

## Allowed Workspace

Only work inside:

```
C:\DevProjects\questops-watchdog
```

## Strictly Forbidden

Do NOT touch, modify, read, or scan:

- `C:\QuestPauseOps`
- `C:\WindowsGSM`
- Any live game server files
- Any scheduled tasks
- Any production scripts, backups, or logs
- Any system or firewall settings
- Any files outside `C:\DevProjects\questops-watchdog`

## Do NOT Install

- npm packages
- PowerShell modules
- Python packages
- Services
- Databases
- Docker
- WSL
- External dependencies of any kind

## Do NOT Build

- Cloud infrastructure or SaaS platforms
- Billing or payment systems
- Web dashboards or APIs
- Databases
- Telemetry or account systems
- Launchers or auto-updaters

## Project Rules

- This is a standalone Windows PowerShell 5.1 product
- No external dependencies or modules
- No admin privilege assumptions
- Small readable files with clear comments
- Safe defaults and defensive coding

## MVP Scope (v0.1)

Allowed:
1. Read monitored servers from JSON config
2. Check if process is running
3. Check log freshness
4. Check backup freshness
5. Check free disk space
6. Send Discord webhook alerts
7. Write local state files
8. Write local logs
9. Support multiple monitored servers

Not allowed yet:
- AI diagnosis engine
- Web dashboard
- Cloud sync
- SaaS platform
- Authentication
- Auto-healing/restarts
- Databases
- Advanced analytics

## Source of Truth

Before making any change, read:
- `AI_WORKSPACE_RULES.md` (this file)
- `PROJECTMAP.md` (phase, architecture, completed work, next tasks)
- `README.md` (setup, usage, folder structure)

PROJECTMAP.md is the authoritative source for:
- Current phase
- Architecture decisions
- Completed work
- Allowed scope
- Next tasks
- Assumptions and limitations

Do not invent new project directions. Do not skip phases. Do not introduce future architecture early.
