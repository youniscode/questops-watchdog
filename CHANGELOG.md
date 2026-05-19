# Changelog

## v0.1.22 — Final MVP release (2026-05-19)

- CHANGELOG and version tracking: VERSION file, CHANGELOG.md, version-aware packaging.
- Install guide rewrite: 13-section beginner-friendly guide with troubleshooting.
- Release packaging: idempotent ZIP generation, exclusion rules, temp config filtering.
- Task installer hardening: pre-install config validation, clear install summary.
- Config validation hardening: numeric type checking, webhook URL detection, summary consistency.
- Per-server category/tags metadata for identification and summary display.
- Optional summary embed: grouped per-server results sent as one Discord embed.
- Recovery alerts: one-time notification on failure-to-healthy transition.
- Maintenance mode: flag-file-based alert suppression during planned downtime.
- Config validation switch: -ValidateConfig on runner and scheduled task.
- README polish: professional GitHub/Fiverr-ready presentation.
- Demo and screenshot assets: workflow demos, architecture document.
- Fiverr service assets: gig description, packages, FAQ, titles, tags, portfolio, delivery checklist.
- MVP QA and release checklists: manual test procedure and release process.
- Final MVP QA execution: 40/40 tests passed across all 7 checklist sections.
- Packaging exclusions fix: temp test configs excluded from release ZIP.
- Release ZIP verification: confirmed correct inclusion and exclusion of all files.

## v0.1.21 — Install guide rewrite (2026-05-19)

- Rewrote `docs/install.md` from 49 to ~330 lines with 13 beginner-friendly sections.
- Added requirements, extract ZIP step, Discord webhook creation guide, environment variable setup (session + permanent), config selection, safe editing rules, validation, manual run, scheduled task install/uninstall, maintenance mode, logs/state explanation, troubleshooting (9 scenarios).
- Added Quick Start section to README.md with link to full install guide.
- Removed old inline install documentation from README.md to avoid duplication.

## v0.1.20 — Release packaging (2026-05-19)

- Created `scripts/package_release.ps1` with `-Version` (default "dev") and `-OutputDir` (default `.\dist`) parameters.
- Copies config/, scripts/, lib/, docs/ directories and root-level files README.md, PROJECTMAP.md, AI_WORKSPACE_RULES.md.
- Excludes .git, logs/, state/, dist/, *.log, `__*.json`.
- Idempotent: removes previous release folder and ZIP before rebuilding.
- Prints release summary (version, release dir, ZIP path, file count).

## v0.1.19 — Task installer hardening (2026-05-19)

- Added `-ValidateConfig` switch to `scripts/install_task.ps1`.
- Calls `validate_config.ps1` pre-install; aborts with clear message on validation failure.
- Persists `-ValidateConfig` in the scheduled task action XML for every run.
- Prints install summary: task name, interval minutes, config path, validation status, runner path.
- No secrets (Discord webhook URLs) printed in install summary.

## v0.1.18 — Config validation hardening (2026-05-19)

- Numeric type checking via `Test-IsNumeric` helper.
- Non-positive number detection for maxAgeMinutes, minFreeGB, maxAgeHours.
- Zero-or-greater check for cooldownMinutes.
- Empty category/tags warnings for enabled servers.
- Per-element tag string validation.
- Webhook URL detection finds URLs anywhere in string value, not just anchored match.
- Summary embed config consistency: enabled-without-Discord detection, missing fields check.
- README.md updated with validation rules reference table.

## v0.1.17 — Per-server category and tags metadata (2026-05-19)

- Added `category` (string) and `tags` (string array) fields to server configs.
- Applied to test config (category "test", tags ["local","test","windows"]).
- Applied to production template (6 servers with unique per-game tags).
- Validator warns on missing category/tags for enabled servers; fails on type mismatch.
- Runner stores category/tags in results; includes in summary embed field values when present.

## v0.1.16 — Optional summary embed (2026-05-19)

- Added `summary` config section with `enabled`, `title`, `color` fields.
- On enabled, sends a single summary embed grouping all server results after per-server alerts.
- Summary fields: server name, all check results (pass/fail/cooldown/unknown), category/tags when present.
- Uses its own cooldown state file (`__summary__/state.json`) separate from per-server cooldown.
- Aligns with recovery alert flow — both send alongside summary when summary is enabled.

## v0.1.15 — Recovery alerts (2026-05-19)

- Added per-server active failure tracking in state files (`active_failures` array).
- On failing check, adds alert ID to active_failures and sends failure embed.
- On passing check, only sends success embed if active_failures was non-empty (recovery), then clears.
- `Clear-QOAlertActive` deletes active_failures key entirely when empty to avoid `{}` in state JSON.
- Recovery embeds use green color, same title/description format as failure embeds.
- Maintains cooldownMinutes for rate-limiting — applies to all alert types.

## v0.1.14 — Maintenance mode (2026-05-19)

- Added `maintenance` flag file system: per-server `<ServerKey>.maintenance` in project root.
- Runner checks for flag file before sending Discord alerts for a server.
- When flag file exists, checks still run and results are logged, but no Discord alert is sent.
- Logged with "[MAINTENANCE]" prefix for visibility.
- Cooldown timer still ticks during maintenance to avoid alert flood on exit.

## v0.1.13 — Config validation switch (2026-05-19)

- Added `-ValidateConfig` parameter to `scripts/questops_watchdog.ps1`.
- When set, runs `validate_config.ps1` before starting checks.
- Stops execution with clear "Validation failed" message if config is invalid.
- Integrated into scheduled task installer for one-step validation.

## v0.1.12 — Config validator (2026-05-19)

- Created `scripts/validate_config.ps1`.
- Validates JSON structure: root object, discord section, global defaults, servers array.
- Validates required server fields (name, processName, check, enabled).
- Detects placeholder paths (C:\REPLACE_ME\) on enabled servers.
- Detects Discord webhook URLs set directly in config instead of environment variable.
- Returns exit code 0 (valid) or 1 (invalid) for scripting use.

## v0.1.11 — Production template (2026-05-19)

- Created `config/servers.production.template.json` with 6 game server entries.
- All servers set to `enabled: false` as safety default.
- REPLACE_ME placeholder paths used throughout.
- Supports: Palworld (process+disk), Minecraft (process+disk), 7 Days to Die (process+disk), Valheim (process+disk+log), Enshrouded (process+disk), Conan Exiles (process+disk+backup).

## v0.1.10 — Scheduled task installer and daily logging (2026-05-19)

- Created `scripts/install_task.ps1`: registers scheduled task running every N minutes with configurable `-IntervalMinutes` and `-ConfigPath`.
- Created `scripts/uninstall_task.ps1`: unregisters the scheduled task.
- Added daily log file: logs/questops-watchdog-YYYY-MM-DD.log with timestamped entries, automatic directory creation.
- Added log freshness check (`Test-QOLogFreshness` in checks.ps1) — verifies newest log file is recent.

## v0.1.9 — Basic monitoring runner (previous phase)

- Created `scripts/questops_watchdog.ps1` main runner.
- Created `lib/checks.ps1` with 4 check functions (process, disk, log freshness, backup freshness).
- Created `lib/discord.ps1` with Discord webhook sender supporting info/error/success and named fields.
- Created `lib/state.ps1` with cooldown/state management.
- Created `config/servers.example.json` reference config.
- Created `config/servers.local.test.json` test config with one enabled server.
- Added AI_WORKSPACE_RULES.md with project reference.
