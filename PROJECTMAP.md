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
│   ├── package_release.ps1    Release packaging script
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
| 12 — Release Packaging | Clean release ZIP packaging with versioning, exclusion rules, and idempotent builds |
| 13 — Install Guide Rewrite | Beginner-friendly installation guide with step-by-step setup, environment variables, config editing, validation, scheduled task, maintenance, and troubleshooting |
| 14 — CHANGELOG & Version Tracking | VERSION file and CHANGELOG.md for release tracking; version-aware packaging; version badge in README |
| 15 — README Polish | Professional GitHub/Fiverr-ready README rewrite with features section, safety section, supported server types, roadmap, screenshot placeholders, and portfolio-friendly tone |
| 16 — Demo and Screenshot Assets | Demo files for summary, validation, maintenance, recovery, and packaging workflows; architecture document; screenshot placeholder directory |
| 17 — Fiverr Service Assets | Complete Fiverr service package: gig description, packages, FAQ, title options, search tags, portfolio summary, delivery checklist |
| 18 — MVP QA and Release Checklists | QA checklist covering repository hygiene, config validation, manual runs, scheduled task, packaging, security, documentation; release checklist covering version bump, QA, packaging, tagging, GitHub release |
| 19 — Final MVP QA Report and Release Notes | QA execution report with 40-test matrix, release notes document, MVP completion declaration |
| 20 — Client Setup Wizard | Interactive PowerShell script for non-technical setup, Discord webhook security, automated config generation and task installation |
| 21 — Windows GUI Setup Wizard | Modern WinForms-based visual installer with folder browsing, secure secret handling, and one-click task installation |

## Current Phase

**Phase 21 — Windows GUI Setup Wizard (complete)**

Version: **v0.1.24**

MVP maturity: **Release (with GUI)** — Full suite of installation tools complete. Includes interactive CLI wizard and modern Windows GUI setup wizard. Secure webhook storage, automated configuration generation, and streamlined installation for all user levels.

Completed:
- (All previous tasks...)
- Task 30: Windows GUI Setup Wizard
  - `scripts/setup_client_gui.ps1` — WinForms-based visual setup tool
  - Visual folder browsing for log and backup paths
  - Real-time output feedback box
  - Integrated generation, validation, and installation logic
  - Updated documentation to prioritize GUI setup

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

## Next Recommended Phase

**Production integrations and multi-node support** — Extend beyond local single-machine monitoring:
- Add `lib/diagnosis.ps1` for human-readable state file summaries
- Network port check validator
- Tag-based alert routing for multi-server organization
- Local HTML status page from state files
- Signed releases and streamlined packaging
- Certificate expiry check validator
