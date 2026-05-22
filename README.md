# QuestOps Watchdog

**v0.1.22** — [Changelog](CHANGELOG.md) — [Installation Guide](docs/install.md) — [Release Notes](docs/release-notes-v0.1.22.md) — [QA Report](docs/final-qa-report.md)

Portable PowerShell monitoring and alerting toolkit for self-hosted game servers.

---

## Why This Exists

Self-hosted game servers crash, fill up disks, and stop producing logs. QuestOps Watchdog is a lightweight, local-first PowerShell agent that checks process health, disk space, log freshness, and backup freshness — then sends Discord alerts when something is wrong.

Everything runs on your machine. No cloud, no accounts, no monthly fees, no databases, no Python, no npm.

Designed for operators who want production visibility without production complexity.

---

## Features

| Area | Capabilities |
|------|-------------|
| **Monitoring** | Process health, disk free space, log file freshness, backup file freshness |
| **Validation** | Config validator catches JSON errors, placeholder paths, webhook URL leaks, bad thresholds before any check runs |
| **Alerting** | Discord embed alerts with severity colors, per-check cooldowns, per-server webhook overrides, optional grouped run summary |
| **Recovery** | One-time recovery alert when a failing check passes again — no repeated notifications |
| **Maintenance** | Flag-file-based maintenance mode suppresses alerts while checks and logging continue |
| **Operations** | Repeating scheduled task with pre-flight validation, daily log files, per-server state tracking, idempotent release packaging |

---

## Supported Server Types

Configure one or mix any:
- Project Zomboid
- Valheim
- Minecraft
- ICARUS
- 7 Days to Die
- Enshrouded / Conan Exiles / Palworld
- Any Windows dedicated server with a process name, log folder, or backup folder

The [production template](config/servers.production.template.json) ships with all six game types pre-configured but disabled — just pick your server, replace paths, and enable.

---

## Quick Start

### 1. Windows GUI Setup Wizard (Best for most users)

The easiest way to get started. Just run the GUI, fill in your server details, and click "Install Task".

```powershell
powershell -File scripts\setup_client_gui.ps1
```

### 2. Interactive CLI Wizard

For those who prefer a terminal-based guided setup.

```powershell
powershell -File scripts\setup_client.ps1
```

See the [Client Setup Wizard Guide](docs/client-setup-wizard.md) for details.

### 2. Manual Setup

```powershell
# 1. Extract the release ZIP to a permanent folder (e.g. C:\QuestOpsWatchdog)
# 2. Set your Discord webhook URL (one time)
$env:QUESTOPS_DISCORD_WEBHOOK="https://discord.com/api/webhooks/your-id/your-token"

# 3. Validate the test config
powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.local.test.json

# 4. Run the watchdog once
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.test.json

# 5. Install automated scheduled task (every 5 minutes)
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.local.test.json -IntervalMinutes 5 -ValidateConfig
```

See the [Installation Guide](docs/install.md) for full step-by-step setup: Discord webhook creation, environment variables, config editing for production servers, scheduled task management, and troubleshooting.

---

## Safety

QuestOps Watchdog is designed for production use by operators who care about safety:

- **No secrets in JSON** — Discord webhook URLs go in environment variables only. The config validator rejects JSON files that contain URLs.
- **Validation before execution** — Run with `-ValidateConfig` to catch config issues before any check runs. The scheduled task installer can enforce this.
- **Maintenance mode** — Create a flag file to suppress Discord alerts during planned maintenance (game updates, server restarts). Checks and logging continue.
- **Local-only architecture** — No cloud API calls (except Discord webhook), no telemetry, no external dependencies. The tool never modifies files or restarts services.
- **Disabled by default** — Every server in the production template is `"enabled": false`. Turn on one at a time.

---

## How It Works

### Checks

All checks are read-only — they inspect state and return results:

| Function | What It Checks | Returns |
|----------|---------------|---------|
| `Test-QOProcessRunning` | Is the server process running? | Running, Message |
| `Test-QOLogFreshness` | Is the log file updating recently? | Fresh, AgeMinutes, Message |
| `Test-QOBackupFreshness` | Is the backup directory up to date? | Fresh, AgeHours, Message |
| `Test-QODiskSpace` | Is free disk space above the threshold? | Healthy, FreeGB, Message |

### Alerting

- Per-check cooldown prevents alert spam (configured per server or globally)
- Each check type has its own timer — disk alerts don't reset process alert timers
- Recovery alerts send one green embed when a failure clears
- Optional summary embed groups all results at end of run

### State and Logging

- Per-server state files track cooldowns and active failures under `state/`
- Daily log files written to `logs/questops-watchdog-YYYY-MM-DD.log`
- Webhook URLs are never logged

