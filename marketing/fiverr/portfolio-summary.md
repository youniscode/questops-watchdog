# Portfolio Summary -- QuestOps Watchdog

## One-liner

Portable PowerShell monitoring and alerting toolkit for self-hosted game servers.

## Project type

Open-source monitoring agent for Windows game server operators.

## Stack

Windows PowerShell 5.1, JSON configuration, Discord webhook API, Windows Task Scheduler.

## What it does

QuestOps Watchdog monitors self-hosted game servers by checking process health, disk space, log freshness, and backup freshness. When something fails, it sends a formatted Discord embed alert with severity colors. When a problem resolves, it sends one recovery notification and then stays quiet.

Everything runs locally on the server machine with no cloud dependencies, no databases, and no external software.

## Key features

- Process, disk, log, and backup health checks -- all read-only
- Config validator catches JSON errors, placeholder paths, and webhook URL leaks before any check runs
- Discord embed alerts with per-check cooldowns to prevent spam
- Per-server recovery alerts (one notification per failure-to-healthy transition)
- Flag-file maintenance mode: suppress alerts during updates without config changes
- Optional grouped summary embed at end of each run
- Windows scheduled task integration for automated monitoring
- Idempotent release packaging for portable deployment

## Supported game types

Project Zomboid, Valheim, Minecraft, ICARUS, 7 Days to Die, Enshrouded, Conan Exiles, Palworld, and any Windows dedicated server.

## Safety design

- Webhook URLs stored in environment variables only, never in config files
- Validation runs before execution, catches mistakes early
- All checks are read-only -- never modifies files or services
- All servers disabled by default in production templates
- No cloud, no telemetry, no external API calls (except Discord)

## Target users

Self-hosted game server operators, small community server owners, dedicated machine admins who want production visibility without production complexity.

## Availability

Source code and documentation on GitHub. Available as a configured service through Fiverr.
