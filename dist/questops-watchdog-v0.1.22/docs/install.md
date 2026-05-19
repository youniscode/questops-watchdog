# QuestOps Watchdog — Installation Guide

This guide walks you through installing QuestOps Watchdog from scratch. No cloud, no accounts, no monthly fees — just a PowerShell script that watches your game servers.

---

## 1. Requirements

Before you start, make sure you have:

- **Windows 7 / Server 2012 or later** — any modern Windows machine
- **Windows PowerShell 5.1** — built into Windows, nothing to install
- **A Discord server** where you can create a webhook
- **Read access** to your game server's files (log folder, backup folder)
- **No admin rights needed** for basic operation (scheduled task may need admin)

No extra software, no npm, no Python, no databases.

---

## 2. Download and Extract

1. Get the latest release ZIP
2. Extract it to a permanent folder — this is where QuestOps Watchdog will live

Recommended location:

```
C:\QuestOpsWatchdog
```

After extracting, the folder should look like this:

```
C:\QuestOpsWatchdog\
├── config\          JSON configuration files
├── scripts\         PowerShell scripts
├── lib\             Library modules
├── docs\            Documentation
├── README.md
├── PROJECTMAP.md
└── AI_WORKSPACE_RULES.md
```

Open PowerShell and navigate to this folder for all the steps below:

```powershell
cd C:\QuestOpsWatchdog
```

---

## 3. Create a Discord Webhook

QuestOps Watchdog sends alerts to a Discord channel using a webhook URL.

1. Open Discord and go to your server
2. Click the gear icon next to a text channel → **Integrations** → **Webhooks**
3. Click **Create Webhook**, give it a name (e.g. "QuestOps Watchdog")
4. Copy the webhook URL — it looks like: `https://discord.com/api/webhooks/123456/abc...`
5. Click **Save**

**Never paste the webhook URL into any JSON config file.** If you do, the config validator will reject it. The URL must be stored in an environment variable instead.

---

## 4. Set the Environment Variable

The webhook URL is stored in a system environment variable so it never appears in config files or logs.

### Option A: Current session only (for testing)

Run this in PowerShell. It lasts until you close the window:

```powershell
$env:QUESTOPS_DISCORD_WEBHOOK="YOUR_WEBHOOK_URL"
```

### Option B: Permanent (survives reboots)

This stores the variable permanently for your user account:

```powershell
[Environment]::SetEnvironmentVariable("QUESTOPS_DISCORD_WEBHOOK", "YOUR_WEBHOOK_URL", "User")
```

Replace `YOUR_WEBHOOK_URL` with the URL you copied from Discord. Close and reopen PowerShell for the permanent variable to take effect.

### Test the webhook

```powershell
powershell -File scripts\test_discord.ps1
```

You should see a blue embed message appear in your Discord channel. If it fails, check the webhook URL and the environment variable name.

---

## 5. Choose a Config File

QuestOps Watchdog ships with three config files:

| File | Purpose |
|------|---------|
| `config\servers.local.test.json` | Safe test config — already enabled, uses repo paths |
| `config\servers.production.template.json` | Production template — 6 game types, all disabled |
| `config\servers.example.json` | Reference example — 2 games, all disabled |

**Start with the test config** to verify everything works before touching production paths.

---

## 6. Edit the Production Config

When you are ready to monitor your real game servers:

1. Copy the production template so you have your own editable file:

```powershell
Copy-Item config\servers.production.template.json config\servers.production.json
```

2. Open `config\servers.production.json` in Notepad or any text editor

3. For each server you want to monitor:

   a. Change `"enabled": false` to `"enabled": true` — but only **one at a time**
   b. Replace `C:\REPLACE_ME\...` paths with your real server paths
   c. Adjust the numeric thresholds if needed (e.g. `minFreeGB`, `maxAgeMinutes`)

4. Save the file

**Safe editing rules:**

- Only enable one server at a time during testing
- The process name should match your server's `.exe` file (e.g. `valheim_server.exe`)
- Log and backup paths must be folders, not individual files
- The `minFreeGB` is the minimum free space before an alert fires
- The `cooldownMinutes` prevents repeated alerts (default 30 minutes is good)

---

## 7. Validate the Config

Always validate your config before running the watchdog:

```powershell
powershell -File scripts\validate_config.ps1 -ConfigPath config\servers.production.json
```

If validation passes, you will see:

```
Results: N passed, 0 warnings, 0 failed.
Validation PASSED.
```

If validation fails, read the error messages, fix the issues, and validate again. Common failures:

- Missing required fields (productName, servers, etc.)
- Placeholder paths (`C:\REPLACE_ME\...`) still present on enabled servers
- Webhook URL pasted directly into JSON
- `maxAgeMinutes` is not a positive number
- Cooldown is negative
- Tags array contains non-string values

---

## 8. Run the Watchdog Manually

Run the watchdog once to verify it works:

```powershell
powershell -File scripts\questops_watchdog.ps1 -ConfigPath config\servers.production.json -ValidateConfig
```

The `-ValidateConfig` flag validates the config first, then runs checks. You will see:

```
QuestOps Watchdog v0.1
Run: 2026-05-19 12:00:00
Config: C:\QuestOpsWatchdog\config\servers.production.json
============================================================

[SERVER] Valheim
  PROCESS : Running
  LOG     : Fresh
  BACKUP  : Fresh
  DISK    : OK (120 GB free)

============================================================
Summary: 1 server(s), 4 check(s), 0 alert(s) sent, 0 suppressed, 0 recovery alert(s).
```

