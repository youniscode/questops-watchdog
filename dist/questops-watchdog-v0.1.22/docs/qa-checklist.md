# QuestOps Watchdog — QA Checklist

Manual QA process before calling a release complete. Run these tests on a clean checkout.

---

## 1. Repository Hygiene

- [ ] `git status` shows clean working tree (no uncommitted changes)
- [ ] `.gitignore` covers `logs/`, `state/`, `dist/`
- [ ] No stale state files in `state/` directory
- [ ] No stale log files committed to repo
- [ ] `dist/` directory is gitignored
- [ ] No `__*.json` test configs in `config/`

## 2. Config Validation

- [ ] `powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.local.test.json` passes with 0 failures
- [ ] `powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.production.template.json` passes (may show warnings for placeholder paths — acceptable)
- [ ] `powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.example.json` passes
- [ ] Config with webhook URL in JSON (instead of env var name) fails
- [ ] Config with negative `maxAgeMinutes` fails
- [ ] Config with negative `minFreeGB` fails
- [ ] Config with negative `cooldownMinutes` fails
- [ ] Config with missing `process.name` on enabled server fails
- [ ] Config with empty `servers` array fails
- [ ] Config validator exits 0 on pass, 1 on failure

## 3. Manual Watchdog Run

### 3a. Healthy local test

- [ ] `powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.test.json -ValidateConfig` completes with exit 0
- [ ] Console shows all processes Running, Logs Fresh, Backup Fresh, Disk OK
- [ ] Daily log file created in `logs/` with timestamped entries

### 3b. Failure config triggers alert

- [ ] `powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.failtest.json` shows PROCESS: STOPPED
- [ ] Alert suppression logged correctly (no webhook URL configured) when `$env:QUESTOPS_DISCORD_WEBHOOK` is not set
- [ ] When `$env:QUESTOPS_DISCORD_WEBHOOK` is set, a Discord embed is sent
- [ ] Cooldown suppression shows "cooldown active" message on repeated runs

### 3c. Recovery config triggers recovery alert

- [ ] First run with fake process name triggers failure and saves active_failures in state
- [ ] Second run with real process name triggers recovery embed (when webhook is set) or logs "recovery suppressed"
- [ ] State file active_failures cleared after recovery
- [ ] Recovery alert is not repeated on subsequent runs

### 3d. Maintenance flag suppresses alert

- [ ] Create flag file: `New-Item -ItemType File -Path ".\\state\\maintenance\\local-test.flag" -Force`
- [ ] Run failtest config: console shows `[MAINTENANCE] : active (alerts suppressed)`
- [ ] No Discord alert sent despite failing checks
- [ ] Suppression count appears in summary
- [ ] Delete flag file: `Remove-Item -LiteralPath ".\\state\\maintenance\\local-test.flag"`
- [ ] Next run sends alerts normally

### 3e. Summary embed reporting

- [ ] `powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.local.summary-test.json` runs without error
- [ ] Summary embed cooldown state created in `state/__summary__/state.json`

## 4. Scheduled Task

- [ ] `powershell -File scripts\install_task.ps1 -ConfigPath config\servers.local.test.json -ValidateConfig` completes with exit 0
- [ ] Install summary shows task name, interval, config path, validation status, runner path
- [ ] No secrets (webhook URLs) printed in install summary
- [ ] Task appears in Windows Task Scheduler as "QuestOps Watchdog"
- [ ] Task is created stopped (not running automatically)
- [ ] `Start-ScheduledTask -TaskName "QuestOps Watchdog"` starts the task without error
- [ ] `powershell -File scripts\uninstall_task.ps1` removes the task
- [ ] Uninstall warns gracefully if task does not exist

## 5. Release Packaging

- [ ] `powershell -File scripts\package_release.ps1` completes with exit 0
- [ ] Output shows correct version (from VERSION file)
- [ ] No double "v" in release folder name (`questops-watchdog-v0.1.22`, not `questops-watchdog-vv0.1.22`)
- [ ] Release folder created under `dist/`
- [ ] ZIP archive created under `dist/`
- [ ] Release folder contains: config/, scripts/, lib/, docs/, README.md, CHANGELOG.md, VERSION, PROJECTMAP.md, AI_WORKSPACE_RULES.md
- [ ] Release folder does NOT contain: logs/, state/, dist/, .git/, *.log, __*.json
- [ ] ZIP file is valid (opens without error)

## 6. Security and Safety

- [ ] No Discord webhook URLs exist in any JSON config file
- [ ] No production game server paths exist in config templates (only `C:\REPLACE_ME\...`)
- [ ] No scripts reference `C:\QuestPauseOps` or `C:\WindowsGSM`
- [ ] No scripts call Stop-Process, Restart-Service, or any file modification
- [ ] Environment variable names in config match documented names
- [ ] Release ZIP contains no secrets (no `.env`, no hardcoded tokens)
- [ ] Config validator catches webhook URLs in JSON

## 7. Documentation

- [ ] README.md renders correctly on GitHub (no broken markdown)
- [ ] All links in README.md resolve (install guide, changelog, project map, demo files, configs)
- [ ] docs/install.md has no broken sections or stale commands
- [ ] CHANGELOG.md is up to date with current VERSION
- [ ] VERSION file contains exactly the current version string
- [ ] PROJECTMAP.md current phase and version are accurate
- [ ] Fiverr assets exist in marketing/fiverr/
- [ ] Demo assets exist in docs/assets/demo/
- [ ] Architecture document exists in docs/assets/