---

## Configuration

| File | Purpose |
|------|---------|
| `servers.example.json` | Reference example (disabled, Valheim + Project Zomboid) |
| `servers.local.test.json` | Safe test config (enabled, repo paths, 1-min cooldown) |
| `servers.production.template.json` | Production template (disabled, 6 game types, placeholder paths, 30-min cooldown) |

Each server includes name, checks to run, threshold values, optional category/tags for display, and optional per-server Discord webhook override.

The [config validator](scripts/validate_config.ps1) checks for:

| Category | Checks |
|----------|--------|
| File/JSON | File exists, valid JSON |
| Required fields | productName, configVersion, global, discord, servers (non-empty) |
| Discord safety | webhookUrlEnvVar is an env var name (not a URL), warns if enabled but env var not set |
| Process | Fails if enabled but process.name is missing |
| Log file | Warns if enabled but path missing, fails if maxAgeMinutes is not positive |
| Disk | Warns if enabled but path missing, fails if minFreeGB is not positive |
| Backup | Warns if enabled but path missing, fails if maxAgeHours is not positive |
| Placeholder paths | Warns if enabled server still uses REPLACE_ME in logFile, backup, or disk paths |

---

## Screenshots and Demo Assets

Screenshot placeholders and annotated demo files for common workflows. These live in `docs/assets/` and can be replaced with actual screenshots when captured.

### Demo Files

| File | Content |
|------|---------|
| [demo-summary.md](docs/assets/demo/demo-summary.md) | Grouped summary embed with healthy, maintenance, failing, and recovery servers |
| [demo-validation.md](docs/assets/demo/demo-validation.md) | Config validator output: pass, pass with warnings, and failure scenarios |
| [demo-maintenance.md](docs/assets/demo/demo-maintenance.md) | Maintenance mode suppression with flag-file activation and console output |
| [demo-recovery.md](docs/assets/demo/demo-recovery.md) | Recovery alert flow from failure to recovery with state file transitions |
| [demo-package.md](docs/assets/demo/demo-package.md) | Release packaging: ZIP generation, folder structure, included/excluded items |

### Architecture

- [architecture.md](docs/assets/architecture.md) — Text-based system diagram showing config, validator, runner, library, state, logs, Discord alerts, scheduled task, and release packaging flow.

### Screenshot Placeholders

The `docs/assets/screenshots/` directory is reserved for actual screenshots:

- `validation-pass.png` — console showing validation passing
- `validation-fail.png` — console showing validation failure with errors
- `summary-alert.png` — Discord embed showing grouped summary
- `maintenance-active.png` — console showing maintenance suppression
- `recovery-alert.png` — Discord embed showing recovery notification
- `architecture.png` — architecture diagram

---

## Release Packaging

Generate a portable release ZIP for deployment:

```powershell
# Reads version from VERSION file
powershell -File scripts\package_release.ps1

# Or specify a version explicitly
powershell -File scripts\package_release.ps1 -Version "v0.1.22"
```

Output: `dist\questops-watchdog-v0.1.22\` (folder) and `dist\questops-watchdog-v0.1.22.zip` (archive).

Includes: configs, scripts, libraries, docs, README, CHANGELOG, VERSION. Excludes: `.git`, `logs/`, `state/`, `dist/`, `*.log`, `__*.json`, `servers.local.*.json` (except `servers.local.test.json`).

---

## Roadmap

Realistic upcoming improvements:

- **Smarter summaries** — More compact alert grouping, per-server run history
- **Dashboard improvements** — Local HTML status page from state files
- **Release polish** — Signed releases, streamlined packaging
- **Additional validators** — Network port check, certificate expiry check
- **Multi-host organization** — Tag-based alert routing, host grouping

No AI diagnosis, no cloud sync, no auto-healing, no mobile apps — staying focused on what a local PowerShell agent does well.

---

## MVP Status

QuestOps Watchdog v0.1.22 has completed MVP QA with 40/40 tests passed. The tool is ready for production use on self-hosted game servers. See the [Final QA Report](docs/final-qa-report.md) and [Release Notes](docs/release-notes-v0.1.22.md) for full details.

## Project Resources

- [Installation Guide](docs/install.md) — step-by-step setup from scratch
- [Changelog](CHANGELOG.md) — release history
- [Release Notes](docs/release-notes-v0.1.22.md) — current release overview
- [Final QA Report](docs/final-qa-report.md) — MVP QA results
- [Project Map](PROJECTMAP.md) — architecture, phases, testing notes
- [Config Templates](config/) — example, test, and production configs
- [QA Checklist](docs/qa-checklist.md) — manual test procedure for releases
- [Release Checklist](docs/release-checklist.md) — step-by-step release process