If a check fails, you will see it in red. A Discord alert is sent if the webhook is configured and the cooldown has expired.

---

## 9. Install the Scheduled Task

The scheduled task runs the watchdog automatically every few minutes so you don't have to run it manually.

```powershell
powershell -File scripts\install_task.ps1 -ConfigPath config\servers.production.json -IntervalMinutes 5 -ValidateConfig
```

This command:

1. Validates your config before installing
2. Creates a scheduled task that runs every 5 minutes
3. Includes `-ValidateConfig` in the task action so every run validates first
4. Shows a summary:

```
SUCCESS: Scheduled task 'QuestOps Watchdog' created.
  Task name:   QuestOps Watchdog
  Interval:    Every 5 minute(s)
  Config path: C:\QuestOpsWatchdog\config\servers.production.json
  Validation:  Yes
  Runner:      C:\QuestOpsWatchdog\scripts\questops_watchdog.ps1
  User:        YourUsername (interactive only)

The task is registered but NOT started automatically.
```

Start the task manually from Task Scheduler or run:

```powershell
Start-ScheduledTask -TaskName "QuestOps Watchdog"
```

**Note:** Some systems require running PowerShell as Administrator to create scheduled tasks. If you get an "Access Denied" error, try running PowerShell as Administrator.

---

## 10. Uninstall the Scheduled Task

To stop automated monitoring:

```powershell
powershell -File scripts\uninstall_task.ps1
```

If you used a custom task name:

```powershell
powershell -File scripts\uninstall_task.ps1 -TaskName "My Custom Name"
```

---

## 11. Maintenance Mode

During planned maintenance (game updates, server restarts), you can suppress Discord alerts without disabling the server in config.

1. Enable maintenance mode in the server's config:

```json
"maintenance": {
  "enabled": true,
  "flagPath": ".\\state\\maintenance\\valheim.flag",
  "suppressAlerts": true
}
```

2. Create the flag file to activate maintenance:

```powershell
New-Item -ItemType File -Path ".\\state\\maintenance\\valheim.flag" -Force
```

3. When maintenance is done, remove the flag file:

```powershell
Remove-Item -LiteralPath ".\\state\\maintenance\\valheim.flag"
```

While the flag file exists, checks still run and logs are written, but no Discord alerts are sent. You will see `MAINTENANCE : active (alerts suppressed)` in the console output.

---

## 12. Logs and State Files

QuestOps Watchdog creates two types of runtime data:

### Logs (`logs\`)

Daily log files are written to `logs\questops-watchdog-YYYY-MM-DD.log`. Each run appends timestamps, server names, check results, and alert activity. Webhook URLs are never written to logs.

Use logs to review what happened on a specific day.

### State (`state\`)

Per-server state files track:
- When each alert was last sent (cooldown tracking)
- Which checks are currently failing (for recovery alerts)
- Summary embed cooldown

State files are JSON. You can read them to see current status, but do not edit them manually.

### Do not share or commit these

- `logs\` contains timestamps and server information — do not share publicly
- `state\` contains runtime data specific to your machine — not useful for others
- Both are excluded from the release ZIP

---

## 13. Troubleshooting

### Script blocked by execution policy

PowerShell may show "running scripts is disabled on this system". Fix:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

This allows locally created scripts and downloaded signed scripts to run. You only need to do this once.

### No Discord alert received

1. Run the webhook test: `powershell -File scripts\test_discord.ps1`
2. If no test message appears, check the environment variable:
   ```powershell
   $env:QUESTOPS_DISCORD_WEBHOOK
   ```
   If empty, the variable is not set. Re-read section 4.
3. Check if alerts are being suppressed by cooldown (state files track cooldowns)
4. Check if the server is in maintenance mode (flag file exists)
5. Check if `discord.enabled` is set to `true` in config

### Config validation failed

- Read the specific FAIL or WARN message — it tells you exactly what is wrong
- Common issues:
  - Webhook URL pasted into JSON instead of env var name
  - Placeholder `C:\REPLACE_ME\...` paths still present on enabled server
  - `maxAgeMinutes` or `minFreeGB` is missing, zero, or negative
  - Tags array has a number instead of a string
- Fix the issue and re-run validation

### Scheduled task not running

1. The task is created stopped by default. Start it manually:
   ```powershell
   Start-ScheduledTask -TaskName "QuestOps Watchdog"
   ```
2. Check Task Scheduler to verify the task exists and is configured correctly
3. The task runs only when you are logged on (interactive mode, no passwords)
4. If you see "Access Denied", run PowerShell as Administrator and re-run the installer
5. Check that the user account exists and can run PowerShell scripts

### Webhook URL accidentally committed or leaked

1. Regenerate the webhook URL in Discord (Discord → Server Settings → Integrations → Webhooks → Regenerate)
2. Update the environment variable with the new URL
3. If you accidentally pasted the URL into a JSON config file, remove it immediately and replace with the env var name
4. The config validator will reject configs containing `http://` or `https://` in webhook fields

### Process name wrong

- Open Task Manager, find your game server process in the Details tab
- Note the exact executable name (e.g. `valheim_server.exe`, `ProjectZomboid64.exe`)
- Update `process.name` in the config
- Run validation again

### Log path wrong

- Verify the log folder exists and contains log files
- Check that the path points to a folder, not a file
- The `maxAgeMinutes` should match how often your game writes to the log (check the newest log file timestamp)
- If your game writes logs rarely, increase `maxAgeMinutes` to avoid false alerts
