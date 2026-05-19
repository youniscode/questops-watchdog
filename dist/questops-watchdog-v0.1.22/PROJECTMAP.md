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

## Current Phase

**Phase 18 — MVP QA and Release Checklists (complete)**

Version: **v0.1.22**

MVP maturity: **Beta** — all core features functional, config validation hardened, release pipeline established, documentation complete, README presentation-ready, demo assets available, Fiverr service package ready for listing, QA and release processes documented.

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
- Task 20 — Release Packaging:
  - `scripts/package_release.ps1` — new release packaging script:
    - Parameters: -Version (default "dev"), -OutputDir (default ".\dist")
    - Creates release folder `dist\questops-watchdog-<version>\` with all product files
    - Creates ZIP `dist\questops-watchdog-<version>.zip`
    - Copies: config/, scripts/, lib/, docs/, README.md, PROJECTMAP.md, AI_WORKSPACE_RULES.md
    - Excludes: .git, .gitignore, logs/, state/, dist/, *.log, __*.json
    - Idempotent — safely replaces existing release folder and ZIP
    - Prints summary: version, release folder, zip path, file count
    - PowerShell 5.1 compatible, no external modules
  - `README.md`: added Release Packaging section with commands, included items, excluded items
  - `PROJECTMAP.md`: added Phase 12, updated Current Phase, updated folder structure
- Task 21 — Install Guide Rewrite:
  - `docs/install.md` — complete rewrite with 13-section beginner-friendly guide:
    - Requirements, download/extract, Discord webhook creation
    - Environment variable setup (current session + permanent)
    - Config file selection and safe editing instructions
    - Config validation, manual run, scheduled task install/uninstall
    - Maintenance mode, logs and state explanation
    - Troubleshooting: execution policy, no alerts, validation failures, task issues, leaked webhooks, wrong process/log paths
    - All commands in code blocks, no huge walls of text, no SaaS/cloud references
  - `README.md`: added Quick Start section at top, replaced old Setup section with link to full install guide
  - `PROJECTMAP.md`: added Phase 13, updated Current Phase
- Task 22 — CHANGELOG & Version Tracking:
  - `VERSION` — single source of truth file containing "v0.1.22"
  - `CHANGELOG.md` — release history from v0.1.10 to v0.1.22 with descriptions
  - `scripts/package_release.ps1` — reads VERSION file when -Version not provided; strips leading "v" to avoid double v in folder/filename; includes CHANGELOG.md and VERSION in root files
  - `README.md` — added version badge and CHANGELOG link at top; updated packaging examples
  - `PROJECTMAP.md` — added Phase 14, updated Current Phase to v0.1.22
- Task 23 — README Polish:
  - `README.md` — full rewrite for GitHub and Fiverr credibility:
    - Strong top section with project name, version, and professional tagline
    - Features section grouped by capability (Monitoring, Validation, Alerting, Maintenance, Operations, Recovery)
    - Supported server types list with production template reference
    - Why This Exists value proposition (lightweight, local-first, PowerShell-native, safe)
    - Quick Start section (extract, webhook, validate, run, schedule)
    - Safety section (no secrets in JSON, validation before execution, maintenance mode, local-only, disabled by default)
    - How It Works (checks table, alerting, state/logging)
    - Configuration overview with validator rules table
    - Screenshots section with markdown placeholders (validation, summary alert, maintenance mode)
    - Release packaging section
    - Roadmap with realistic upcoming items (no AI/cloud/auto-healing hype)
    - Practical, operations-focused tone suitable for Fiverr portfolio and GitHub visitors
    - Professional markdown with bullets, command blocks, tables, no emoji spam, no walls of text
  - `PROJECTMAP.md` — added Phase 15, updated Current Phase to v0.1.22, added MVP maturity estimate (Beta)
- Task 24 — Demo and Screenshot Assets:
  - `docs/assets/demo/demo-summary.md` — realistic grouped summary example with 4 server states (healthy, maintenance, failing, recovery), console output, Discord embed fields, configuration, and rollup counts
  - `docs/assets/demo/demo-validation.md` — three validator scenarios: clean pass, pass with warnings (placeholder paths, missing metadata), and failure (webhook URL in JSON, missing process name, negative threshold)
  - `docs/assets/demo/demo-maintenance.md` — maintenance mode workflow: config, flag-file activation, console output showing suppression, deactivation, and behavior details
  - `docs/assets/demo/demo-recovery.md` — recovery alert flow: state file with active failure, failure detection run, recovery detection run, cleared state file, recovery rules table, console output with recovery counter
  - `docs/assets/demo/demo-package.md` — release packaging: command, console output, generated folder tree, included/excluded items list, characteristics
  - `docs/assets/architecture.md` — clean text architecture diagram with data flow, execution flow (config/validator/runner/checks/state/logs/discord), library component reference, state storage layout, scheduled task integration, release packaging, and runtime characteristics
  - `README.md` — replaced old Screenshots placeholder section with Screenshots and Demo Assets section linking all 6 demo files and architecture document; added screenshot placeholder directory reference with 6 expected capture filenames
  - `docs/assets/screenshots/` — empty directory reserved for future screenshot captures
- Task 25 — Fiverr Service Assets:
  - `marketing/fiverr/gig-description.md` — clear intro, supported games list, features, what buyer receives, what is not included, delivery format; practical operations-focused tone
  - `marketing/fiverr/packages.md` — three tiers: Basic (1 server, install + Discord), Standard (multi-server, summaries, maintenance, validation), Premium (advanced setup, recovery alerts, release packaging, operations review, architecture walkthrough)
  - `marketing/fiverr/faq.md` — 14 realistic questions: supported games, Windows-only, offline operation, Discord requirement, buyer self-editing, modded server support, admin rights, failure behavior, read-only safety, multi-server, maintenance pausing, watchdog uptime, webhook safety, support scope
  - `marketing/fiverr/title-options.md` — 10 realistic Fiverr title ideas targeting Valheim, Project Zomboid, Minecraft, and generic Windows game server monitoring
  - `marketing/fiverr/search-tags.md` — primary keywords, secondary keywords, long-tail keywords, platform-specific tags organized by search intent
  - `marketing/fiverr/portfolio-summary.md` — professional one-page summary: one-liner, stack, features, supported games, safety design, target users, availability
  - `marketing/fiverr/delivery-checklist.md` — tiered checklist: per-order basics, Standard additions, Premium additions, deliverable files list, explicit not-delivered list
- Task 26 — MVP QA and Release Checklists:
  - `docs/qa-checklist.md` — comprehensive manual QA checklist with 7 sections:
    - Repository hygiene: clean git status, ignored directories, no stale files
    - Config validation: 10 tests covering pass/fail scenarios for all validator checks
    - Manual watchdog run: 5 subsections (healthy test, failure alert, recovery alert, maintenance suppression, summary reporting)
    - Scheduled task: install with validation, verify in Task Scheduler, start, uninstall, graceful missing-task handling
    - Release packaging: version correctness, folder/zip creation, included/excluded items, ZIP validity
    - Security/safety: no webhook URLs in JSON, no live paths in templates, no file modification, no secrets in ZIP
    - Documentation: README rendering, link validity, changelog/version alignment, Fiverr/demo/asset presence
  - `docs/release-checklist.md` — step-by-step release process with 7 stages:
    - Pre-release: changes committed, QA passed, clean working tree
    - Bump version: VERSION, CHANGELOG, README, PROJECTMAP updates with commit message convention
    - Run QA checklist: full execution required before proceeding
    - Package release: run packaging script, verify structure
    - Inspect release ZIP: corruption check, spot-check files, exclusion verification
    - Create git tag with message, push tag and branch
    - Optional GitHub release with changelog entry and ZIP attachment
    - Post-release: update Fiverr and portfolio references
  - `README.md` — added QA Checklist and Release Checklist links to Project Resources
  - `PROJECTMAP.md` — added Phase 18, updated Current Phase to v0.1.22

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
