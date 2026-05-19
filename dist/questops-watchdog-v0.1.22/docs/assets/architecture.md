# QuestOps Watchdog — Architecture

## Overview

QuestOps Watchdog is a modular PowerShell 5.1 application with four functional layers: configuration, validation, execution, and output.

```
                          ┌─────────────────────┐
                          │   config/*.json      │
                          │  (server definitions)│
                          └──────────┬──────────┘
                                     │
                          ┌──────────▼──────────┐
                          │  validate_config.ps1 │
                          │  (config validator)  │
                          └──────────┬──────────┘
                                     │ pass/fail
                                     │
                          ┌──────────▼──────────┐
                          │ questops_watchdog.ps1│
                          │   (main runner)      │
                          │                      │
              ┌───────────┤  ┌───────────────┐   ├───────────┐
              │           │  │  lib/checks    │   │           │
              │           │  │  .ps1          │   │           │
              │           │  └───────┬───────┘   │           │
              │           │          │           │           │
              ▼           │  ┌───────▼───────┐   │           ▼
        ┌─────────┐       │  │  lib/discord   │   │     ┌─────────┐
        │ state/  │       │  │  .ps1          │   │     │  logs/  │
        │ (JSON)  │       │  └───────┬───────┘   │     │ (daily) │
        └─────────┘       │          │           │     └─────────┘
                          │          ▼           │
                          │   Discord Webhook    │
                          │   (alert embeds)     │
                          └─────────────────────┘
```

## Execution Flow

### 1. Configuration

```
config/servers.json
 ├── productName          Identification label
 ├── configVersion        Schema version for future migration
 ├── global               Default thresholds and paths
 │   ├── logDir           Log file directory
 │   ├── defaultCooldown  Global cooldown fallback
 │   └── ...
 ├── discord              Webhook configuration
 │   └── webhookUrlEnvVar Name of env var containing the webhook URL
 ├── summary              (optional) Grouped summary embed settings
 └── servers[]            Array of server definitions
      ├── name            Display name
      ├── enabled         true/false
      ├── process         Process check config
      ├── logFile         (optional) Log freshness check config
      ├── backup          (optional) Backup freshness check config
      ├── disk            (optional) Disk space check config
      ├── discord         (optional) Per-server webhook override
      ├── maintenance     (optional) Maintenance mode config
      ├── category        (optional) Classification label
      └── tags            (optional) Free-form string array
```

### 2. Validation

`validate_config.ps1` runs before any checks when invoked with `-ValidateConfig`:

1. Read and parse JSON
2. Verify required root fields
3. Check Discord webhook safety (env var only, no URLs in JSON)
4. Validate each server entry in the `servers` array
5. Verify numeric thresholds are positive
6. Check for placeholder paths on enabled servers
7. Validate category/tags metadata types
8. Check summary section consistency
9. Exit 0 on pass, 1 on fail

### 3. Main Runner

`questops_watchdog.ps1` orchestrates the full monitoring cycle:

```
for each enabled server in config:
    for each configured check (process, log, backup, disk):
        1. Run the check function from lib/checks.ps1
        2. If check fails:
           a. Test cooldown (skip if within window)
           b. Test maintenance mode (skip if flag file exists)
           c. Add to active_failures
           d. Send Discord failure embed
           e. Record last-sent timestamp
        3. If check passes:
           a. If in active_failures: send recovery embed, clear
           b. Otherwise: no action
    accumulate per-server results

if summary embed enabled:
    send grouped summary embed with cooldown

write daily log file
```

### 4. Library Components

```
lib/
 ├── checks.ps1     Four independent, read-only check functions
 │                   ├── Test-QOProcessRunning
 │                   ├── Test-QOLogFreshness
 │                   ├── Test-QOBackupFreshness
 │                   └── Test-QODiskSpace
 │
 ├── discord.ps1    Discord webhook sender
 │                   └── Send-QODiscordWebhook
 │                       (supports severity: info/warning/critical/success)
 │
 └── state.ps1      State and cooldown management
                     ├── Get-QOStateFilePath
                     ├── Read-QOState
                     ├── Write-QOState
                     ├── Test-QOAlertCooldown
                     ├── Set-QOAlertSent
                     ├── Set-QOAlertActive
                     ├── Clear-QOAlertActive
                     └── Test-QOAlertActive
```

### 5. State Storage

```
state/
 ├── <server-key>/
 │   └── state.json
 │       ├── alerts {}            Per-check-type cooldown timestamps
 │       └── active_failures []   Currently failing alert IDs
 └── __summary__/
     └── state.json               Summary embed cooldown
```

### 6. Scheduled Task Integration

```
scripts/
 ├── install_task.ps1     Registers scheduled task
 │                          - Interval in minutes
 │                          - Config path
 │                          - Optional -ValidateConfig
 │                          - Interactive user only, no stored passwords
 │
 └── uninstall_task.ps1   Unregisters scheduled task
```

### 7. Release Packaging

```
scripts/package_release.ps1
  ├── Reads version (VERSION file or -Version param)
  ├── Copies product files to dist/<name>-<version>/
  ├── Excludes runtime data (.git, logs/, state/, dist/)
  └── Creates ZIP archive
      └── Output: dist/questops-watchdog-<version>.zip
```

## Runtime Characteristics

- **Read-only**: Never modifies game server files, processes, or services
- **Stateless across runs**: Each run is independent; state is loaded from disk
- **Cooldown-driven**: Alert frequency limited by per-check and per-server timers
- **Fault-tolerant**: Missing or corrupt state files don't crash the runner
- **Log-first**: All activity recorded to daily log files regardless of alert status
- **No external dependencies**: Requires only Windows PowerShell 5.1

## Data Flow

```
JSON Config ──► Validator ──► Runner ──► Checks ──► State
                                  │                    │
                                  │                    ▼
                                  ├──► Discord API (alerts)
                                  │
                                  └──► Daily Log File
```
