# Frequently Asked Questions

## What game servers do you support?

Project Zomboid, Valheim, Minecraft, ICARUS, 7 Days to Die, Enshrouded, Conan Exiles, Palworld, and any Windows game server with a process name, log folder, or backup folder. If it runs on Windows and produces logs or backups, it can be monitored.

## Does this work on Linux?

No. QuestOps Watchdog is built on Windows PowerShell 5.1 and uses Windows-specific features (process queries, scheduled tasks, drive space checks). It requires a Windows machine.

## Can this work without internet?

Monitoring checks run entirely on your local machine and do not require internet. Discord alerts need outbound HTTPS access (api.discord.com). If Discord is unreachable, the watchdog logs everything locally and you can review it later.

## Do I need a Discord server?

Yes. Alerts are sent to a Discord channel via webhook. You need a Discord server where you can create a webhook (free, takes 2 minutes). If you cannot use Discord, the watchdog still runs and logs everything -- you can review results manually from the console or log files.

## Can I edit the config myself after delivery?

Yes. Config files are plain JSON. You can add or remove servers, change thresholds, enable/disable checks, and adjust cooldown intervals. The config validator catches mistakes before they cause problems.

## Does this support modded game servers?

Yes. Modded servers still run a Windows process, write logs, and consume disk space. As long as the process name and paths are correct, all checks work regardless of mods.

## Do I need admin rights?

Basic operation (running the watchdog manually) does not require admin rights. Installing the automated scheduled task may need admin rights depending on your system configuration. I will work within your access level.

## What happens if the watchdog detects a problem?

A Discord embed is sent to your channel with the server name, check type, and details (e.g. "Valheim -- Process Stopped"). If the same problem persists, alerts are rate-limited by configurable cooldowns to avoid spam. When the problem resolves, one recovery alert is sent and then silence resumes.

## Will this restart my server or modify game files?

No. QuestOps Watchdog is read-only. It never starts, stops, or restarts processes. It never modifies game files, configs, or folders. It only checks state and sends alerts.

## Can I monitor multiple servers on the same machine?

Yes. The production template supports 6 game types out of the box. You can add any number of servers to a single config. Each server gets its own checks, thresholds, and cooldown timers.

## How do I pause alerts during maintenance?

Create a flag file. No config changes needed. While the flag file exists, checks still run and logs still write, but Discord alerts are suppressed. Delete the flag file to resume alerting.

## What happens if the watchdog itself stops running?

If the machine is on and the scheduled task is running, the watchdog restarts automatically on the next interval (default 5 minutes). If the machine is off, no checks run until it comes back. There is no watchdog for the watchdog in this version.

## Is my Discord webhook URL safe?

Yes. The webhook URL is stored in a Windows environment variable, never in a config file or log. The config validator rejects JSON files that contain URLs. If you ever need to rotate the webhook, regenerate it in Discord and update the environment variable.

## Do you provide 24/7 support?

No. This is a setup and configuration service. The watchdog runs independently on your machine once configured. I provide documentation and will walk you through your setup, but ongoing monitoring is handled by the tool itself.

## What if I have a game server not on your list?

Message me. If it runs on Windows and has a process name, I can almost certainly configure monitoring for it. Custom server types may need additional check configuration.
