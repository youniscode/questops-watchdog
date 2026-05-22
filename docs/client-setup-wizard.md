# Client Setup Wizard

The Client Setup Wizard is an interactive PowerShell script designed to help non-technical users configure QuestOps Watchdog for their game servers without manually editing JSON files.

---

## What the Wizard Does

- **Interactive Prompts**: Asks simple questions about your server.
- **Auto-Discovery**: Suggests default process names based on the game type you select.
- **Secure Webhook Storage**: Securely stores your Discord Webhook URL in your Windows User Environment Variables so it never touches a config file or log.
- **Config Generation**: Creates a production-ready `config/servers.client.generated.json` file.
- **Validation**: Automatically runs the config validator to ensure everything is correct.
- **One-Click Automation**: Optionally installs the Windows Scheduled Task to run the watchdog automatically.

---

## How to Run It

1. Open PowerShell.
2. Navigate to your QuestOps Watchdog folder.
3. Run the wizard:

```powershell
powershell -File scripts\setup_client.ps1
```

---

## What It Asks

The wizard will guide you through the following 14 steps:

1. **Server display name**: The name that appears in your Discord alerts.
2. **Game type**: Choose from Valheim, Project Zomboid, Minecraft, ICARUS, 7 Days to Die, or Other.
3. **Process name**: The executable name (e.g., `valheim_server.exe`). Defaults provided for known games.
4. **Log folder path**: Where your server's log files live.
5. **Backup folder path**: Where your server's backups are stored.
6. **Disk path**: The drive or folder to watch for free space (Default: `C:\`).
7. **Minimum free disk GB**: When to alert if disk space is low (Default: `20`).
8. **Log freshness max age minutes**: How long since the last log update before alerting (Default: `30`).
9. **Backup freshness max age hours**: How long since the last backup before alerting (Default: `48`).
10. **Discord webhook URL**: Your Discord channel's webhook URL (input is hidden).
11. **Enable summary reporting?**: Whether to send one grouped alert at the end of each run.
12. **Enable maintenance mode?**: Whether to enable the flag-file system for pausing alerts.
13. **Install scheduled task?**: Whether to set up the automated runner.
14. **Scheduled task interval**: How often the watchdog should run (Default: `5` minutes).

---

## Outputs

### 1. Generated Config
A new file is created at `config/servers.client.generated.json`. This file is fully enabled and ready for use. It uses the `production` category and tags based on your game type.

### 2. Environment Variable
The Discord Webhook URL is stored in a User Environment Variable named `QUESTOPS_DISCORD_WEBHOOK`. This survives reboots and keeps your secrets out of the codebase.

### 3. Scheduled Task
If you chose to install the task, a new Windows Scheduled Task named "QuestOps Watchdog" is created. It is registered to run under your user account and only when you are logged on.

---

## How to Uninstall

If you installed the scheduled task and want to remove it:

1. Open PowerShell.
2. Run the uninstaller:

```powershell
powershell -File scripts\uninstall_task.ps1
```
